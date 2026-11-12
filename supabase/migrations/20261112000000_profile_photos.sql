-- ==============================================================================
-- Profile photos and organization logos
-- ==============================================================================
-- Two public-read Storage buckets (unguessable paths, jpeg/png/webp, 2 MB):
--   avatars/<user id>/<file>              written only by that active user
--   organization-logos/<org id>/<file>    written only by an admin of that
--                                         (non-archived) organization
-- The database stores the bucket-relative object path, never a URL, so the same
-- row works for any host serving the project. profiles.avatar_url is replaced by
-- profiles.avatar_path; organizations gain logo_path and description.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Columns
-- ------------------------------------------------------------------------------

alter table public.profiles drop column avatar_url;
alter table public.profiles add column avatar_path text;
alter table public.profiles add constraint profiles_avatar_path_own_folder
    check (avatar_path is null
           or (avatar_path like id::text || '/%' and char_length(avatar_path) <= 200));

alter table public.organizations add column logo_path text;
alter table public.organizations add column description text;
alter table public.organizations add constraint organizations_logo_path_own_folder
    check (logo_path is null
           or (logo_path like id::text || '/%' and char_length(logo_path) <= 200));
alter table public.organizations add constraint organizations_description_length
    check (description is null or char_length(description) <= 280);

grant update (username, display_name, avatar_path) on public.profiles to authenticated;
grant update (name, description, logo_path) on public.organizations to authenticated;

-- ------------------------------------------------------------------------------
-- 2. Functions that used avatar_url
-- ------------------------------------------------------------------------------

-- Deactivation also drops the photo reference.
create or replace function public._deactivate_user(p_uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    r record;
begin
    if not exists (
        select 1 from public.profiles p where p.id = p_uid and p.deactivated_at is null
    ) then
        return;
    end if;

    for r in
        select m.organization_id
        from public.organization_members m
        join public.organizations o on o.id = m.organization_id
        where m.user_id = p_uid and m.deactivated_at is null and o.archived_at is null
          and not exists (
              select 1 from public.organization_members x
              where x.organization_id = m.organization_id
                and x.user_id <> p_uid and x.deactivated_at is null)
    loop
        perform public._archive_org(r.organization_id);
    end loop;

    for r in select m.id from public.organization_members m where m.user_id = p_uid loop
        perform public._clear_member_schedule(r.id);
    end loop;

    update public.organization_members set deactivated_at = now()
    where user_id = p_uid and deactivated_at is null;
    update public.invitations set status = 'cancelled', responded_at = now()
    where invited_user_id = p_uid and status = 'pending';
    update public.profiles set deactivated_at = now(), avatar_path = null where id = p_uid;
end;
$$;

drop function public.search_profiles(text);
create function public.search_profiles(p_query text)
returns table (id uuid, username text, display_name text, avatar_path text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_q text := lower(btrim(coalesce(p_query, '')));
    v_like text;
begin
    if char_length(v_q) < 3 then
        return;
    end if;
    v_like := replace(replace(replace(v_q, '\', '\\'), '%', '\%'), '_', '\_');
    return query
        select p.id, p.username, p.display_name, p.avatar_path
        from public.profiles p
        where p.id <> v_uid
          and p.deactivated_at is null
          and (p.username like v_like || '%' or lower(p.display_name) like '%' || v_like || '%')
        order by p.username
        limit 20;
end;
$$;
revoke all on function public.search_profiles(text) from public, anon, authenticated;
grant execute on function public.search_profiles(text) to authenticated;

-- ------------------------------------------------------------------------------
-- 3. Buckets
-- ------------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
    ('organization-logos', 'organization-logos', true, 2097152,
     array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
    set public = excluded.public,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- ------------------------------------------------------------------------------
-- 4. Storage policies
-- ------------------------------------------------------------------------------

-- The first folder of an organization logo path is the organization id; any
-- other shape is simply not writable.
create function public.can_write_org_logo(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_org uuid;
begin
    begin
        v_org := (storage.foldername(p_name))[1]::uuid;
    exception when others then
        return false;
    end;
    return public.can_admin_org(v_org);
end;
$$;
revoke all on function public.can_write_org_logo(text) from public, anon, authenticated;
grant execute on function public.can_write_org_logo(text) to authenticated;

-- Reads of the public buckets go through the public URL (no policy needed). The
-- select policies only let a writer find the object they replace or delete.
create policy avatars_select_own on storage.objects for select to authenticated
    using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatars_insert_own on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and public.is_active_user()
                and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatars_update_own on storage.objects for update to authenticated
    using (bucket_id = 'avatars' and public.is_active_user()
           and (storage.foldername(name))[1] = auth.uid()::text)
    with check (bucket_id = 'avatars' and public.is_active_user()
                and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatars_delete_own on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and public.is_active_user()
           and (storage.foldername(name))[1] = auth.uid()::text);

create policy org_logos_select_admin on storage.objects for select to authenticated
    using (bucket_id = 'organization-logos' and public.can_write_org_logo(name));
create policy org_logos_insert_admin on storage.objects for insert to authenticated
    with check (bucket_id = 'organization-logos' and public.can_write_org_logo(name));
create policy org_logos_update_admin on storage.objects for update to authenticated
    using (bucket_id = 'organization-logos' and public.can_write_org_logo(name))
    with check (bucket_id = 'organization-logos' and public.can_write_org_logo(name));
create policy org_logos_delete_admin on storage.objects for delete to authenticated
    using (bucket_id = 'organization-logos' and public.can_write_org_logo(name));
