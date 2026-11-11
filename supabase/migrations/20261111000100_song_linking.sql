-- ==============================================================================
-- Song linking: every version belongs to one song, matched at creation
-- ==============================================================================
-- A song is the work (title + artist). Each person's version is its own sheet and
-- is always linked to a song. Songs are matched by a normalized key (lower case,
-- no accents, no punctuation, collapsed spaces) when a version is created, so
-- duplicates are rare. A version's owner can move it to another song when it was
-- attached wrongly. Songs without versions are removed.
--
-- This replaces song merge requests (removed here): song_merge_requests,
-- request_song_merge, respond_to_song_merge, songs.merged_into_id, resolve_song.
-- ==============================================================================

create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- ------------------------------------------------------------------------------
-- 1. Remove merge
-- ------------------------------------------------------------------------------

drop trigger trg_song_versions_resolve_song on public.song_versions;
drop function public.song_versions_resolve_song();

-- Functions that followed merged_into_id are redefined without it.
create or replace function public.can_see_song(p_song uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.songs s
        where s.id = p_song
          and (s.created_by = auth.uid()
               or exists (
                    select 1 from public.song_versions v
                    where v.song_id = s.id
                      and public.can_see_version(v.id)))
    );
$$;

create or replace function public.can_view_profile(p_profile uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select p_profile = auth.uid()
        or exists (
            select 1
            from public.organization_members mine
            join public.organization_members theirs
              on theirs.organization_id = mine.organization_id
            where mine.user_id = auth.uid() and mine.deactivated_at is null
              and theirs.user_id = p_profile
        )
        or exists (
            select 1 from public.invitations i
            where i.status = 'pending'
              and ((i.invited_user_id = auth.uid() and i.invited_by = p_profile)
                or (i.invited_user_id = p_profile and public.is_org_admin(i.organization_id)))
        )
        or exists (
            select 1 from public.song_versions v
            where v.owner_id = p_profile and public.can_see_version(v.id)
        );
$$;

create or replace function public.fork_song_version(p_version_id uuid, p_label text default null)
returns public.song_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_src public.song_versions;
    v_new public.song_versions;
    v_label text := nullif(btrim(coalesce(p_label, '')), '');
begin
    if not public.can_see_version(p_version_id) then
        raise exception 'version_not_found' using errcode = 'P0002';
    end if;
    select * into v_src from public.song_versions where id = p_version_id;
    insert into public.song_versions (
        song_id, owner_id, label, forked_from_version_id, visibility, key, tempo,
        time_signature_beats, time_signature_beat_value, sections_json, tags_json,
        cover_image_path, notes)
    values (
        v_src.song_id, v_uid,
        left(coalesce(v_label, v_src.label || ' (copy)'), 100),
        v_src.id, 'private', v_src.key, v_src.tempo,
        v_src.time_signature_beats, v_src.time_signature_beat_value, v_src.sections_json,
        v_src.tags_json, v_src.cover_image_path, v_src.notes)
    returning * into v_new;
    perform public._copy_scores(v_src.id, v_new.id);
    if v_src.owner_id <> v_uid then
        perform public._notify(v_src.owner_id, null, 'song_version_forked',
            jsonb_build_object('version_id', v_src.id, 'new_version_id', v_new.id,
                               'song_id', v_new.song_id, 'forked_by', v_uid));
    end if;
    return v_new;
end;
$$;

drop function public.respond_to_song_merge(uuid, boolean);
drop function public.request_song_merge(uuid, uuid);
drop function public._merge_songs(uuid, uuid);
drop table public.song_merge_requests;
delete from public.notifications
where type in ('song_merge_requested', 'song_merge_accepted', 'song_merge_declined');

-- The surviving song of an old merge already holds every version.
alter table public.songs drop constraint songs_not_merged_into_itself;
drop index public.songs_merged_into_idx;
alter table public.songs drop column merged_into_id;
drop function public.resolve_song(uuid);

-- ------------------------------------------------------------------------------
-- 2. Normalized identity
-- ------------------------------------------------------------------------------

-- Lower case, accent-free; apostrophes dropped, other punctuation is a space;
-- spaces collapsed. "Tú Fidelidad" and "Tu fidelidad" match; "Way Maker (Live)"
-- stays different from "Way Maker".
create function public.normalize_song_text(p_text text)
returns text
language sql
stable
set search_path = ''
as $$
    select btrim(regexp_replace(
        regexp_replace(lower(extensions.unaccent(coalesce(p_text, ''))), '[''’`]', '', 'g'),
        '[^[:alnum:]]+', ' ', 'g'));
$$;

alter table public.songs add column normalized_key text;
update public.songs
set normalized_key = public.normalize_song_text(title) || '|' || public.normalize_song_text(artist);

-- Join existing exact duplicates: versions move to the oldest song.
with ranked as (
    select id,
           first_value(id) over (partition by normalized_key order by created_at, id) as keeper
    from public.songs
)
update public.song_versions v set song_id = r.keeper
from ranked r
where v.song_id = r.id and r.id <> r.keeper;

-- Songs without versions disappear (duplicates just emptied, orphans, old merges).
delete from public.songs s
where not exists (select 1 from public.song_versions v where v.song_id = s.id);

alter table public.songs alter column normalized_key set not null;
create unique index songs_normalized_key_idx on public.songs (normalized_key);
create index songs_search_trgm_idx on public.songs
    using gin ((replace(normalized_key, '|', ' ')) extensions.gin_trgm_ops);

-- Keeps the key in step with title/artist; a collision is a clear error.
create function public.songs_set_key()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    new.normalized_key := public.normalize_song_text(new.title) || '|'
                          || public.normalize_song_text(new.artist);
    if exists (select 1 from public.songs s
               where s.normalized_key = new.normalized_key and s.id <> new.id) then
        raise exception 'song_exists' using errcode = 'P0001';
    end if;
    return new;
end;
$$;

create trigger trg_songs_set_key
    before insert or update of title, artist on public.songs
    for each row execute function public.songs_set_key();

-- ------------------------------------------------------------------------------
-- 3. Empty songs disappear
-- ------------------------------------------------------------------------------

create function public.songs_delete_empty()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    begin
        delete from public.songs s
        where s.id = old.song_id
          and not exists (select 1 from public.song_versions v where v.song_id = s.id);
    exception when foreign_key_violation then
        -- Another user attached a version at the same moment: the song is in
        -- use again, so keep it and let the original delete or move succeed.
        null;
    end;
    return null;
end;
$$;

create trigger trg_song_versions_delete_empty_song
    after delete on public.song_versions
    for each row execute function public.songs_delete_empty();
create trigger trg_song_versions_move_empty_song
    after update of song_id on public.song_versions
    for each row when (old.song_id is distinct from new.song_id)
    execute function public.songs_delete_empty();

-- ------------------------------------------------------------------------------
-- 4. RPCs
-- ------------------------------------------------------------------------------

-- The id of the song with exactly this title and artist (normalized), creating
-- it when missing. Works across every song, including ones whose versions are
-- private to someone else: it reveals only that the song the caller typed exists.
create function public.find_or_create_song(p_title text, p_artist text default '')
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_key text := public.normalize_song_text(p_title) || '|'
                  || public.normalize_song_text(p_artist);
    v_id uuid;
begin
    select id into v_id from public.songs where normalized_key = v_key;
    if found then
        return v_id;
    end if;
    begin
        insert into public.songs (title, artist, created_by)
        values (btrim(coalesce(p_title, '')), btrim(coalesce(p_artist, '')), v_uid)
        returning id into v_id;
        return v_id;
    exception when unique_violation or sqlstate 'P0001' then
        -- Someone created it at the same moment (song_exists / unique key).
        select id into v_id from public.songs where normalized_key = v_key;
        if found then
            return v_id;
        end if;
        raise;
    end;
end;
$$;

-- Owner only: attach my version to another existing song. Setlists and
-- repertoire reference the version, so they keep working.
create function public.move_version_to_song(p_version_id uuid, p_song_id uuid)
returns public.song_versions
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_row public.song_versions;
begin
    select * into v_row from public.song_versions where id = p_version_id;
    if not found or not public.can_see_version(p_version_id) then
        raise exception 'version_not_found' using errcode = 'P0002';
    end if;
    if v_row.owner_id <> v_uid then
        raise exception 'not_version_owner' using errcode = '42501';
    end if;
    if not exists (select 1 from public.songs where id = p_song_id) then
        raise exception 'song_not_found' using errcode = 'P0002';
    end if;
    if v_row.song_id <> p_song_id then
        update public.song_versions set song_id = p_song_id, updated_at = now()
        where id = p_version_id
        returning * into v_row;
    end if;
    return v_row;
end;
$$;

-- Visible songs matching what the user typed: contains the text, or close to
-- it (typos). Runs with the caller's rights, so only songs they can see appear
-- and the count only includes versions they can see.
create function public.search_songs(p_query text, p_limit integer default 8)
returns table (song_id uuid, title text, artist text, created_by uuid, version_count integer)
language sql
stable
security invoker
set search_path = ''
as $$
    with q as (select public.normalize_song_text(p_query) as n),
    hits as (
        select s.id, s.title, s.artist, s.created_by,
               replace(s.normalized_key, '|', ' ') as flat,
               greatest(extensions.similarity(replace(s.normalized_key, '|', ' '), q.n),
                        extensions.similarity(split_part(s.normalized_key, '|', 1), q.n)) as score,
               q.n
        from public.songs s, q
        where q.n <> ''
    )
    select h.id, h.title, h.artist, h.created_by,
           (select count(*)::integer from public.song_versions v where v.song_id = h.id)
    from hits h
    where h.flat like '%' || h.n || '%' or h.score > 0.3
    order by (h.flat like h.n || '%') desc, h.score desc, h.title
    limit greatest(1, least(coalesce(p_limit, 8), 25));
$$;

-- ------------------------------------------------------------------------------
-- 5. Policies and grants
-- ------------------------------------------------------------------------------

-- The id returned by find_or_create_song may be a song whose versions the caller
-- cannot see yet; attaching a version of their own to it is what makes it visible.
drop policy song_versions_insert on public.song_versions;
create policy song_versions_insert on public.song_versions for insert to authenticated
    with check (owner_id = auth.uid() and public.is_active_user()
                and (forked_from_version_id is null
                     or public.can_see_version(forked_from_version_id)));

revoke all on function
    public.normalize_song_text(text), public.songs_set_key(), public.songs_delete_empty(),
    public.find_or_create_song(text, text), public.move_version_to_song(uuid, uuid),
    public.search_songs(text, integer)
    from public, anon, authenticated;
grant execute on function
    public.normalize_song_text(text),
    public.find_or_create_song(text, text),
    public.move_version_to_song(uuid, uuid),
    public.search_songs(text, integer)
    to authenticated;
