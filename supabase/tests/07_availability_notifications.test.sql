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
-- Availability (absences, assignment responses) and notifications
-- Org A: alice + eve admins, bob + frank members. carol is an outsider.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','eve','frank']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role) values
    (tests.org('Org A'), tests.uid('eve'), 'admin'),
    (tests.org('Org A'), tests.uid('bob'), 'member'),
    (tests.org('Org A'), tests.uid('frank'), 'member');

-- Absences -------------------------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(format($$ insert into public.member_absences (id, organization_id, member_id, starts_on, ends_on, note)
    values ('00000000-0000-0000-0000-0000000000f1', %L, %L, '2030-05-10', '2030-05-12', 'Holiday') $$,
    tests.org('Org A'), tests.member('Org A', 'bob')), 'a member records their own absence');
select throws_ok(format($$ insert into public.member_absences (organization_id, member_id, starts_on, ends_on)
    values (%L, %L, '2030-05-12', '2030-05-10') $$, tests.org('Org A'), tests.member('Org A', 'bob')),
    '23514', null, 'ends_on must not precede starts_on');
select lives_ok(format($$ insert into public.member_absences (organization_id, member_id, starts_on, ends_on)
    values (%L, %L, '2030-06-01', '2030-06-01') $$, tests.org('Org A'), tests.member('Org A', 'bob')), 'a single day is fine');
select throws_ok(format($$ insert into public.member_absences (organization_id, member_id, starts_on, ends_on)
    values (%L, %L, '2030-05-10', '2030-05-12') $$, tests.org('Org A'), tests.member('Org A', 'frank')),
    '42501', null, 'cannot record an absence for someone else');
select is((select count(*)::int from public.member_absences), 2, 'bob reads his own absences');

select tests.as_user('frank');
select is((select count(*)::int from public.member_absences), 0, 'other members cannot read them');
select tests.as_user('carol');
select is((select count(*)::int from public.member_absences), 0, 'outsiders cannot');
select tests.as_user('alice');
select is((select count(*)::int from public.member_absences), 2, 'admins can read the absences of their organization');
select throws_ok(format($$ insert into public.member_absences (organization_id, member_id, starts_on, ends_on)
    values (%L, %L, '2030-07-01', '2030-07-02') $$, tests.org('Org A'), tests.member('Org A', 'bob')),
    '42501', null, 'but admins cannot write them');
update public.member_absences set note = 'admin edit';
delete from public.member_absences;
select tests.reset();
select is((select count(*)::int from public.member_absences where note = 'admin edit'), 0, 'admins cannot edit');
select is((select count(*)::int from public.member_absences), 2, 'nor delete');
select tests.as_user('bob');
select lives_ok($$ update public.member_absences set note = 'Back late' where id = '00000000-0000-0000-0000-0000000000f1' $$, 'owner edits');
select lives_ok($$ delete from public.member_absences where starts_on = '2030-06-01' $$, 'owner deletes');
select is((select count(*)::int from public.member_absences), 1, 'one left');

-- members_available_on -----------------------------------------------------------------------------
select tests.as_user('alice');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-09')), 4, 'everyone is available before the absence');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-10')), 3, 'start day is covered');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-11')), 3, 'middle day is covered');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-12')), 3, 'end day is covered');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-13')), 4, 'available again after');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-11') where username = 'bob'), 0, 'bob is the one missing');
select tests.as_user('frank');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-11')), 3, 'members can ask too, without seeing absence details');
select tests.as_user('carol');
select is((select count(*)::int from public.members_available_on(tests.org('Org A'), '2030-05-11')), 0, 'outsiders get nothing');

-- Assignment responses ----------------------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time)
    values ('evt-1', %1$L, 'Gig', now() + interval '3 days'), ('evt-2', %1$L, 'Rehearsal', now() + interval '4 days') $$,
    tests.org('Org A')), 'admin creates events');
select throws_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument, response)
    values (%L, 'evt-1', %L, 'bass', 'accepted') $$, tests.org('Org A'), tests.member('Org A', 'bob')),
    '42501', null, 'admins cannot pre-accept on behalf of a member');
select lives_ok(format($$ insert into public.event_assignments (id, organization_id, event_id, member_id, instrument)
    values ('00000000-0000-0000-0000-0000000000e1', %L, 'evt-1', %L, 'bass') $$,
    tests.org('Org A'), tests.member('Org A', 'bob')), 'admin assigns bob');
select is((select response from public.event_assignments), 'pending', 'assignments start pending');
select tests.reset();
select is(tests.notifs('bob', 'event_assigned'), 1, 'the assignee is notified');
select is((select payload ->> 'event_title' from public.notifications where type = 'event_assigned'), 'Gig', 'with the event title');

select tests.as_user('frank');
update public.event_assignments set response = 'accepted';
select tests.reset();
select is((select response from public.event_assignments), 'pending', 'another member cannot answer for bob');
select tests.as_user('alice');
select throws_ok($$ update public.event_assignments set response = 'accepted' $$, '42501', 'not_assignee',
    'an admin cannot answer for the assignee');
select tests.as_user('bob');
select throws_ok($$ update public.event_assignments set instrument = 'drums' $$, '42501', 'not_admin',
    'the assignee cannot change the assignment itself');
select throws_ok(format($$ update public.event_assignments set member_id = %L $$, tests.member('Org A', 'frank')),
    '42501', 'not_admin', 'nor hand it to someone else');
select throws_ok($$ update public.event_assignments set event_id = 'evt-2' $$, '42501', null, 'nor move it to another event');
select lives_ok($$ update public.event_assignments set response = 'accepted' $$, 'the assignee accepts');
select ok((select responded_at is not null from public.event_assignments), 'responded_at is stamped');
select tests.reset();
select is(tests.notifs('alice', 'assignment_declined'), 0, 'accepting notifies nobody');

select tests.as_user('bob');
select lives_ok($$ update public.event_assignments set response = 'declined', decline_reason = 'Sick' $$, 'the assignee declines with a reason');
select is((select decline_reason from public.event_assignments), 'Sick', 'reason stored');
select tests.reset();
select is(tests.notifs('alice', 'assignment_declined'), 1, 'admins are notified of a decline');
select is(tests.notifs('eve', 'assignment_declined'), 1, 'all admins');
select is(tests.notifs('bob', 'assignment_declined'), 0, 'not the decliner');
select is((select payload ->> 'reason' from public.notifications where type = 'assignment_declined' limit 1), 'Sick', 'payload carries the reason');

select tests.as_user('bob');
select lives_ok($$ update public.event_assignments set response = 'accepted' $$, 'bob changes his mind');
select is((select decline_reason from public.event_assignments), null, 'reason is cleared when no longer declined');

-- Reassigning resets the answer and notifies both people
select tests.as_user('alice');
select lives_ok(format($$ update public.event_assignments set member_id = %L $$, tests.member('Org A', 'frank')),
    'admin reassigns to frank');
select is((select response from public.event_assignments), 'pending', 'the answer resets');
select tests.reset();
select is(tests.notifs('bob', 'event_unassigned'), 1, 'the previous assignee is told');
select is(tests.notifs('frank', 'event_assigned'), 1, 'the new one is told');

-- Unassigning notifies; deleting the event does not
select tests.as_user('alice');
select lives_ok(format($$ delete from public.event_assignments where member_id = %L $$, tests.member('Org A', 'frank')), 'admin unassigns');
select tests.reset();
select is(tests.notifs('frank', 'event_unassigned'), 1, 'unassigned member is notified');
select tests.as_user('alice');
select lives_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    values (%L, 'evt-2', %L, 'keys') $$, tests.org('Org A'), tests.member('Org A', 'frank')), 'assign frank to evt-2');
select lives_ok($$ delete from public.calendar_events where id = 'evt-2' $$, 'the event is deleted');
select tests.reset();
select is(tests.notifs('frank', 'event_unassigned'), 1, 'no extra notification when the whole event is deleted');

-- Notifications ---------------------------------------------------------------------------------------------
-- Admin edits a member's musician fields
select tests.as_user('alice');
select lives_ok(format($$ update public.organization_members set notes = 'Plays 5-string', instruments = array['bass']
    where id = %L $$, tests.member('Org A', 'bob')), 'admin edits bob''s musician fields');
select tests.reset();
select is(tests.notifs('bob', 'member_profile_edited'), 1, 'bob is notified');
select is((select payload -> 'changed_fields' from public.notifications where type = 'member_profile_edited'),
    '["instruments", "notes"]'::jsonb, 'with the list of changed fields');
select tests.as_user('bob');
select lives_ok(format($$ update public.organization_members set notes = 'My own edit' where id = %L $$,
    tests.member('Org A', 'bob')), 'bob edits his own fields');
select tests.reset();
select is(tests.notifs('bob', 'member_profile_edited'), 1, 'self edits do not notify');

-- Role change
select tests.as_user('alice');
select public.set_member_role(tests.member('Org A', 'frank'), 'admin');
select tests.reset();
select is(tests.notifs('frank', 'role_changed'), 1, 'role change notifies the member');
select is((select payload ->> 'new_role' from public.notifications where type = 'role_changed'), 'admin', 'with the new role');

-- Privacy of notifications
select tests.as_user('alice');
select is((select count(*)::int from public.notifications where recipient_id = tests.uid('bob')), 0, 'others cannot read bob''s notifications');
select tests.as_user('carol');
select is((select count(*)::int from public.notifications), 0, 'outsiders read none');
select tests.as_anon();
select throws_ok($$ select * from public.notifications $$, '42501', null, 'anon cannot read notifications');
select tests.as_user('bob');
select cmp_ok((select count(*)::int from public.notifications), '>', 0, 'bob reads his own');
select is((select count(*)::int from public.notifications where recipient_id <> tests.uid('bob')), 0, 'and only his own');
select throws_ok(format($$ insert into public.notifications (recipient_id, type) values (%L, 'spam') $$, tests.uid('bob')),
    '42501', null, 'clients cannot create notifications');
select throws_ok($$ delete from public.notifications $$, '42501', null, 'nor delete them');
select throws_ok($$ update public.notifications set payload = '{}'::jsonb $$, '42501', null, 'nor change their content');
update public.notifications set read_at = now() where type = 'event_assigned';
select is((select count(*)::int from public.notifications where read_at is not null), 1, 'but can mark them read');
select tests.save('unread', (select count(*)::text from public.notifications where read_at is null));
select is(public.mark_notifications_read()::text, tests.get('unread'),
    'mark_notifications_read marks the rest and returns how many');
select is((select count(*)::int from public.notifications where read_at is null), 0, 'all read');
select tests.as_user('frank');
select is((select count(*)::int from public.notifications where read_at is not null), 0, 'marking read is per recipient');
update public.notifications set read_at = now() where recipient_id = tests.uid('bob');
select tests.reset();
select is((select count(*)::int from public.notifications where recipient_id = tests.uid('frank') and read_at is not null), 0,
    'one user cannot mark another''s notifications');

-- Assignments cannot target a deactivated member
select tests.create_user('gina');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role)
    values (tests.org('Org A'), tests.uid('gina'), 'member');
select tests.as_user('gina');
select lives_ok($$ select public.deactivate_account() $$, 'gina deactivates her account');
select tests.as_user('alice');
select throws_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    values (%L, 'evt-1', %L, 'keys') $$, tests.org('Org A'), tests.member('Org A', 'gina')),
    'P0001', 'member_deactivated', 'an event cannot be assigned to a deactivated member');
select lives_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    values (%L, 'evt-1', %L, 'keys') $$, tests.org('Org A'), tests.member('Org A', 'frank')), 'assign frank to evt-1');
select throws_ok(format($$ update public.event_assignments set member_id = %L where event_id = 'evt-1' $$,
    tests.member('Org A', 'gina')), 'P0001', 'member_deactivated', 'nor reassigned to one');

-- Removal keeps the member's shared versions, repertoire entries and setlist items
select tests.reset();
insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-0000000005a1', 'Bobs Song', 'x', tests.uid('bob'));
insert into public.song_versions (id, song_id, owner_id, label, visibility)
    values ('00000000-0000-0000-0000-0000000005b1', '00000000-0000-0000-0000-0000000005a1', tests.uid('bob'), 'Bob V', 'organizations');
insert into public.version_shares (version_id, organization_id)
    values ('00000000-0000-0000-0000-0000000005b1', tests.org('Org A'));
insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (tests.org('Org A'), '00000000-0000-0000-0000-0000000005b1', tests.uid('alice'));

-- Removal
select tests.as_user('alice');
select lives_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    select %1$L, 'evt-1', %2$L, 'bass' $$, tests.org('Org A'), tests.member('Org A', 'bob')), 'assign bob again');
select lives_ok(format($$ select public.remove_member(%L) $$, tests.member('Org A', 'bob')), 'admin removes bob');
select tests.reset();
select is(tests.notifs('bob', 'removed'), 1, 'the removed member is told');
select is(tests.notifs('bob', 'event_unassigned'), 1, 'removal clean-up is silent (only the earlier reassignment notification)');
select is((select count(*)::int from public.version_shares where version_id = '00000000-0000-0000-0000-0000000005b1'), 1,
    'removing the owner keeps the share of their version');
select is((select count(*)::int from public.organization_repertoire where version_id = '00000000-0000-0000-0000-0000000005b1'), 1,
    'and the repertoire entry');
select tests.as_user('bob');
select lives_ok($$ delete from public.version_shares where version_id = '00000000-0000-0000-0000-0000000005b1' $$,
    'the former member can still unshare');
select tests.reset();
select is((select count(*)::int from public.organization_repertoire where version_id = '00000000-0000-0000-0000-0000000005b1'), 0,
    'which then removes it from the repertoire');

-- Realtime
select ok(exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
                  and schemaname = 'public' and tablename = 'notifications'),
    'notifications are in the realtime publication');
select ok(exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
                  and schemaname = 'public' and tablename = 'event_assignments'),
    'event_assignments too');

select * from finish();
rollback;
