-- ==============================================================================
-- Battuta baseline schema: users, organizations, bands, invitations, songs,
-- availability, notifications and permissions
-- ==============================================================================
-- Model: user -> organization -> bands. Admins are per organization. Joining is
-- only by invitation (join link / QR token, or invite by username).
-- Songs are modelled like LaCuerda: one song (the work) has many versions by
-- different owners; visibility, forks and merges are per version.
--
-- Layout: tables, helper functions, triggers, RLS policies, RPCs, grants,
-- realtime. All client writes to membership/invitation/notification tables go
-- through RPCs or triggers.
--
-- Accounts are never hard-deleted: profiles are tombstones (deactivated_at) and
-- nothing cascades from auth.users into content.
--
-- Error contract (RPCs and triggers raise `message` = machine code):
--   28000 not_authenticated
--   42501 not_admin, not_member, not_assignee, not_song_creator
--   22023 invalid_name, invalid_username, invalid_role, invalid_expiry,
--         invalid_max_uses, invalid_amount, invalid_date_range
--   P0002 invite_not_found, user_not_found, invitation_not_found,
--         member_not_found, version_not_found, song_not_found,
--         merge_request_not_found
--   P0001 invite_revoked, invite_expired, invite_used_up, already_member,
--         already_invited, cannot_invite_self, invitation_not_pending,
--         last_admin, band_not_in_organization, organization_archived,
--         archive_already_requested, archive_not_requested,
--         account_deactivated, member_deactivated, merge_same_song,
--         merge_cycle, merge_already_requested, merge_not_pending
--   23505 username_taken
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Tables
-- ------------------------------------------------------------------------------

-- No foreign key to auth.users on purpose: a profile outlives its auth user.
create table public.profiles (
    id uuid primary key,
    username text not null,
    display_name text not null,
    avatar_url text,
    deactivated_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint profiles_username_format check (username ~ '^[a-z0-9_.]{3,30}$'),
    constraint profiles_display_name_length
        check (char_length(btrim(display_name)) between 1 and 80)
);
create unique index profiles_username_key on public.profiles (lower(username));

create table public.organizations (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    created_by uuid references public.profiles (id),
    archived_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint organizations_name_length check (char_length(btrim(name)) between 1 and 100)
);

create table public.organization_members (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null references public.organizations (id) on delete cascade,
    user_id uuid not null references public.profiles (id),
    role text not null default 'member' check (role in ('admin', 'member')),
    -- Musician profile, per organization. Availability lives in member_absences.
    instruments text[] not null default '{}',
    min_pitch text,
    max_pitch text,
    notes text,
    -- Set when the account is deactivated: the row stays as history.
    deactivated_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (organization_id, user_id),
    unique (id, organization_id)
);
create index organization_members_user_idx on public.organization_members (user_id);

-- Archiving needs every current admin to approve. Approvals are matched against
-- the admins at evaluation time, so admins added/removed mid-request are handled.
create table public.organization_archive_requests (
    organization_id uuid primary key references public.organizations (id) on delete cascade,
    requested_by uuid references public.profiles (id),
    requested_at timestamptz not null default now()
);
create table public.organization_archive_approvals (
    organization_id uuid not null
        references public.organization_archive_requests (organization_id) on delete cascade,
    user_id uuid not null references public.profiles (id),
    approved_at timestamptz not null default now(),
    primary key (organization_id, user_id)
);

create table public.bands (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null references public.organizations (id) on delete cascade,
    name text not null,
    description text,
    color_value bigint not null default 4293241148, -- 0xFFE5A93C (stage amber)
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, organization_id)
);
create index bands_organization_idx on public.bands (organization_id);

-- Composite foreign keys guarantee band and member belong to the same organization.
create table public.band_members (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null,
    band_id uuid not null,
    member_id uuid not null,
    created_at timestamptz not null default now(),
    unique (band_id, member_id),
    foreign key (band_id, organization_id)
        references public.bands (id, organization_id) on delete cascade,
    foreign key (member_id, organization_id)
        references public.organization_members (id, organization_id) on delete cascade
);
create index band_members_member_idx on public.band_members (member_id);

create table public.invite_links (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null references public.organizations (id) on delete cascade,
    band_id uuid,
    token text not null unique
        default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
    created_by uuid references public.profiles (id),
    created_at timestamptz not null default now(),
    expires_at timestamptz not null,
    max_uses integer check (max_uses is null or max_uses >= 1),
    use_count integer not null default 0 check (use_count >= 0),
    revoked_at timestamptz,
    foreign key (band_id, organization_id)
        references public.bands (id, organization_id) on delete set null (band_id)
);
create index invite_links_organization_idx on public.invite_links (organization_id);

create table public.invitations (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null references public.organizations (id) on delete cascade,
    band_id uuid,
    invited_user_id uuid not null references public.profiles (id),
    invited_by uuid references public.profiles (id),
    status text not null default 'pending'
        check (status in ('pending', 'accepted', 'declined', 'cancelled')),
    created_at timestamptz not null default now(),
    responded_at timestamptz,
    updated_at timestamptz not null default now(),
    foreign key (band_id, organization_id)
        references public.bands (id, organization_id) on delete set null (band_id)
);
create unique index invitations_one_pending_idx
    on public.invitations (organization_id, invited_user_id) where status = 'pending';
create index invitations_user_idx on public.invitations (invited_user_id);

-- Songs: the work. No chord content here, see song_versions.
create table public.songs (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    artist text not null default '',
    created_by uuid not null references public.profiles (id),
    -- Set when merged away: acts as a redirect to the surviving song.
    merged_into_id uuid references public.songs (id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint songs_title_length check (char_length(btrim(title)) between 1 and 200),
    constraint songs_not_merged_into_itself check (merged_into_id is distinct from id)
);
create index songs_created_by_idx on public.songs (created_by);
create index songs_merged_into_idx on public.songs (merged_into_id);

-- Versions (arrangements) of a song. Only the owner edits or deletes.
create table public.song_versions (
    id uuid primary key default gen_random_uuid(),
    song_id uuid not null references public.songs (id),
    owner_id uuid not null references public.profiles (id),
    label text not null default 'Original',
    forked_from_version_id uuid references public.song_versions (id) on delete set null,
    visibility text not null default 'private'
        check (visibility in ('private', 'organizations', 'public')),
    key text not null default 'C',
    tempo integer not null default 120,
    time_signature_beats integer not null default 4,
    time_signature_beat_value integer not null default 4,
    sections_json text not null default '[]',
    tags_json text not null default '[]',
    cover_image_path text,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint song_versions_label_length check (char_length(btrim(label)) between 1 and 100)
);
create index song_versions_song_idx on public.song_versions (song_id);
create index song_versions_owner_idx on public.song_versions (owner_id);

-- Organizations a version with visibility 'organizations' is shared with.
create table public.version_shares (
    version_id uuid not null references public.song_versions (id) on delete cascade,
    organization_id uuid not null references public.organizations (id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (version_id, organization_id)
);
create index version_shares_organization_idx on public.version_shares (organization_id);

-- Scores (OMR / notation) belong to a version.
create table public.scores (
    id uuid primary key default gen_random_uuid(),
    version_id uuid not null references public.song_versions (id) on delete cascade,
    title text not null,
    composer text,
    artist text,
    time_signature jsonb not null default '{"numerator": 4, "denominator": 4}'::jsonb,
    key_signature text not null default 'C',
    tempo integer not null default 120,
    sections jsonb not null default '[]'::jsonb,
    metadata jsonb not null default '{}'::jsonb,
    deleted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index scores_version_idx on public.scores (version_id);

create table public.sections (
    id uuid primary key default gen_random_uuid(),
    score_id uuid not null references public.scores (id) on delete cascade,
    name text not null,
    format text not null default 'leadSheet',
    indications text,
    order_index integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index sections_score_idx on public.sections (score_id);

create table public.measures (
    id uuid primary key default gen_random_uuid(),
    section_id uuid not null references public.sections (id) on delete cascade,
    measure_number integer not null,
    time_signature text not null default '4/4',
    warning text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index measures_section_idx on public.measures (section_id);

create table public.note_events (
    id uuid primary key default gen_random_uuid(),
    measure_id uuid not null references public.measures (id) on delete cascade,
    pitch text not null,
    duration_ticks integer not null,
    lyric text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index note_events_measure_idx on public.note_events (measure_id);

create table public.chord_symbols (
    id uuid primary key default gen_random_uuid(),
    measure_id uuid not null references public.measures (id) on delete cascade,
    symbol text not null,
    beat_offset_ticks integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index chord_symbols_measure_idx on public.chord_symbols (measure_id);

-- The versions an organization plays. Admins pick among versions visible to it.
create table public.organization_repertoire (
    organization_id uuid not null references public.organizations (id) on delete cascade,
    version_id uuid not null references public.song_versions (id) on delete cascade,
    added_by uuid references public.profiles (id),
    created_at timestamptz not null default now(),
    primary key (organization_id, version_id)
);
create index organization_repertoire_version_idx on public.organization_repertoire (version_id);

create table public.song_merge_requests (
    id uuid primary key default gen_random_uuid(),
    source_song_id uuid not null references public.songs (id),
    target_song_id uuid not null references public.songs (id),
    requested_by uuid not null references public.profiles (id),
    approver_id uuid not null references public.profiles (id),
    -- Title snapshots so the approver sees both songs without read access.
    source_title text not null,
    target_title text not null,
    status text not null default 'pending'
        check (status in ('pending', 'accepted', 'declined', 'cancelled')),
    created_at timestamptz not null default now(),
    responded_at timestamptz,
    constraint song_merge_requests_distinct check (source_song_id <> target_song_id)
);
create unique index song_merge_requests_one_pending_idx
    on public.song_merge_requests (source_song_id, target_song_id) where status = 'pending';
create index song_merge_requests_approver_idx on public.song_merge_requests (approver_id);

create table public.setlists (
    id text primary key,
    organization_id uuid not null references public.organizations (id) on delete cascade,
    band_id uuid,
    created_by uuid references public.profiles (id),
    title text not null,
    description text,
    event_date timestamptz,
    tags_json text not null default '[]',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, organization_id),
    foreign key (band_id, organization_id)
        references public.bands (id, organization_id) on delete set null (band_id)
);
create index setlists_organization_idx on public.setlists (organization_id);

-- Setlist entries reference a repertoire version. When the version leaves the
-- repertoire, version_id becomes null and the snapshot keeps the entry readable.
create table public.setlist_items (
    id uuid primary key default gen_random_uuid(),
    setlist_id text not null,
    organization_id uuid not null,
    position integer not null default 0,
    version_id uuid,
    title_snapshot text not null,
    artist_snapshot text,
    label_snapshot text,
    key_snapshot text,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    foreign key (setlist_id, organization_id)
        references public.setlists (id, organization_id) on delete cascade,
    foreign key (organization_id, version_id)
        references public.organization_repertoire (organization_id, version_id)
        on delete set null (version_id)
);
create index setlist_items_setlist_idx on public.setlist_items (setlist_id, position);

create table public.calendar_events (
    id text primary key,
    organization_id uuid not null references public.organizations (id) on delete cascade,
    band_id uuid,
    created_by uuid references public.profiles (id),
    title text not null,
    date_time timestamptz not null,
    location text,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, organization_id),
    foreign key (band_id, organization_id)
        references public.bands (id, organization_id) on delete set null (band_id)
);
create index calendar_events_organization_idx on public.calendar_events (organization_id, date_time);

create table public.recurring_schedules (
    id text primary key,
    organization_id uuid not null references public.organizations (id) on delete cascade,
    band_id uuid,
    created_by uuid references public.profiles (id),
    title text not null,
    day_of_week integer not null default 7, -- 1=Monday, 7=Sunday
    pattern text not null default 'weekly',
    lookahead_count integer not null default 4,
    is_active boolean not null default true,
    disabled_after timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    foreign key (band_id, organization_id)
        references public.bands (id, organization_id) on delete set null (band_id)
);
create index recurring_schedules_organization_idx on public.recurring_schedules (organization_id);

-- Who plays what at an event. A removed member keeps past assignments (member_id
-- becomes null); future ones are deleted by trigger. Only the assigned member
-- answers; admins (re)assign.
create table public.event_assignments (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null,
    event_id text not null,
    member_id uuid,
    instrument text not null,
    response text not null default 'pending'
        check (response in ('pending', 'accepted', 'declined')),
    responded_at timestamptz,
    decline_reason text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (event_id, member_id, instrument),
    foreign key (event_id, organization_id)
        references public.calendar_events (id, organization_id) on delete cascade,
    foreign key (member_id, organization_id)
        references public.organization_members (id, organization_id) on delete set null (member_id)
);
create index event_assignments_event_idx on public.event_assignments (event_id);
create index event_assignments_member_idx on public.event_assignments (member_id);

-- Days a member is away. The member manages their own; admins can read.
create table public.member_absences (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null,
    member_id uuid not null,
    starts_on date not null,
    ends_on date not null,
    note text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint member_absences_range check (ends_on >= starts_on),
    foreign key (member_id, organization_id)
        references public.organization_members (id, organization_id) on delete cascade
);
create index member_absences_member_idx on public.member_absences (member_id, starts_on, ends_on);

create table public.notifications (
    id uuid primary key default gen_random_uuid(),
    recipient_id uuid not null references public.profiles (id),
    organization_id uuid references public.organizations (id) on delete cascade,
    type text not null,
    payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    read_at timestamptz
);
create index notifications_recipient_idx on public.notifications (recipient_id, created_at desc);

-- A row only exists to override the free default (see organization_quota()).
create table public.workspace_quotas (
    organization_id uuid primary key references public.organizations (id) on delete cascade,
    monthly_gemini_credits_limit integer not null default 5000,
    max_storage_bytes bigint not null default 1073741824, -- 1 GB
    tier text not null default 'free',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.workspace_usage (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null references public.organizations (id) on delete cascade,
    user_id uuid not null references public.profiles (id),
    billing_period text not null, -- 'YYYY-MM'
    gemini_tokens_used bigint not null default 0,
    gemini_scans_count integer not null default 0,
    gemini_credits_consumed integer not null default 0,
    storage_used_bytes bigint not null default 0,
    files_uploaded_count integer not null default 0,
    last_activity_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (organization_id, user_id, billing_period)
);
create index workspace_usage_user_idx on public.workspace_usage (user_id);

-- ------------------------------------------------------------------------------
-- 2. Helper functions (SECURITY DEFINER so policies do not recurse into RLS)
-- ------------------------------------------------------------------------------

create function public.require_uid()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then
        raise exception 'not_authenticated' using errcode = '28000';
    end if;
    if exists (select 1 from public.profiles p where p.id = v_uid and p.deactivated_at is not null) then
        raise exception 'account_deactivated' using errcode = 'P0001';
    end if;
    return v_uid;
end;
$$;

create function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.deactivated_at is null
    );
$$;

create function public.is_org_member(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.organization_members m
        where m.organization_id = p_org and m.user_id = auth.uid()
          and m.deactivated_at is null
    );
$$;

create function public.is_org_admin(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.organization_members m
        where m.organization_id = p_org and m.user_id = auth.uid()
          and m.role = 'admin' and m.deactivated_at is null
    );
$$;

create function public.is_org_active(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.organizations o
        where o.id = p_org and o.archived_at is null
    );
$$;

-- Admin of a non-archived organization: the gate for every admin write.
create function public.can_admin_org(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.is_org_admin(p_org) and public.is_org_active(p_org);
$$;

-- The member row belongs to the caller (active, organization not archived).
create function public.is_own_member(p_member uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.organization_members m
        join public.organizations o on o.id = m.organization_id
        where m.id = p_member and m.user_id = auth.uid()
          and m.deactivated_at is null and o.archived_at is null
    );
$$;

create function public.has_pending_invitation(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.invitations i
        where i.organization_id = p_org
          and i.invited_user_id = auth.uid()
          and i.status = 'pending'
    );
$$;

-- Follows merged_into_id to the surviving song (null if the song is unknown).
create function public.resolve_song(p_song uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    with recursive chain as (
        select s.id, s.merged_into_id, 0 as depth
        from public.songs s where s.id = p_song
        union all
        select s.id, s.merged_into_id, c.depth + 1
        from public.songs s join chain c on s.id = c.merged_into_id
        where c.depth < 50
    )
    select id from chain where merged_into_id is null order by depth desc limit 1;
$$;

-- Version visibility: owner, public, or shared to an organization I belong to.
-- Callable by anon (public versions are readable signed out).
create function public.can_see_version(p_version uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.song_versions v
        where v.id = p_version
          and (v.owner_id = auth.uid()
               or v.visibility = 'public'
               or (v.visibility = 'organizations' and exists (
                    select 1
                    from public.version_shares s
                    join public.organization_members m on m.organization_id = s.organization_id
                    where s.version_id = v.id
                      and m.user_id = auth.uid()
                      and m.deactivated_at is null)))
    );
$$;

-- A song is visible if I created it or can see one of its versions (or, when it
-- was merged away, one of the surviving song's versions). A private version
-- therefore never leaks its song title.
create function public.can_see_song(p_song uuid)
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
                    where v.song_id in (s.id, public.resolve_song(s.id))
                      and public.can_see_version(v.id)))
    );
$$;

create function public.owns_version(p_version uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.is_active_user() and exists (
        select 1 from public.song_versions v
        where v.id = p_version and v.owner_id = auth.uid()
    );
$$;

-- Is the version visible to an organization (shared to it, or public)?
create function public.version_visible_to_org(p_version uuid, p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.song_versions v
        where v.id = p_version
          and (v.visibility = 'public'
               or (v.visibility = 'organizations' and exists (
                    select 1 from public.version_shares s
                    where s.version_id = v.id and s.organization_id = p_org)))
    );
$$;

-- The owner may share only to organizations they actively belong to.
create function public.can_share_version(p_version uuid, p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.owns_version(p_version)
       and public.is_org_member(p_org)
       and public.is_org_active(p_org);
$$;

create function public.version_of_score(p_score uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select version_id from public.scores where id = p_score;
$$;

create function public.version_of_section(p_section uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select sc.version_id
    from public.sections s join public.scores sc on sc.id = s.score_id
    where s.id = p_section;
$$;

create function public.version_of_measure(p_measure uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select sc.version_id
    from public.measures m
    join public.sections s on s.id = m.section_id
    join public.scores sc on sc.id = s.score_id
    where m.id = p_measure;
$$;

-- A profile is visible to: itself, people sharing an organization (deactivated
-- ones included, as history), the inviter of my pending invitations, (for admins)
-- users invited to their organization, owners of versions I can see, and the
-- other side of a song merge request.
create function public.can_view_profile(p_profile uuid)
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
        )
        or exists (
            select 1 from public.song_merge_requests r
            where (r.requested_by = auth.uid() and r.approver_id = p_profile)
               or (r.approver_id = auth.uid() and r.requested_by = p_profile)
        );
$$;

-- Internal helpers: not granted to any client role.

create function public._notify(
    p_recipient uuid, p_org uuid, p_type text, p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if p_recipient is null then
        return;
    end if;
    if not exists (
        select 1 from public.profiles p where p.id = p_recipient and p.deactivated_at is null
    ) then
        return;
    end if;
    insert into public.notifications (recipient_id, organization_id, type, payload)
    values (p_recipient, p_org, p_type, coalesce(p_payload, '{}'::jsonb));
end;
$$;

create function public._notify_admins(
    p_org uuid, p_type text, p_payload jsonb, p_except uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    r record;
begin
    for r in
        select m.user_id from public.organization_members m
        where m.organization_id = p_org and m.role = 'admin' and m.deactivated_at is null
          and m.user_id is distinct from p_except
    loop
        perform public._notify(r.user_id, p_org, p_type, p_payload);
    end loop;
end;
$$;

create function public._notify_members(
    p_org uuid, p_type text, p_payload jsonb, p_except uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    r record;
begin
    for r in
        select m.user_id from public.organization_members m
        where m.organization_id = p_org and m.deactivated_at is null
          and m.user_id is distinct from p_except
    loop
        perform public._notify(r.user_id, p_org, p_type, p_payload);
    end loop;
end;
$$;

-- Archives an organization: read-only from now on, no joins, nothing deleted.
create function public._archive_org(p_org uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.organizations set archived_at = now()
    where id = p_org and archived_at is null;
    if not found then
        return;
    end if;
    delete from public.organization_archive_requests where organization_id = p_org;
    update public.invitations set status = 'cancelled', responded_at = now()
    where organization_id = p_org and status = 'pending';
    update public.invite_links set revoked_at = now()
    where organization_id = p_org and revoked_at is null;
    perform public._notify_members(p_org, 'archive_completed',
        jsonb_build_object('organization_id', p_org));
end;
$$;

-- Archives the organization when an open request has been approved by every
-- current (active) admin.
create function public._archive_check(p_org uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not exists (
        select 1 from public.organization_archive_requests r where r.organization_id = p_org
    ) then
        return;
    end if;
    if exists (
        select 1 from public.organization_members m
        where m.organization_id = p_org and m.role = 'admin' and m.deactivated_at is null
          and not exists (
              select 1 from public.organization_archive_approvals a
              where a.organization_id = p_org and a.user_id = m.user_id)
    ) then
        return;
    end if;
    perform public._archive_org(p_org);
end;
$$;

-- Removes band memberships and future assignments of a member row.
create function public._clear_member_schedule(p_member uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform set_config('battuta.silent', 'on', true);
    delete from public.band_members where member_id = p_member;
    delete from public.event_assignments a
    using public.calendar_events e
    where a.member_id = p_member
      and e.id = a.event_id
      and e.organization_id = a.organization_id
      and e.date_time > now();
    perform set_config('battuta.silent', 'off', true);
end;
$$;

-- Slack-style deactivation. Nothing authored is deleted.
create function public._deactivate_user(p_uid uuid)
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

    -- Only member of an active organization: archive it. (A last admin with other
    -- active members is rejected by guard_last_admin when the membership is
    -- deactivated below.)
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
    update public.profiles set deactivated_at = now(), avatar_url = null where id = p_uid;
end;
$$;

-- ------------------------------------------------------------------------------
-- 3. Triggers
-- ------------------------------------------------------------------------------

create function public.handle_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

do $$
declare
    t text;
begin
    foreach t in array array[
        'profiles', 'organizations', 'organization_members', 'bands', 'invitations',
        'songs', 'song_versions', 'scores', 'sections', 'measures', 'note_events',
        'chord_symbols', 'setlists', 'setlist_items', 'calendar_events',
        'recurring_schedules', 'event_assignments', 'member_absences',
        'workspace_quotas', 'workspace_usage'
    ] loop
        execute format(
            'create trigger trg_%1$s_updated_at before update on public.%1$I
             for each row execute function public.handle_updated_at()', t);
    end loop;
end;
$$;

-- Usernames are stored lowercase and trimmed.
create function public.normalize_profile()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.username := lower(btrim(new.username));
    new.display_name := btrim(new.display_name);
    return new;
end;
$$;

create trigger trg_profiles_normalize
    before insert or update on public.profiles
    for each row execute function public.normalize_profile();

-- Creates the profile on sign-up from user metadata (username, display_name).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_username text := lower(btrim(coalesce(new.raw_user_meta_data ->> 'username', '')));
    v_display text := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
begin
    if v_username !~ '^[a-z0-9_.]{3,30}$' then
        raise exception 'invalid_username' using errcode = '22023';
    end if;
    if v_display = '' then
        v_display := v_username;
    end if;
    insert into public.profiles (id, username, display_name)
    values (new.id, v_username, left(v_display, 80));
    return new;
exception
    when unique_violation then
        raise exception 'username_taken' using errcode = '23505';
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Deleting an auth user deactivates the profile instead of cascading anywhere.
create function public.handle_auth_user_deleted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public._deactivate_user(old.id);
    return old;
end;
$$;

create trigger on_auth_user_deleted
    before delete on auth.users
    for each row execute function public.handle_auth_user_deleted();

-- An active organization always keeps one active admin: blocks deleting,
-- demoting or deactivating the last one. The organization row is locked to
-- serialize concurrent changes. Archived organizations and organization deletion
-- skip the check.
create function public.guard_last_admin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_archived timestamptz;
begin
    if old.role <> 'admin' or old.deactivated_at is not null then
        return case tg_op when 'DELETE' then old else new end;
    end if;
    if tg_op = 'UPDATE' and new.role = 'admin' and new.deactivated_at is null then
        return new;
    end if;

    select o.archived_at into v_archived
    from public.organizations o where o.id = old.organization_id for update;
    if found and v_archived is null and not exists (
        select 1 from public.organization_members m
        where m.organization_id = old.organization_id
          and m.role = 'admin' and m.deactivated_at is null
          and m.id <> old.id
    ) then
        raise exception 'last_admin' using errcode = 'P0001';
    end if;

    return case tg_op when 'DELETE' then old else new end;
end;
$$;

create trigger trg_members_guard_last_admin
    before delete or update of role, deactivated_at on public.organization_members
    for each row execute function public.guard_last_admin();

-- An admin leaving/being demoted can complete a pending archive request.
create function public.members_archive_check()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public._archive_check(old.organization_id);
    return null;
end;
$$;

create trigger trg_members_archive_check
    after delete or update of role, deactivated_at on public.organization_members
    for each row execute function public.members_archive_check();

-- Removing a member deletes their future event assignments (past assignments are
-- kept). Their version shares, repertoire entries and setlist items stay, exactly
-- like deactivation; the owner can still unshare themselves.
create function public.purge_member_data()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform set_config('battuta.silent', 'on', true);
    delete from public.event_assignments a
    using public.calendar_events e
    where a.member_id = old.id
      and e.id = a.event_id
      and e.organization_id = a.organization_id
      and e.date_time > now();
    perform set_config('battuta.silent', 'off', true);
    return old;
end;
$$;

create trigger trg_members_purge_data
    before delete on public.organization_members
    for each row execute function public.purge_member_data();

-- Notifications on member changes: role change, and admin edits of musician fields.
create function public.members_notify_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_changed text[];
begin
    if old.role is distinct from new.role then
        perform public._notify(new.user_id, new.organization_id, 'role_changed',
            jsonb_build_object('member_id', new.id, 'old_role', old.role, 'new_role', new.role));
    end if;

    v_changed := array_remove(array[
        case when old.instruments is distinct from new.instruments then 'instruments' end,
        case when old.min_pitch is distinct from new.min_pitch then 'min_pitch' end,
        case when old.max_pitch is distinct from new.max_pitch then 'max_pitch' end,
        case when old.notes is distinct from new.notes then 'notes' end
    ], null);
    if cardinality(v_changed) > 0
       and auth.uid() is not null and auth.uid() <> new.user_id then
        perform public._notify(new.user_id, new.organization_id, 'member_profile_edited',
            jsonb_build_object('member_id', new.id, 'edited_by', auth.uid(),
                               'changed_fields', to_jsonb(v_changed)));
    end if;
    return null;
end;
$$;

create trigger trg_members_notify_changes
    after update on public.organization_members
    for each row execute function public.members_notify_changes();

-- Assignments: only the assignee answers, only admins (re)assign.
create function public.guard_assignment_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := auth.uid();
    v_is_assignee boolean;
    v_response_changed boolean;
    v_assignment_changed boolean;
begin
    if v_uid is null then
        return new; -- maintenance (service role / migrations)
    end if;
    if new.organization_id is distinct from old.organization_id
       or new.event_id is distinct from old.event_id then
        raise exception 'permission denied' using errcode = '42501';
    end if;
    v_response_changed := (new.response, new.responded_at, new.decline_reason)
        is distinct from (old.response, old.responded_at, old.decline_reason);
    v_assignment_changed := (new.member_id, new.instrument)
        is distinct from (old.member_id, old.instrument);

    if v_assignment_changed then
        if not public.can_admin_org(old.organization_id) then
            raise exception 'not_admin' using errcode = '42501';
        end if;
        new.response := 'pending';
        new.responded_at := null;
        new.decline_reason := null;
    elsif v_response_changed then
        select exists (
            select 1 from public.organization_members m
            where m.id = old.member_id and m.user_id = v_uid and m.deactivated_at is null
        ) into v_is_assignee;
        if not v_is_assignee then
            raise exception 'not_assignee' using errcode = '42501';
        end if;
        if new.response = 'pending' then
            new.responded_at := null;
            new.decline_reason := null;
        else
            new.responded_at := now();
            if new.response <> 'declined' then
                new.decline_reason := null;
            end if;
        end if;
    end if;
    return new;
end;
$$;

create trigger trg_assignments_guard_update
    before update on public.event_assignments
    for each row execute function public.guard_assignment_update();

create function public.assignments_notify()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_row public.event_assignments;
    v_event public.calendar_events;
    v_user uuid;
begin
    if current_setting('battuta.silent', true) = 'on' then
        return null;
    end if;

    if tg_op in ('INSERT', 'UPDATE') then
        v_row := new;
        select * into v_event from public.calendar_events
        where id = v_row.event_id and organization_id = v_row.organization_id;
        if tg_op = 'INSERT' or new.member_id is distinct from old.member_id then
            select m.user_id into v_user from public.organization_members m where m.id = new.member_id;
            perform public._notify(v_user, new.organization_id, 'event_assigned',
                jsonb_build_object('assignment_id', new.id, 'event_id', new.event_id,
                                   'event_title', v_event.title, 'date_time', v_event.date_time,
                                   'instrument', new.instrument));
        end if;
    end if;

    if tg_op = 'UPDATE' and new.member_id is distinct from old.member_id and old.member_id is not null then
        select m.user_id into v_user from public.organization_members m where m.id = old.member_id;
        perform public._notify(v_user, old.organization_id, 'event_unassigned',
            jsonb_build_object('assignment_id', old.id, 'event_id', old.event_id,
                               'event_title', v_event.title, 'instrument', old.instrument));
    end if;

    if tg_op = 'DELETE' and old.member_id is not null then
        select * into v_event from public.calendar_events
        where id = old.event_id and organization_id = old.organization_id;
        if found then -- skipped when the event itself is being deleted
            select m.user_id into v_user from public.organization_members m where m.id = old.member_id;
            perform public._notify(v_user, old.organization_id, 'event_unassigned',
                jsonb_build_object('assignment_id', old.id, 'event_id', old.event_id,
                                   'event_title', v_event.title, 'instrument', old.instrument));
        end if;
    end if;

    if tg_op = 'UPDATE' and new.response = 'declined' and old.response is distinct from 'declined' then
        select m.user_id into v_user from public.organization_members m where m.id = new.member_id;
        perform public._notify_admins(new.organization_id, 'assignment_declined',
            jsonb_build_object('assignment_id', new.id, 'event_id', new.event_id,
                               'event_title', v_event.title, 'member_id', new.member_id,
                               'instrument', new.instrument, 'reason', new.decline_reason),
            v_user);
    end if;
    return null;
end;
$$;

create trigger trg_assignments_notify
    after insert or update or delete on public.event_assignments
    for each row execute function public.assignments_notify();

-- Versions always attach to the surviving song of a merge chain.
create function public.song_versions_resolve_song()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    new.song_id := coalesce(public.resolve_song(new.song_id), new.song_id);
    return new;
end;
$$;

create trigger trg_song_versions_resolve_song
    before insert or update of song_id on public.song_versions
    for each row execute function public.song_versions_resolve_song();

-- Assignments cannot target a deactivated member.
create function public.assignments_guard_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if new.member_id is not null and exists (
        select 1 from public.organization_members m
        where m.id = new.member_id and m.deactivated_at is not null
    ) then
        raise exception 'member_deactivated' using errcode = 'P0001';
    end if;
    return new;
end;
$$;

create trigger trg_assignments_guard_member
    before insert or update of member_id on public.event_assignments
    for each row execute function public.assignments_guard_member();

-- A version that stops being visible to an organization leaves its repertoire.
create function public.version_shares_cleanup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    delete from public.organization_repertoire r
    where r.version_id = old.version_id
      and r.organization_id = old.organization_id
      and not public.version_visible_to_org(old.version_id, old.organization_id);
    return null;
end;
$$;

create trigger trg_version_shares_cleanup
    after delete on public.version_shares
    for each row execute function public.version_shares_cleanup();

create function public.version_visibility_cleanup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    -- Shares only make sense for 'organizations'; drop them so no uuid lingers.
    if new.visibility <> 'organizations' then
        delete from public.version_shares s where s.version_id = new.id;
    end if;
    delete from public.organization_repertoire r
    where r.version_id = new.id
      and not public.version_visible_to_org(new.id, r.organization_id);
    return null;
end;
$$;

create trigger trg_version_visibility_cleanup
    after update of visibility on public.song_versions
    for each row when (old.visibility is distinct from new.visibility)
    execute function public.version_visibility_cleanup();

-- Setlist entries snapshot the song so they survive leaving the repertoire.
create function public.setlist_items_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v record;
begin
    if new.version_id is not null then
        select s.title, s.artist, sv.label, sv.key into v
        from public.song_versions sv join public.songs s on s.id = sv.song_id
        where sv.id = new.version_id;
        if found then
            new.title_snapshot := v.title;
            new.artist_snapshot := v.artist;
            new.label_snapshot := v.label;
            new.key_snapshot := v.key;
        end if;
    end if;
    return new;
end;
$$;

create trigger trg_setlist_items_snapshot
    before insert on public.setlist_items
    for each row execute function public.setlist_items_snapshot();

-- ------------------------------------------------------------------------------
-- 4. Row Level Security
-- ------------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.organization_archive_requests enable row level security;
alter table public.organization_archive_approvals enable row level security;
alter table public.bands enable row level security;
alter table public.band_members enable row level security;
alter table public.invite_links enable row level security;
alter table public.invitations enable row level security;
alter table public.songs enable row level security;
alter table public.song_versions enable row level security;
alter table public.version_shares enable row level security;
alter table public.scores enable row level security;
alter table public.sections enable row level security;
alter table public.measures enable row level security;
alter table public.note_events enable row level security;
alter table public.chord_symbols enable row level security;
alter table public.organization_repertoire enable row level security;
alter table public.song_merge_requests enable row level security;
alter table public.setlists enable row level security;
alter table public.setlist_items enable row level security;
alter table public.calendar_events enable row level security;
alter table public.recurring_schedules enable row level security;
alter table public.event_assignments enable row level security;
alter table public.member_absences enable row level security;
alter table public.notifications enable row level security;
alter table public.workspace_quotas enable row level security;
alter table public.workspace_usage enable row level security;

-- Profiles (insert only via sign-up trigger; never deleted).
create policy profiles_select on public.profiles for select to authenticated
    using (public.can_view_profile(id));
create policy profiles_update_own on public.profiles for update to authenticated
    using (id = auth.uid() and deactivated_at is null)
    with check (id = auth.uid() and deactivated_at is null);

-- Organizations (created only via create_organization; archived are read-only).
create policy organizations_select on public.organizations for select to authenticated
    using (public.is_org_member(id) or public.has_pending_invitation(id));
create policy organizations_update_admin on public.organizations for update to authenticated
    using (public.can_admin_org(id)) with check (public.can_admin_org(id));

-- Members: no insert/delete policy, only RPCs. Column grants limit what an update
-- can touch (musician fields only, never role / organization_id / user_id).
create policy members_select on public.organization_members for select to authenticated
    using (public.is_org_member(organization_id));
create policy members_update on public.organization_members for update to authenticated
    using ((user_id = auth.uid() and deactivated_at is null and public.is_org_active(organization_id))
           or public.can_admin_org(organization_id))
    with check ((user_id = auth.uid() and deactivated_at is null and public.is_org_active(organization_id))
                or public.can_admin_org(organization_id));

create policy archive_requests_select on public.organization_archive_requests
    for select to authenticated using (public.is_org_member(organization_id));
create policy archive_approvals_select on public.organization_archive_approvals
    for select to authenticated using (public.is_org_member(organization_id));

-- Bands and band membership.
create policy bands_select on public.bands for select to authenticated
    using (public.is_org_member(organization_id));
create policy bands_write on public.bands for all to authenticated
    using (public.can_admin_org(organization_id))
    with check (public.can_admin_org(organization_id));

create policy band_members_select on public.band_members for select to authenticated
    using (public.is_org_member(organization_id));
create policy band_members_write on public.band_members for all to authenticated
    using (public.can_admin_org(organization_id))
    with check (public.can_admin_org(organization_id));

-- Invites: readable by admins; created/changed only through RPCs.
create policy invite_links_select on public.invite_links for select to authenticated
    using (public.is_org_admin(organization_id));
create policy invitations_select on public.invitations for select to authenticated
    using (invited_user_id = auth.uid() or public.is_org_admin(organization_id));

-- Songs and versions. Public content is readable by anon (signed-out share links).
create policy songs_select on public.songs for select to anon, authenticated
    using (public.can_see_song(id));
create policy songs_insert on public.songs for insert to authenticated
    with check (created_by = auth.uid() and public.is_active_user());
create policy songs_update on public.songs for update to authenticated
    using (created_by = auth.uid() and public.is_active_user())
    with check (created_by = auth.uid());
create policy songs_delete on public.songs for delete to authenticated
    using (created_by = auth.uid() and public.is_active_user());

create policy song_versions_select on public.song_versions for select to anon, authenticated
    using (public.can_see_version(id));
create policy song_versions_insert on public.song_versions for insert to authenticated
    with check (owner_id = auth.uid() and public.is_active_user() and public.can_see_song(song_id));
create policy song_versions_update on public.song_versions for update to authenticated
    using (public.owns_version(id)) with check (owner_id = auth.uid());
create policy song_versions_delete on public.song_versions for delete to authenticated
    using (public.owns_version(id));

create policy version_shares_select on public.version_shares for select to authenticated
    using (public.owns_version(version_id) or public.is_org_member(organization_id));
create policy version_shares_insert on public.version_shares for insert to authenticated
    with check (public.can_share_version(version_id, organization_id));
create policy version_shares_delete on public.version_shares for delete to authenticated
    using (public.owns_version(version_id));

create policy scores_select on public.scores for select to anon, authenticated
    using (public.can_see_version(version_id));
create policy scores_write on public.scores for all to authenticated
    using (public.owns_version(version_id))
    with check (public.owns_version(version_id));

create policy sections_select on public.sections for select to anon, authenticated
    using (public.can_see_version(public.version_of_score(score_id)));
create policy sections_write on public.sections for all to authenticated
    using (public.owns_version(public.version_of_score(score_id)))
    with check (public.owns_version(public.version_of_score(score_id)));

create policy measures_select on public.measures for select to anon, authenticated
    using (public.can_see_version(public.version_of_section(section_id)));
create policy measures_write on public.measures for all to authenticated
    using (public.owns_version(public.version_of_section(section_id)))
    with check (public.owns_version(public.version_of_section(section_id)));

create policy note_events_select on public.note_events for select to anon, authenticated
    using (public.can_see_version(public.version_of_measure(measure_id)));
create policy note_events_write on public.note_events for all to authenticated
    using (public.owns_version(public.version_of_measure(measure_id)))
    with check (public.owns_version(public.version_of_measure(measure_id)));

create policy chord_symbols_select on public.chord_symbols for select to anon, authenticated
    using (public.can_see_version(public.version_of_measure(measure_id)));
create policy chord_symbols_write on public.chord_symbols for all to authenticated
    using (public.owns_version(public.version_of_measure(measure_id)))
    with check (public.owns_version(public.version_of_measure(measure_id)));

-- Repertoire: members read; admins pick among versions visible to the organization.
create policy repertoire_select on public.organization_repertoire for select to authenticated
    using (public.is_org_member(organization_id));
create policy repertoire_insert on public.organization_repertoire for insert to authenticated
    with check (public.can_admin_org(organization_id)
                and added_by = auth.uid()
                and public.version_visible_to_org(version_id, organization_id));
create policy repertoire_delete on public.organization_repertoire for delete to authenticated
    using (public.can_admin_org(organization_id));

create policy merge_requests_select on public.song_merge_requests for select to authenticated
    using (requested_by = auth.uid() or approver_id = auth.uid());

-- Organization content: members read, admins write.
create policy setlists_select on public.setlists for select to authenticated
    using (public.is_org_member(organization_id));
create policy setlists_write on public.setlists for all to authenticated
    using (public.can_admin_org(organization_id))
    with check (public.can_admin_org(organization_id));

create policy setlist_items_select on public.setlist_items for select to authenticated
    using (public.is_org_member(organization_id));
create policy setlist_items_write on public.setlist_items for all to authenticated
    using (public.can_admin_org(organization_id))
    with check (public.can_admin_org(organization_id));

create policy calendar_events_select on public.calendar_events for select to authenticated
    using (public.is_org_member(organization_id));
create policy calendar_events_write on public.calendar_events for all to authenticated
    using (public.can_admin_org(organization_id))
    with check (public.can_admin_org(organization_id));

create policy recurring_schedules_select on public.recurring_schedules for select to authenticated
    using (public.is_org_member(organization_id));
create policy recurring_schedules_write on public.recurring_schedules for all to authenticated
    using (public.can_admin_org(organization_id))
    with check (public.can_admin_org(organization_id));

create policy event_assignments_select on public.event_assignments for select to authenticated
    using (public.is_org_member(organization_id));
create policy event_assignments_insert on public.event_assignments for insert to authenticated
    with check (public.can_admin_org(organization_id) and response = 'pending');
create policy event_assignments_update on public.event_assignments for update to authenticated
    using (public.can_admin_org(organization_id)
           or (member_id is not null and public.is_own_member(member_id)))
    with check (public.can_admin_org(organization_id)
                or (member_id is not null and public.is_own_member(member_id)));
create policy event_assignments_delete on public.event_assignments for delete to authenticated
    using (public.can_admin_org(organization_id));

create policy member_absences_select on public.member_absences for select to authenticated
    using (public.is_own_member(member_id) or public.is_org_admin(organization_id));
create policy member_absences_write on public.member_absences for all to authenticated
    using (public.is_own_member(member_id))
    with check (public.is_own_member(member_id));

create policy notifications_select on public.notifications for select to authenticated
    using (recipient_id = auth.uid());
create policy notifications_update on public.notifications for update to authenticated
    using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

create policy workspace_quotas_select on public.workspace_quotas for select to authenticated
    using (public.is_org_member(organization_id));
create policy workspace_usage_select on public.workspace_usage for select to authenticated
    using (public.is_org_member(organization_id));

-- ------------------------------------------------------------------------------
-- 5. RPCs
-- ------------------------------------------------------------------------------

-- Raises not_admin / organization_archived unless the caller can admin the org.
create function public._require_org_admin(p_org uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not public.is_org_admin(p_org) then
        raise exception 'not_admin' using errcode = '42501';
    end if;
    if not public.is_org_active(p_org) then
        raise exception 'organization_archived' using errcode = 'P0001';
    end if;
end;
$$;

create function public.create_organization(p_name text)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_name text := btrim(coalesce(p_name, ''));
    v_org public.organizations;
begin
    if char_length(v_name) not between 1 and 100 then
        raise exception 'invalid_name' using errcode = '22023';
    end if;
    insert into public.organizations (name, created_by)
    values (v_name, v_uid) returning * into v_org;
    insert into public.organization_members (organization_id, user_id, role)
    values (v_org.id, v_uid, 'admin');
    return v_org;
end;
$$;

-- Organizations the caller actively belongs to (archived ones only on request).
create function public.my_organizations(p_include_archived boolean default false)
returns setof public.organizations
language sql
stable
security definer
set search_path = ''
as $$
    select o.*
    from public.organizations o
    where exists (
            select 1 from public.organization_members m
            where m.organization_id = o.id and m.user_id = auth.uid()
              and m.deactivated_at is null)
      and (coalesce(p_include_archived, false) or o.archived_at is null)
    order by o.name;
$$;

-- Effective quota: the stored override, or the free default.
create function public.organization_quota(p_org uuid)
returns table (tier text, monthly_gemini_credits_limit integer, max_storage_bytes bigint)
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(q.tier, 'free'),
           coalesce(q.monthly_gemini_credits_limit, 5000),
           coalesce(q.max_storage_bytes, 1073741824::bigint)
    from (select 1) one
    left join public.workspace_quotas q on q.organization_id = p_org
    where public.is_org_member(p_org);
$$;

-- Archiving ---------------------------------------------------------------------

create function public.request_organization_archive(p_org uuid)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_org public.organizations;
begin
    perform public._require_org_admin(p_org);
    select * into v_org from public.organizations where id = p_org for update;
    if exists (select 1 from public.organization_archive_requests where organization_id = p_org) then
        raise exception 'archive_already_requested' using errcode = 'P0001';
    end if;
    insert into public.organization_archive_requests (organization_id, requested_by)
    values (p_org, v_uid);
    insert into public.organization_archive_approvals (organization_id, user_id)
    values (p_org, v_uid);
    perform public._notify_admins(p_org, 'archive_requested',
        jsonb_build_object('organization_id', p_org, 'organization_name', v_org.name,
                           'requested_by', v_uid), v_uid);
    perform public._archive_check(p_org);
    select * into v_org from public.organizations where id = p_org;
    return v_org;
end;
$$;

create function public.approve_organization_archive(p_org uuid)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_org public.organizations;
begin
    perform public._require_org_admin(p_org);
    perform 1 from public.organizations where id = p_org for update;
    if not exists (select 1 from public.organization_archive_requests where organization_id = p_org) then
        raise exception 'archive_not_requested' using errcode = 'P0001';
    end if;
    insert into public.organization_archive_approvals (organization_id, user_id)
    values (p_org, v_uid)
    on conflict do nothing;
    perform public._archive_check(p_org);
    select * into v_org from public.organizations where id = p_org;
    return v_org;
end;
$$;

create function public.cancel_organization_archive(p_org uuid)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_org public.organizations;
begin
    perform public._require_org_admin(p_org);
    select * into v_org from public.organizations where id = p_org for update;
    if not exists (select 1 from public.organization_archive_requests where organization_id = p_org) then
        raise exception 'archive_not_requested' using errcode = 'P0001';
    end if;
    delete from public.organization_archive_requests where organization_id = p_org;
    perform public._notify_admins(p_org, 'archive_cancelled',
        jsonb_build_object('organization_id', p_org, 'organization_name', v_org.name,
                           'cancelled_by', v_uid), v_uid);
    return v_org;
end;
$$;

-- Account -----------------------------------------------------------------------

create function public.deactivate_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
begin
    perform public._deactivate_user(v_uid);
end;
$$;

-- Invites -----------------------------------------------------------------------

create function public.create_invite_link(
    p_organization_id uuid,
    p_band_id uuid default null,
    p_expires_in interval default interval '7 days',
    p_max_uses integer default null
)
returns public.invite_links
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_link public.invite_links;
begin
    perform public._require_org_admin(p_organization_id);
    if p_expires_in is null or p_expires_in <= interval '0' then
        raise exception 'invalid_expiry' using errcode = '22023';
    end if;
    if p_max_uses is not null and p_max_uses < 1 then
        raise exception 'invalid_max_uses' using errcode = '22023';
    end if;
    if p_band_id is not null and not exists (
        select 1 from public.bands b
        where b.id = p_band_id and b.organization_id = p_organization_id
    ) then
        raise exception 'band_not_in_organization' using errcode = 'P0001';
    end if;
    insert into public.invite_links (organization_id, band_id, created_by, expires_at, max_uses)
    values (p_organization_id, p_band_id, v_uid, now() + p_expires_in, p_max_uses)
    returning * into v_link;
    return v_link;
end;
$$;

create function public.revoke_invite_link(p_link_id uuid)
returns public.invite_links
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_link public.invite_links;
begin
    perform public.require_uid();
    select * into v_link from public.invite_links where id = p_link_id;
    if not found then
        raise exception 'invite_not_found' using errcode = 'P0002';
    end if;
    perform public._require_org_admin(v_link.organization_id);
    update public.invite_links
    set revoked_at = coalesce(revoked_at, now())
    where id = p_link_id
    returning * into v_link;
    return v_link;
end;
$$;

-- Check order: not found, archived, revoked, expired, used up. A user who is
-- already a member succeeds without a duplicate row and without consuming a use;
-- the band of the link is still added. Concurrent double submits are safe
-- (insert ... on conflict do nothing).
create function public.join_with_invite_link(p_token text)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_link public.invite_links;
    v_member public.organization_members;
begin
    select * into v_link from public.invite_links where token = p_token for update;
    if not found then
        raise exception 'invite_not_found' using errcode = 'P0002';
    end if;
    if not public.is_org_active(v_link.organization_id) then
        raise exception 'organization_archived' using errcode = 'P0001';
    end if;
    if v_link.revoked_at is not null then
        raise exception 'invite_revoked' using errcode = 'P0001';
    end if;
    if v_link.expires_at <= now() then
        raise exception 'invite_expired' using errcode = 'P0001';
    end if;
    if v_link.max_uses is not null and v_link.use_count >= v_link.max_uses then
        raise exception 'invite_used_up' using errcode = 'P0001';
    end if;

    insert into public.organization_members (organization_id, user_id, role)
    values (v_link.organization_id, v_uid, 'member')
    on conflict (organization_id, user_id) do nothing
    returning * into v_member;
    if found then
        update public.invite_links set use_count = use_count + 1 where id = v_link.id;
    else
        select * into v_member from public.organization_members
        where organization_id = v_link.organization_id and user_id = v_uid;
    end if;

    if v_link.band_id is not null then
        insert into public.band_members (organization_id, band_id, member_id)
        values (v_link.organization_id, v_link.band_id, v_member.id)
        on conflict (band_id, member_id) do nothing;
    end if;
    return v_member;
end;
$$;

create function public.invite_user_by_username(
    p_organization_id uuid,
    p_username text,
    p_band_id uuid default null
)
returns public.invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_target uuid;
    v_invitation public.invitations;
    v_org_name text;
begin
    perform public._require_org_admin(p_organization_id);
    select id into v_target from public.profiles
    where lower(username) = lower(btrim(coalesce(p_username, '')))
      and deactivated_at is null;
    if v_target is null then
        raise exception 'user_not_found' using errcode = 'P0002';
    end if;
    if v_target = v_uid then
        raise exception 'cannot_invite_self' using errcode = 'P0001';
    end if;
    if exists (
        select 1 from public.organization_members
        where organization_id = p_organization_id and user_id = v_target
    ) then
        raise exception 'already_member' using errcode = 'P0001';
    end if;
    if exists (
        select 1 from public.invitations
        where organization_id = p_organization_id
          and invited_user_id = v_target and status = 'pending'
    ) then
        raise exception 'already_invited' using errcode = 'P0001';
    end if;
    if p_band_id is not null and not exists (
        select 1 from public.bands b
        where b.id = p_band_id and b.organization_id = p_organization_id
    ) then
        raise exception 'band_not_in_organization' using errcode = 'P0001';
    end if;
    insert into public.invitations (organization_id, band_id, invited_user_id, invited_by)
    values (p_organization_id, p_band_id, v_target, v_uid)
    returning * into v_invitation;
    select name into v_org_name from public.organizations where id = p_organization_id;
    perform public._notify(v_target, p_organization_id, 'invitation',
        jsonb_build_object('invitation_id', v_invitation.id, 'organization_id', p_organization_id,
                           'organization_name', v_org_name, 'band_id', p_band_id,
                           'invited_by', v_uid));
    return v_invitation;
end;
$$;

create function public.respond_to_invitation(p_invitation_id uuid, p_accept boolean)
returns public.invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_inv public.invitations;
    v_member_id uuid;
begin
    select * into v_inv from public.invitations
    where id = p_invitation_id and invited_user_id = v_uid for update;
    if not found then
        raise exception 'invitation_not_found' using errcode = 'P0002';
    end if;
    if v_inv.status <> 'pending' then
        raise exception 'invitation_not_pending' using errcode = 'P0001';
    end if;

    if coalesce(p_accept, false) then
        if not public.is_org_active(v_inv.organization_id) then
            raise exception 'organization_archived' using errcode = 'P0001';
        end if;
        insert into public.organization_members (organization_id, user_id, role)
        values (v_inv.organization_id, v_uid, 'member')
        on conflict (organization_id, user_id) do nothing;
        if v_inv.band_id is not null then
            select id into v_member_id from public.organization_members
            where organization_id = v_inv.organization_id and user_id = v_uid;
            insert into public.band_members (organization_id, band_id, member_id)
            values (v_inv.organization_id, v_inv.band_id, v_member_id)
            on conflict (band_id, member_id) do nothing;
        end if;
    end if;

    update public.invitations
    set status = case when coalesce(p_accept, false) then 'accepted' else 'declined' end,
        responded_at = now()
    where id = v_inv.id
    returning * into v_inv;
    return v_inv;
end;
$$;

create function public.cancel_invitation(p_invitation_id uuid)
returns public.invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_inv public.invitations;
begin
    perform public.require_uid();
    select * into v_inv from public.invitations where id = p_invitation_id for update;
    if not found then
        raise exception 'invitation_not_found' using errcode = 'P0002';
    end if;
    perform public._require_org_admin(v_inv.organization_id);
    if v_inv.status <> 'pending' then
        raise exception 'invitation_not_pending' using errcode = 'P0001';
    end if;
    update public.invitations
    set status = 'cancelled', responded_at = now()
    where id = v_inv.id
    returning * into v_inv;
    return v_inv;
end;
$$;

-- Members -----------------------------------------------------------------------

-- Demoting the last admin is rejected by the guard_last_admin trigger.
create function public.set_member_role(p_member_id uuid, p_role text)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_member public.organization_members;
begin
    perform public.require_uid();
    if p_role is null or p_role not in ('admin', 'member') then
        raise exception 'invalid_role' using errcode = '22023';
    end if;
    select * into v_member from public.organization_members where id = p_member_id;
    if not found then
        raise exception 'member_not_found' using errcode = 'P0002';
    end if;
    perform public._require_org_admin(v_member.organization_id);
    if v_member.deactivated_at is not null then
        raise exception 'member_deactivated' using errcode = 'P0001';
    end if;
    update public.organization_members set role = p_role
    where id = p_member_id returning * into v_member;
    return v_member;
end;
$$;

-- Removing the last admin is rejected by the guard_last_admin trigger.
create function public.remove_member(p_member_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_member public.organization_members;
    v_org_name text;
begin
    select * into v_member from public.organization_members where id = p_member_id;
    if not found then
        raise exception 'member_not_found' using errcode = 'P0002';
    end if;
    perform public._require_org_admin(v_member.organization_id);
    delete from public.organization_members where id = p_member_id;
    select name into v_org_name from public.organizations where id = v_member.organization_id;
    perform public._notify(v_member.user_id, v_member.organization_id, 'removed',
        jsonb_build_object('organization_id', v_member.organization_id,
                           'organization_name', v_org_name, 'removed_by', v_uid));
end;
$$;

create function public.leave_organization(p_organization_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
begin
    if not exists (
        select 1 from public.organization_members
        where organization_id = p_organization_id and user_id = v_uid
          and deactivated_at is null
    ) then
        raise exception 'not_member' using errcode = '42501';
    end if;
    delete from public.organization_members
    where organization_id = p_organization_id and user_id = v_uid;
end;
$$;

-- Active members of an organization without an absence on the given day.
create function public.members_available_on(p_org uuid, p_date date)
returns table (member_id uuid, user_id uuid, username text, display_name text)
language sql
stable
security definer
set search_path = ''
as $$
    select m.id, m.user_id, p.username, p.display_name
    from public.organization_members m
    join public.profiles p on p.id = m.user_id
    where public.is_org_member(p_org)
      and m.organization_id = p_org
      and m.deactivated_at is null
      and not exists (
          select 1 from public.member_absences a
          where a.member_id = m.id
            and p_date between a.starts_on and a.ends_on)
    order by p.username;
$$;

-- Username / display-name search. Never exposes email. Excludes the caller and
-- deactivated accounts.
create function public.search_profiles(p_query text)
returns table (id uuid, username text, display_name text, avatar_url text)
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
        select p.id, p.username, p.display_name, p.avatar_url
        from public.profiles p
        where p.id <> v_uid
          and p.deactivated_at is null
          and (p.username like v_like || '%' or lower(p.display_name) like '%' || v_like || '%')
        order by p.username
        limit 20;
end;
$$;

-- Pre-flight check for the sign-up form (callable while signed out). The unique
-- index remains the source of truth if two people race. Deactivated usernames
-- stay reserved.
create function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select lower(btrim(coalesce(p_username, ''))) ~ '^[a-z0-9_.]{3,30}$'
       and not exists (
           select 1 from public.profiles
           where lower(username) = lower(btrim(p_username))
       );
$$;

create function public.mark_notifications_read(p_ids uuid[] default null)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_count integer;
begin
    update public.notifications
    set read_at = now()
    where recipient_id = v_uid and read_at is null
      and (p_ids is null or id = any (p_ids));
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

create function public.record_gemini_scan_usage(
    p_organization_id uuid,
    p_tokens integer,
    p_credits integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_period text := to_char(now(), 'YYYY-MM');
begin
    if not public.is_org_member(p_organization_id) then
        raise exception 'not_member' using errcode = '42501';
    end if;
    if not public.is_org_active(p_organization_id) then
        raise exception 'organization_archived' using errcode = 'P0001';
    end if;
    if p_tokens < 0 or p_credits < 0 then
        raise exception 'invalid_amount' using errcode = '22023';
    end if;
    insert into public.workspace_usage (
        organization_id, user_id, billing_period,
        gemini_tokens_used, gemini_scans_count, gemini_credits_consumed
    )
    values (p_organization_id, v_uid, v_period, p_tokens, 1, p_credits)
    on conflict (organization_id, user_id, billing_period) do update set
        gemini_tokens_used = public.workspace_usage.gemini_tokens_used + excluded.gemini_tokens_used,
        gemini_scans_count = public.workspace_usage.gemini_scans_count + 1,
        gemini_credits_consumed = public.workspace_usage.gemini_credits_consumed
            + excluded.gemini_credits_consumed,
        last_activity_at = now();
end;
$$;

-- Songs: forks and merges ---------------------------------------------------------

-- Copies the score trees of one version into another.
create function public._copy_scores(p_from uuid, p_to uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    s record;
    sec record;
    m record;
    v_score uuid;
    v_section uuid;
    v_measure uuid;
begin
    for s in select * from public.scores where version_id = p_from and deleted_at is null loop
        insert into public.scores (version_id, title, composer, artist, time_signature,
                                   key_signature, tempo, sections, metadata)
        values (p_to, s.title, s.composer, s.artist, s.time_signature,
                s.key_signature, s.tempo, s.sections, s.metadata)
        returning id into v_score;
        for sec in select * from public.sections where score_id = s.id loop
            insert into public.sections (score_id, name, format, indications, order_index)
            values (v_score, sec.name, sec.format, sec.indications, sec.order_index)
            returning id into v_section;
            for m in select * from public.measures where section_id = sec.id loop
                insert into public.measures (section_id, measure_number, time_signature, warning)
                values (v_section, m.measure_number, m.time_signature, m.warning)
                returning id into v_measure;
                insert into public.note_events (measure_id, pitch, duration_ticks, lyric)
                select v_measure, n.pitch, n.duration_ticks, n.lyric
                from public.note_events n where n.measure_id = m.id;
                insert into public.chord_symbols (measure_id, symbol, beat_offset_ticks)
                select v_measure, c.symbol, c.beat_offset_ticks
                from public.chord_symbols c where c.measure_id = m.id;
            end loop;
        end loop;
    end loop;
end;
$$;

-- Anyone who can see a version can copy it (private by default) under the same
-- (surviving) song. The original owner is notified.
create function public.fork_song_version(p_version_id uuid, p_label text default null)
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
        public.resolve_song(v_src.song_id), v_uid,
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

-- Moves every version of the source under the target and leaves a redirect.
create function public._merge_songs(p_source uuid, p_target uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_source uuid := public.resolve_song(p_source);
    v_target uuid := public.resolve_song(p_target);
begin
    if v_source = v_target then
        raise exception 'merge_cycle' using errcode = 'P0001';
    end if;
    update public.song_versions set song_id = v_target where song_id = v_source;
    update public.songs set merged_into_id = v_target where id = v_source;
    update public.songs set merged_into_id = v_target where merged_into_id = v_source;
    update public.song_merge_requests set status = 'cancelled', responded_at = now()
    where status = 'pending' and (source_song_id = v_source or target_song_id = v_source);
end;
$$;

create function public.request_song_merge(p_source_song uuid, p_target_song uuid)
returns public.song_merge_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_source public.songs;
    v_target public.songs;
    v_approver uuid;
    v_req public.song_merge_requests;
    v_auto boolean;
begin
    if p_source_song = p_target_song then
        raise exception 'merge_same_song' using errcode = 'P0001';
    end if;
    if not public.can_see_song(p_source_song) or not public.can_see_song(p_target_song) then
        raise exception 'song_not_found' using errcode = 'P0002';
    end if;
    select * into v_source from public.songs where id = public.resolve_song(p_source_song);
    select * into v_target from public.songs where id = public.resolve_song(p_target_song);
    if v_source.id = v_target.id then
        raise exception 'merge_cycle' using errcode = 'P0001';
    end if;
    if v_source.created_by <> v_uid and v_target.created_by <> v_uid then
        raise exception 'not_song_creator' using errcode = '42501';
    end if;
    if exists (
        select 1 from public.song_merge_requests r
        where r.source_song_id = v_source.id and r.target_song_id = v_target.id
          and r.status = 'pending'
    ) then
        raise exception 'merge_already_requested' using errcode = 'P0001';
    end if;

    v_approver := case when v_source.created_by = v_uid then v_target.created_by
                       else v_source.created_by end;
    -- Auto-approved when the requester created both, or the other creator is deactivated.
    v_auto := v_approver = v_uid or exists (
        select 1 from public.profiles p where p.id = v_approver and p.deactivated_at is not null);

    insert into public.song_merge_requests (
        source_song_id, target_song_id, requested_by, approver_id,
        source_title, target_title, status, responded_at)
    values (v_source.id, v_target.id, v_uid, v_approver, v_source.title, v_target.title,
            case when v_auto then 'accepted' else 'pending' end,
            case when v_auto then now() end)
    returning * into v_req;

    if v_auto then
        perform public._merge_songs(v_source.id, v_target.id);
    else
        perform public._notify(v_approver, null, 'song_merge_requested',
            jsonb_build_object('request_id', v_req.id, 'source_song_id', v_source.id,
                               'target_song_id', v_target.id, 'source_title', v_source.title,
                               'target_title', v_target.title, 'requested_by', v_uid));
    end if;
    return v_req;
end;
$$;

create function public.respond_to_song_merge(p_request_id uuid, p_accept boolean)
returns public.song_merge_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := public.require_uid();
    v_req public.song_merge_requests;
begin
    select * into v_req from public.song_merge_requests
    where id = p_request_id and approver_id = v_uid for update;
    if not found then
        raise exception 'merge_request_not_found' using errcode = 'P0002';
    end if;
    if v_req.status <> 'pending' then
        raise exception 'merge_not_pending' using errcode = 'P0001';
    end if;
    if coalesce(p_accept, false) then
        perform public._merge_songs(v_req.source_song_id, v_req.target_song_id);
    end if;
    update public.song_merge_requests
    set status = case when coalesce(p_accept, false) then 'accepted' else 'declined' end,
        responded_at = now()
    where id = v_req.id
    returning * into v_req;
    perform public._notify(v_req.requested_by, null,
        case when coalesce(p_accept, false) then 'song_merge_accepted' else 'song_merge_declined' end,
        jsonb_build_object('request_id', v_req.id, 'source_song_id', v_req.source_song_id,
                           'target_song_id', v_req.target_song_id, 'responded_by', v_uid));
    return v_req;
end;
$$;

-- ------------------------------------------------------------------------------
-- 6. Grants (least privilege; RLS then narrows rows)
-- ------------------------------------------------------------------------------

revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;

grant select on public.profiles, public.organizations, public.organization_members,
    public.organization_archive_requests, public.organization_archive_approvals,
    public.bands, public.band_members, public.invite_links, public.invitations,
    public.version_shares, public.organization_repertoire, public.song_merge_requests,
    public.notifications, public.workspace_quotas, public.workspace_usage to authenticated;
grant update (username, display_name, avatar_url) on public.profiles to authenticated;
grant update (name) on public.organizations to authenticated;
grant update (instruments, min_pitch, max_pitch, notes)
    on public.organization_members to authenticated;
grant update (read_at) on public.notifications to authenticated;
grant insert, update, delete on public.bands, public.band_members to authenticated;

-- Songs: public content is readable by anon.
grant select on public.songs, public.song_versions, public.scores, public.sections,
    public.measures, public.note_events, public.chord_symbols to anon, authenticated;
grant insert (id, title, artist, created_by) on public.songs to authenticated;
grant update (title, artist) on public.songs to authenticated;
grant delete on public.songs to authenticated;
grant insert (id, song_id, owner_id, label, visibility, key, tempo, time_signature_beats,
              time_signature_beat_value, sections_json, tags_json, cover_image_path, notes)
    on public.song_versions to authenticated;
grant update (label, visibility, key, tempo, time_signature_beats, time_signature_beat_value,
              sections_json, tags_json, cover_image_path, notes)
    on public.song_versions to authenticated;
grant delete on public.song_versions to authenticated;
grant insert, delete on public.version_shares to authenticated;
grant insert, update, delete on public.scores, public.sections, public.measures,
    public.note_events, public.chord_symbols to authenticated;
grant insert, delete on public.organization_repertoire to authenticated;

grant select, insert, update, delete on
    public.setlists, public.setlist_items, public.calendar_events,
    public.recurring_schedules to authenticated;
grant select, insert, delete on public.event_assignments to authenticated;
grant update (member_id, instrument, response, responded_at, decline_reason)
    on public.event_assignments to authenticated;
grant select, insert, update, delete on public.member_absences to authenticated;

-- Helpers used inside policies (anon can evaluate the public-content ones).
grant execute on function
    public.can_see_version(uuid), public.can_see_song(uuid), public.resolve_song(uuid),
    public.version_of_score(uuid), public.version_of_section(uuid),
    public.version_of_measure(uuid)
    to anon, authenticated;
grant execute on function
    public.is_org_member(uuid), public.is_org_admin(uuid), public.is_org_active(uuid),
    public.can_admin_org(uuid), public.is_own_member(uuid), public.is_active_user(),
    public.has_pending_invitation(uuid), public.can_view_profile(uuid),
    public.owns_version(uuid), public.version_visible_to_org(uuid, uuid),
    public.can_share_version(uuid, uuid)
    to authenticated;

-- RPCs.
grant execute on function
    public.create_organization(text),
    public.my_organizations(boolean),
    public.organization_quota(uuid),
    public.request_organization_archive(uuid),
    public.approve_organization_archive(uuid),
    public.cancel_organization_archive(uuid),
    public.deactivate_account(),
    public.create_invite_link(uuid, uuid, interval, integer),
    public.revoke_invite_link(uuid),
    public.join_with_invite_link(text),
    public.invite_user_by_username(uuid, text, uuid),
    public.respond_to_invitation(uuid, boolean),
    public.cancel_invitation(uuid),
    public.set_member_role(uuid, text),
    public.remove_member(uuid),
    public.leave_organization(uuid),
    public.members_available_on(uuid, date),
    public.search_profiles(text),
    public.mark_notifications_read(uuid[]),
    public.record_gemini_scan_usage(uuid, integer, integer),
    public.fork_song_version(uuid, text),
    public.request_song_merge(uuid, uuid),
    public.respond_to_song_merge(uuid, boolean)
    to authenticated;
grant execute on function public.is_username_available(text) to anon, authenticated;

-- ------------------------------------------------------------------------------
-- 7. Realtime
-- ------------------------------------------------------------------------------

do $$
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
        alter publication supabase_realtime add table
            public.organization_members, public.calendar_events,
            public.event_assignments, public.invitations, public.notifications;
    end if;
end;
$$;
