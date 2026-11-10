-- Shared test helpers (each file is self-contained and rolls back).
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

create schema tests;
grant usage on schema tests to anon, authenticated;

create table tests.kv (k text primary key, v text);
grant all on tests.kv to anon, authenticated;

create function tests.create_user(p_username text, p_display text default null)
returns uuid language plpgsql as $$
declare v uuid := gen_random_uuid();
begin
    insert into auth.users (id, email, raw_user_meta_data)
    values (v, p_username || '@example.test',
            jsonb_build_object('username', p_username, 'display_name', p_display));
    return v;
end $$;

create function tests.uid(p_username text) returns uuid
language sql stable security definer set search_path = '' as $$
    select id from public.profiles where username = lower(p_username) $$;

create function tests.org(p_name text) returns uuid
language sql stable security definer set search_path = '' as $$
    select id from public.organizations where name = p_name $$;

create function tests.band(p_name text) returns uuid
language sql stable security definer set search_path = '' as $$
    select id from public.bands where name = p_name $$;

create function tests.member(p_org text, p_username text) returns uuid
language sql stable security definer set search_path = '' as $$
    select m.id from public.organization_members m
    join public.organizations o on o.id = m.organization_id
    join public.profiles p on p.id = m.user_id
    where o.name = p_org and p.username = lower(p_username) $$;

create function tests.save(p_key text, p_value text) returns void
language sql as $$
    insert into tests.kv values (p_key, p_value)
    on conflict (k) do update set v = excluded.v $$;

create function tests.get(p_key text) returns text
language sql stable as $$ select v from tests.kv where k = p_key $$;

create function tests.reset() returns void language plpgsql as $$
begin
    execute 'reset role';
    perform set_config('request.jwt.claims', '', true);
end $$;

create function tests.as_user(p_username text) returns void language plpgsql as $$
begin
    perform tests.reset();
    perform set_config('request.jwt.claims',
        json_build_object('sub', tests.uid(p_username), 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
end $$;

create function tests.as_anon() returns void language plpgsql as $$
begin
    perform tests.reset();
    perform set_config('request.jwt.claims', '{"role":"anon"}', true);
    execute 'set local role anon';
end $$;

create function tests.song(p_title text) returns uuid
language sql stable security definer set search_path = '' as $$
    select id from public.songs where title = p_title $$;

create function tests.version(p_label text) returns uuid
language sql stable security definer set search_path = '' as $$
    select id from public.song_versions where label = p_label $$;

create function tests.notifs(p_username text, p_type text) returns int
language sql stable security definer set search_path = '' as $$
    select count(*)::int from public.notifications
    where recipient_id = (select id from public.profiles where username = lower(p_username))
      and type = p_type $$;

-- ============================================================================
-- Organizations, membership, roles, bands and content permissions
-- Users: alice+eve admins of Org A, bob+frank members of Org A, carol outsider,
--        dave sole admin of Org B.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','dave','eve','frank']) as u;

-- create_organization ----------------------------------------------------------
select tests.as_user('alice');
select is((select name from public.create_organization('  Org A ')), 'Org A', 'create_organization trims the name');
select throws_ok($$ select public.create_organization('   ') $$, '22023', 'invalid_name', 'blank name rejected');
select throws_ok($$ select public.create_organization(repeat('x', 101)) $$, '22023', 'invalid_name', 'long name rejected');
select is((select count(*)::int from public.organization_members where role = 'admin'), 1,
          'creator becomes the admin member');
select is((select count(*)::int from public.workspace_quotas), 0, 'no quota row is created per organization');
select is((select tier from public.organization_quota(tests.org('Org A'))), 'free', 'new organizations get the free default');

select tests.as_user('dave');
select lives_ok($$ select public.create_organization('Org B') $$, 'dave creates Org B');
select tests.reset();

-- Seed the rest of the roster directly (membership has no insert path for users).
insert into public.organization_members (organization_id, user_id, role) values
    (tests.org('Org A'), tests.uid('eve'), 'admin'),
    (tests.org('Org A'), tests.uid('bob'), 'member'),
    (tests.org('Org A'), tests.uid('frank'), 'member');

-- Bands (admin-only writes) ----------------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.bands (id, organization_id, name)
    values ('00000000-0000-0000-0000-0000000000a1', %L, 'Band A1') $$, tests.org('Org A')),
    'admin creates a band');
select tests.as_user('bob');
select throws_ok(format($$ insert into public.bands (organization_id, name) values (%L, 'Rogue') $$, tests.org('Org A')),
    '42501', null, 'member cannot create a band');
select tests.as_user('dave');
select lives_ok(format($$ insert into public.bands (id, organization_id, name)
    values ('00000000-0000-0000-0000-0000000000b1', %L, 'Band B1') $$, tests.org('Org B')),
    'Org B admin creates a band');
select tests.as_user('alice');
select throws_ok(format($$ insert into public.bands (organization_id, name) values (%L, 'Wrong org') $$, tests.org('Org B')),
    '42501', null, 'admin cannot create a band in another organization');

-- Visibility --------------------------------------------------------------------
select tests.as_user('bob');
select is((select count(*)::int from public.organizations), 1, 'member sees only their organization');
select is((select count(*)::int from public.organization_members), 4, 'member sees the roster of their organization');
select is((select count(*)::int from public.bands), 1, 'member sees their organization bands');
select is((select count(*)::int from public.profiles), 4, 'member sees profiles of co-members only');
select tests.as_user('carol');
select is((select count(*)::int from public.organizations), 0, 'outsider sees no organization');
select is((select count(*)::int from public.organization_members), 0, 'outsider sees no members');
select is((select count(*)::int from public.bands), 0, 'outsider sees no bands');
select is((select count(*)::int from public.workspace_quotas), 0, 'outsider sees no quotas');

-- Self-promotion attack (old hole) ------------------------------------------------
select tests.as_user('carol');
select throws_ok(format($$ insert into public.organization_members (organization_id, user_id, role)
    values (%L, %L, 'admin') $$, tests.org('Org A'), tests.uid('carol')),
    '42501', null, 'outsider cannot insert themselves as admin of an organization');
select throws_ok($$ insert into public.organizations (name) values ('Mine') $$, '42501', null,
    'organizations cannot be inserted directly');
select throws_ok(format($$ insert into public.organization_members (organization_id, user_id)
    values (%L, %L) $$, tests.org('Org A'), tests.uid('carol')),
    '42501', null, 'outsider cannot insert themselves as member either');

select tests.as_user('bob');
select throws_ok(format($$ update public.organization_members set role = 'admin' where id = %L $$,
    tests.member('Org A', 'bob')), '42501', null, 'member cannot promote themself');
select throws_ok(format($$ update public.organization_members set organization_id = %L where id = %L $$,
    tests.org('Org B'), tests.member('Org A', 'bob')), '42501', null, 'member cannot move to another organization');
select throws_ok(format($$ update public.organization_members set user_id = %L where id = %L $$,
    tests.uid('carol'), tests.member('Org A', 'bob')), '42501', null, 'user_id cannot be reassigned');
select throws_ok(format($$ delete from public.organization_members where id = %L $$,
    tests.member('Org A', 'bob')), '42501', null, 'members cannot be deleted directly');
select tests.as_user('alice');
select throws_ok(format($$ update public.organization_members set role = 'member' where id = %L $$,
    tests.member('Org A', 'bob')), '42501', null, 'even admins cannot change role directly (RPC only)');
select throws_ok(format($$ insert into public.organization_members (organization_id, user_id)
    values (%L, %L) $$, tests.org('Org A'), tests.uid('carol')),
    '42501', null, 'even admins cannot add members directly (RPC only)');

-- Musician fields ---------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(format($$ update public.organization_members
    set instruments = array['bass'], min_pitch = 'E1', max_pitch = 'G3', notes = 'hi'
    where id = %L $$, tests.member('Org A', 'bob')), 'member edits own musician fields');
update public.organization_members set notes = 'pwned' where id = (select tests.member('Org A', 'alice'));
select tests.reset();
select is((select min_pitch from public.organization_members where id = tests.member('Org A', 'bob')),
    'E1', 'own musician fields persisted');
select is((select notes from public.organization_members where id = tests.member('Org A', 'alice')),
    null, 'member cannot edit another member''s fields');
select tests.as_user('alice');
select lives_ok(format($$ update public.organization_members set notes = 'ok' where id = %L $$,
    tests.member('Org A', 'bob')), 'admin can edit a member''s fields');
select tests.as_user('carol');
update public.organization_members set notes = 'pwned' where id = (select tests.member('Org A', 'bob'));
select tests.reset();
select is((select notes from public.organization_members where id = tests.member('Org A', 'bob')),
    'ok', 'outsider cannot edit members');

-- Organization rename -----------------------------------------------------------------
select tests.as_user('bob');
update public.organizations set name = 'Hijacked' where id = tests.org('Org A');
select tests.as_user('carol');
update public.organizations set name = 'Hijacked' where id = tests.org('Org A');
select tests.reset();
select is((select name from public.organizations where id = tests.org('Org A')), 'Org A', 'only admins can rename');
select tests.as_user('alice');
select throws_ok(format($$ update public.organizations set created_by = %L where id = %L $$,
    tests.uid('alice'), tests.org('Org A')), '42501', null, 'only the name column is updatable');

-- set_member_role -------------------------------------------------------------------------
select tests.as_user('bob');
select throws_ok(format($$ select public.set_member_role(%L, 'admin') $$, tests.member('Org A', 'bob')),
    '42501', 'not_admin', 'member cannot call set_member_role');
select tests.as_user('carol');
select throws_ok(format($$ select public.set_member_role(%L, 'admin') $$, tests.member('Org A', 'bob')),
    '42501', 'not_admin', 'outsider cannot call set_member_role');
select tests.as_user('alice');
select throws_ok(format($$ select public.set_member_role(%L, 'owner') $$, tests.member('Org A', 'bob')),
    '22023', 'invalid_role', 'invalid role');
select throws_ok($$ select public.set_member_role(gen_random_uuid(), 'admin') $$,
    'P0002', 'member_not_found', 'unknown member');
select is((select role from public.set_member_role(tests.member('Org A', 'frank'), 'admin')), 'admin',
    'admin promotes a member');
select is((select role from public.set_member_role(tests.member('Org A', 'frank'), 'member')), 'member',
    'admin demotes an admin while another admin exists');
select tests.as_anon();
select throws_ok($$ select public.set_member_role(gen_random_uuid(), 'admin') $$, '42501', null, 'anon denied');

-- Last admin protection ------------------------------------------------------------------
select tests.as_user('dave');
select throws_ok(format($$ select public.set_member_role(%L, 'member') $$, tests.member('Org B', 'dave')),
    'P0001', 'last_admin', 'last admin cannot be demoted');
select throws_ok(format($$ select public.remove_member(%L) $$, tests.member('Org B', 'dave')),
    'P0001', 'last_admin', 'last admin cannot be removed');
select throws_ok(format($$ select public.leave_organization(%L) $$, tests.org('Org B')),
    'P0001', 'last_admin', 'last admin cannot leave');
select tests.reset();
select throws_ok(format($$ update public.organization_members set role = 'member' where id = %L $$,
    tests.member('Org B', 'dave')), 'P0001', 'last_admin', 'even superuser-level demotion is blocked by the trigger');

-- Removing a member cleans up band memberships and future assignments --------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band A1'), %L) $$, tests.org('Org A'), tests.member('Org A', 'frank')),
    'admin adds a member to a band');
select lives_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band A1'), %L) $$, tests.org('Org A'), tests.member('Org A', 'bob')),
    'admin adds another member to a band');
select throws_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band A1'), %L) $$, tests.org('Org A'), tests.member('Org A', 'bob')),
    '23505', null, 'a member cannot be in the same band twice');
select lives_ok(format($$ insert into public.calendar_events (id, organization_id, band_id, title, date_time) values
    ('evt-future', %1$L, tests.band('Band A1'), 'Future', now() + interval '2 days'),
    ('evt-past', %1$L, tests.band('Band A1'), 'Past', now() - interval '2 days') $$, tests.org('Org A')),
    'admin creates events');
select lives_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument) values
    (%1$L, 'evt-future', %2$L, 'drums'), (%1$L, 'evt-past', %2$L, 'drums'),
    (%1$L, 'evt-future', %3$L, 'bass') $$, tests.org('Org A'), tests.member('Org A', 'frank'), tests.member('Org A', 'bob')),
    'admin assigns members to events');

select tests.as_user('bob');
select throws_ok(format($$ select public.remove_member(%L) $$, tests.member('Org A', 'frank')),
    '42501', 'not_admin', 'member cannot remove a member');
select tests.as_user('carol');
select throws_ok(format($$ select public.remove_member(%L) $$, tests.member('Org A', 'frank')),
    '42501', 'not_admin', 'outsider cannot remove a member');
select tests.as_user('alice');
select throws_ok($$ select public.remove_member(gen_random_uuid()) $$, 'P0002', 'member_not_found', 'unknown member');
select lives_ok(format($$ select public.remove_member(%L) $$, tests.member('Org A', 'frank')), 'admin removes a member');
select tests.reset();
select is((select count(*)::int from public.organization_members where user_id = tests.uid('frank')), 0, 'member row removed');
select is((select count(*)::int from public.band_members where band_id = tests.band('Band A1')), 1,
    'removed member''s band memberships are gone (other membership kept)');
select is((select count(*)::int from public.event_assignments where event_id = 'evt-future'), 1,
    'future assignments of the removed member are deleted');
select is((select count(*)::int from public.event_assignments where event_id = 'evt-past' and member_id is null), 1,
    'past assignments are kept with member_id cleared');

-- Band membership only within the same organization -------------------------------------------------
select tests.as_user('alice');
select throws_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band A1'), %L) $$, tests.org('Org A'), tests.member('Org B', 'dave')),
    '23503', null, 'cannot add a member of another organization to a band');
select throws_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band B1'), %L) $$, tests.org('Org A'), tests.member('Org A', 'eve')),
    '23503', null, 'cannot add a member to a band of another organization (org id spoofed)');
select throws_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band B1'), %L) $$, tests.org('Org B'), tests.member('Org A', 'eve')),
    '42501', null, 'cannot write band members of an organization you do not administer');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, band_id, title, date_time)
    values ('evt-x', %L, tests.band('Band B1'), 'X', now()) $$, tests.org('Org A')),
    '23503', null, 'event cannot reference a band of another organization');
select throws_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    values (%L, 'evt-future', %L, 'keys') $$, tests.org('Org A'), tests.member('Org B', 'dave')),
    '23503', null, 'cannot assign a member of another organization to an event');

select tests.as_user('bob');
select is((select count(*)::int from public.band_members), 1, 'members can read band membership');
select throws_ok(format($$ insert into public.band_members (organization_id, band_id, member_id)
    values (%L, tests.band('Band A1'), %L) $$, tests.org('Org A'), tests.member('Org A', 'eve')),
    '42501', null, 'member cannot edit band membership');
select tests.as_user('carol');
select is((select count(*)::int from public.band_members), 0, 'outsider cannot read band membership');

-- (Songs, versions and score trees are covered in 06_songs.test.sql.)

-- Setlists, events, schedules, assignments -------------------------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.setlists (id, organization_id, band_id, title)
    values ('set-1', %L, tests.band('Band A1'), 'Sunday') $$, tests.org('Org A')), 'admin writes a setlist');
select lives_ok(format($$ insert into public.recurring_schedules (id, organization_id, title)
    values ('rec-1', %L, 'Weekly') $$, tests.org('Org A')), 'admin writes a recurring schedule');
select tests.as_user('bob');
select is((select count(*)::int from public.setlists), 1, 'member reads setlists');
select is((select count(*)::int from public.calendar_events), 2, 'member reads events');
select is((select count(*)::int from public.recurring_schedules), 1, 'member reads schedules');
select is((select count(*)::int from public.event_assignments), 2, 'member reads assignments');
select throws_ok(format($$ insert into public.setlists (id, organization_id, title) values ('set-2', %L, 'x') $$,
    tests.org('Org A')), '42501', null, 'member cannot write setlists');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time)
    values ('evt-bob', %L, 'x', now()) $$, tests.org('Org A')), '42501', null, 'member cannot write events');
select throws_ok(format($$ insert into public.recurring_schedules (id, organization_id, title) values ('rec-2', %L, 'x') $$,
    tests.org('Org A')), '42501', null, 'member cannot write schedules');
select throws_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    values (%L, 'evt-future', %L, 'keys') $$, tests.org('Org A'), tests.member('Org A', 'bob')),
    '42501', null, 'member cannot assign themself to an event');
update public.calendar_events set title = 'Hacked' where id = 'evt-future';
delete from public.event_assignments;
select tests.reset();
select is((select title from public.calendar_events where id = 'evt-future'), 'Future', 'member cannot edit events');
select is((select count(*)::int from public.event_assignments), 2, 'member cannot delete assignments');
select tests.as_user('carol');
select is((select count(*)::int from public.setlists) + (select count(*)::int from public.calendar_events)
        + (select count(*)::int from public.recurring_schedules) + (select count(*)::int from public.event_assignments),
    0, 'outsider reads no organization content');
select tests.as_user('dave');
select is((select count(*)::int from public.calendar_events), 0, 'other organization admin reads nothing of Org A');
select throws_ok(format($$ insert into public.setlists (id, organization_id, title) values ('set-3', %L, 'x') $$,
    tests.org('Org A')), '42501', null, 'admin of another organization cannot write here');

-- Quotas and usage -------------------------------------------------------------------------------------
select tests.reset();
insert into public.workspace_quotas (organization_id, tier, max_storage_bytes)
    values (tests.org('Org A'), 'pro', 5000);
select tests.as_user('bob');
select is((select tier from public.organization_quota(tests.org('Org A'))), 'pro', 'override replaces the free default');
select tests.as_user('carol');
select is((select count(*)::int from public.organization_quota(tests.org('Org A'))), 0, 'outsider cannot read the quota');
select tests.as_user('bob');
select is((select count(*)::int from public.workspace_quotas), 1, 'member reads the organization quota');
select throws_ok($$ update public.workspace_quotas set max_storage_bytes = 1 $$, '42501', null, 'quota not writable by users');
select lives_ok(format($$ select public.record_gemini_scan_usage(%L, 100, 2) $$, tests.org('Org A')), 'usage recorded');
select lives_ok(format($$ select public.record_gemini_scan_usage(%L, 50, 1) $$, tests.org('Org A')), 'usage aggregates');
select is((select gemini_tokens_used::int from public.workspace_usage), 150, 'tokens aggregated');
select is((select gemini_scans_count from public.workspace_usage), 2, 'scans counted');
select is((select gemini_credits_consumed from public.workspace_usage), 3, 'credits aggregated');
select throws_ok(format($$ select public.record_gemini_scan_usage(%L, -1, 0) $$, tests.org('Org A')),
    '22023', 'invalid_amount', 'negative usage rejected');
select throws_ok($$ insert into public.workspace_usage (organization_id, user_id, billing_period) values (null, null, 'x') $$,
    '42501', null, 'usage not writable directly');
select tests.as_user('carol');
select throws_ok(format($$ select public.record_gemini_scan_usage(%L, 1, 1) $$, tests.org('Org A')),
    '42501', 'not_member', 'outsider cannot record usage');
select tests.as_user('alice');
select is((select count(*)::int from public.workspace_usage), 1, 'admin sees organization usage');

-- leave_organization and user deletion ---------------------------------------------------------------------
select tests.as_user('carol');
select throws_ok(format($$ select public.leave_organization(%L) $$, tests.org('Org A')), '42501', 'not_member',
    'non-member cannot leave');
select tests.as_user('bob');
select lives_ok(format($$ select public.leave_organization(%L) $$, tests.org('Org A')), 'member leaves');
select tests.reset();
select is((select count(*)::int from public.band_members where member_id not in (select id from public.organization_members)), 0,
    'no orphan band memberships');
select is((select count(*)::int from public.event_assignments where event_id = 'evt-future'), 0,
    'leaving removes future assignments');
select tests.as_user('alice');
select lives_ok(format($$ select public.leave_organization(%L) $$, tests.org('Org A')), 'admin leaves while another admin exists');
select tests.as_user('eve');
select throws_ok(format($$ select public.leave_organization(%L) $$, tests.org('Org A')), 'P0001', 'last_admin',
    'remaining admin cannot leave');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role) values (tests.org('Org A'), tests.uid('alice'), 'admin');
select lives_ok(format($$ delete from auth.users where id = %L $$, tests.uid('eve')),
    'deleting an admin user is allowed when another admin exists');
select ok((select deactivated_at is not null from public.organization_members where id = tests.member('Org A', 'eve')),
    'deleted user''s membership is deactivated, not removed');
select is((select count(*)::int from public.organization_members where organization_id = tests.org('Org A')), 2,
    'the deactivated membership row is kept as history');
select lives_ok(format($$ delete from public.organizations where id = %L $$, tests.org('Org B')),
    'deleting an organization is not blocked by the last admin guard');

select * from finish();
rollback;
