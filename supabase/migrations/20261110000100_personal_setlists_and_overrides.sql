-- ==============================================================================
-- Personal setlists and per-item key/tempo overrides
-- ==============================================================================
-- Until now every setlist belonged to an organization. A musician can also keep
-- personal setlists: owned by one user, no organization, items may reference any
-- version the owner can see (their own, shared with their organizations, public).
-- Setlist items additionally carry the performance key and tempo overrides the
-- app already had locally.
--
-- Exactly one of setlists.organization_id / setlists.owner_id is set.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Columns and constraints
-- ------------------------------------------------------------------------------

alter table public.setlists
    add column owner_id uuid references public.profiles (id),
    alter column organization_id drop not null,
    add constraint setlists_exactly_one_owner
        check ((organization_id is null) <> (owner_id is null));
create index setlists_owner_idx on public.setlists (owner_id);

alter table public.setlist_items
    alter column organization_id drop not null,
    add column key_override text,
    add column tempo_override integer,
    add constraint setlist_items_tempo_override_range
        check (tempo_override is null or tempo_override between 20 and 400);

-- Items of any setlist belong to it (the composite foreign key of the baseline
-- only covers organization setlists, where organization_id is set).
alter table public.setlist_items
    add constraint setlist_items_setlist_fkey
        foreign key (setlist_id) references public.setlists (id) on delete cascade;

-- Items of personal setlists reference any version; losing it keeps the snapshot.
-- (Items of organization setlists still go through organization_repertoire.)
alter table public.setlist_items
    add constraint setlist_items_version_fkey
        foreign key (version_id) references public.song_versions (id)
        on delete set null (version_id);

-- ------------------------------------------------------------------------------
-- 2. Helper
-- ------------------------------------------------------------------------------

create function public.owns_personal_setlist(p_setlist text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.is_active_user() and exists (
        select 1 from public.setlists s
        where s.id = p_setlist and s.organization_id is null and s.owner_id = auth.uid()
    );
$$;

-- ------------------------------------------------------------------------------
-- 3. Row Level Security
-- ------------------------------------------------------------------------------

drop policy setlists_select on public.setlists;
drop policy setlists_write on public.setlists;
drop policy setlist_items_select on public.setlist_items;
drop policy setlist_items_write on public.setlist_items;

-- Organization setlists: members read, admins write (unchanged).
-- Personal setlists: only their owner, and only while the account is active.
create policy setlists_select on public.setlists for select to authenticated
    using ((organization_id is not null and public.is_org_member(organization_id))
           or (organization_id is null and owner_id = auth.uid()));
create policy setlists_write on public.setlists for all to authenticated
    using ((organization_id is not null and public.can_admin_org(organization_id))
           or (organization_id is null and owner_id = auth.uid() and public.is_active_user()))
    with check ((organization_id is not null and owner_id is null
                 and public.can_admin_org(organization_id))
                or (organization_id is null and owner_id = auth.uid()
                    and public.is_active_user()));

create policy setlist_items_select on public.setlist_items for select to authenticated
    using ((organization_id is not null and public.is_org_member(organization_id))
           or (organization_id is null and public.owns_personal_setlist(setlist_id)));
create policy setlist_items_write on public.setlist_items for all to authenticated
    using ((organization_id is not null and public.can_admin_org(organization_id))
           or (organization_id is null and public.owns_personal_setlist(setlist_id)))
    with check ((organization_id is not null and public.can_admin_org(organization_id))
                or (organization_id is null and public.owns_personal_setlist(setlist_id)
                    and (version_id is null or public.can_see_version(version_id))));

-- ------------------------------------------------------------------------------
-- 4. Grants
-- ------------------------------------------------------------------------------

-- A setlist can never change hands (organization_id / owner_id) after creation.
revoke update on public.setlists from authenticated;
grant update (title, description, event_date, tags_json, band_id)
    on public.setlists to authenticated;

grant execute on function public.owns_personal_setlist(text) to authenticated;

-- ------------------------------------------------------------------------------
-- 5. Edit time (conflict resolution between devices)
-- ------------------------------------------------------------------------------
-- `updated_at` is the time of the last write of any kind (a device pushing, a
-- song merge moving versions under another song, a share cleanup). It only says
-- "something changed". `edited_at` is when the user last edited the content,
-- as stamped by the editing device; only clients write it, never a trigger or
-- a server function, so server-side changes cannot make a stale copy look newer.
-- Devices compare their local edit time with `edited_at` to decide who wins.

alter table public.song_versions
    add column edited_at timestamptz not null default now();
alter table public.scores
    add column edited_at timestamptz not null default now();
alter table public.setlists
    add column edited_at timestamptz not null default now();

-- `scores` grants insert and update on every column and setlists inserts any
-- column; the column grants of setlists (update) and song_versions need it.
grant update (edited_at) on public.setlists to authenticated;
grant insert (edited_at, forked_from_version_id) on public.song_versions to authenticated;
grant update (edited_at) on public.song_versions to authenticated;

-- ------------------------------------------------------------------------------
-- 6. Fork lineage
-- ------------------------------------------------------------------------------
-- A client that creates a fork offline records where it came from. The parent
-- must be visible to the owner, so lineage cannot point at private versions of
-- other users.

drop policy song_versions_insert on public.song_versions;
create policy song_versions_insert on public.song_versions for insert to authenticated
    with check (owner_id = auth.uid() and public.is_active_user() and public.can_see_song(song_id)
                and (forked_from_version_id is null
                     or public.can_see_version(forked_from_version_id)));
