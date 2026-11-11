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

-- ============================================================================
-- Calendar details: event type, setlist and series links, materialized occurrences
-- Org A: alice admin, bob member. Org B: dave admin. carol is an outsider.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','dave']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select tests.as_user('dave');
select public.create_organization('Org B');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role) values
    (tests.org('Org A'), tests.uid('bob'), 'member');
insert into public.setlists (id, organization_id, title) values
    ('set-a', tests.org('Org A'), 'Sunday set'),
    ('set-b', tests.org('Org B'), 'Other org set');

-- Defaults and columns -------------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.recurring_schedules (id, organization_id, title, event_type, time_of_day, location)
    values ('rec-a', %L, 'Sunday worship', 'sundayService', '10:30', 'Main hall') $$, tests.org('Org A')),
    'admin creates a schedule with a time, place and type');
select lives_ok(format($$ insert into public.recurring_schedules (id, organization_id, title) values ('rec-default', %L, 'Defaults') $$,
    tests.org('Org A')), 'a schedule can omit the new columns');
select is((select time_of_day::text from public.recurring_schedules where id = 'rec-default'), '09:00:00', 'time_of_day defaults to 09:00');
select is((select event_type from public.recurring_schedules where id = 'rec-default'), 'sundayService', 'schedule event_type defaults to sundayService');
select throws_ok(format($$ insert into public.recurring_schedules (id, organization_id, title, event_type) values ('rec-bad', %L, 'x', 'party') $$,
    tests.org('Org A')), '23514', null, 'unknown schedule event types are rejected');

select lives_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time) values ('evt-plain', %L, 'Plain', now() + interval '3 days') $$,
    tests.org('Org A')), 'an event can omit the new columns');
select is((select event_type from public.calendar_events where id = 'evt-plain'), 'sundayService', 'event_type defaults to sundayService');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, event_type) values ('evt-bad', %L, 'x', now(), 'party') $$,
    tests.org('Org A')), '23514', null, 'unknown event types are rejected');

-- Setlist link -------------------------------------------------------------------------------------
select lives_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, event_type, setlist_id)
    values ('evt-set', %L, 'With setlist', now() + interval '4 days', 'rehearsal', 'set-a') $$, tests.org('Org A')),
    'an event links a setlist of its organization');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, setlist_id)
    values ('evt-foreign-set', %L, 'x', now(), 'set-b') $$, tests.org('Org A')),
    '23503', null, 'a setlist of another organization cannot be linked');
select throws_ok($$ update public.calendar_events set setlist_id = 'set-b' where id = 'evt-set' $$,
    '23503', null, 'nor can an existing link be moved to it');

-- Series link and occurrences ----------------------------------------------------------------------
select lives_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id, occurrence_date)
    values ('evt-occ-1', %L, 'Sunday worship', now() + interval '5 days', 'rec-a', '2030-05-12') $$, tests.org('Org A')),
    'an occurrence is materialized');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id, occurrence_date)
    values ('evt-occ-dup', %L, 'Sunday worship', now() + interval '5 days', 'rec-a', '2030-05-12') $$, tests.org('Org A')),
    '23505', null, 'the same occurrence cannot be materialized twice');
select lives_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id, occurrence_date)
    values ('evt-occ-2', %L, 'Sunday worship', now() + interval '12 days', 'rec-a', '2030-05-19') $$, tests.org('Org A')),
    'another day of the same series is fine');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id)
    values ('evt-no-date', %L, 'x', now(), 'rec-a') $$, tests.org('Org A')),
    '23514', null, 'an event of a series needs its occurrence date');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id, occurrence_date)
    values ('evt-ghost', %L, 'x', now(), 'rec-missing', '2030-05-12') $$, tests.org('Org A')),
    '23503', null, 'the series must exist');

select tests.as_user('dave');
select lives_ok(format($$ insert into public.recurring_schedules (id, organization_id, title) values ('rec-b', %L, 'Org B series') $$,
    tests.org('Org B')), 'another organization has its own schedule');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id, occurrence_date)
    values ('evt-cross', %L, 'x', now(), 'rec-a', '2030-06-02') $$, tests.org('Org B')),
    '23503', null, 'a series of another organization cannot be linked');

-- Permissions ----------------------------------------------------------------------------------------
select tests.as_user('bob');
select is((select count(*)::int from public.calendar_events), 4, 'members read the events');
select is((select count(*)::int from public.recurring_schedules), 2, 'and the schedules');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, event_type, setlist_id)
    values ('evt-member', %L, 'x', now(), 'rehearsal', 'set-a') $$, tests.org('Org A')),
    '42501', null, 'a member cannot create events');
select throws_ok(format($$ insert into public.recurring_schedules (id, organization_id, title, time_of_day) values ('rec-member', %L, 'x', '08:00') $$,
    tests.org('Org A')), '42501', null, 'a member cannot create schedules');
update public.calendar_events set setlist_id = null, title = 'Hacked' where id = 'evt-set';
update public.recurring_schedules set location = 'Hacked' where id = 'rec-a';
delete from public.calendar_events where id = 'evt-occ-1';
select tests.reset();
select is((select setlist_id from public.calendar_events where id = 'evt-set'), 'set-a', 'a member cannot unlink a setlist');
select is((select title from public.calendar_events where id = 'evt-set'), 'With setlist', 'a member cannot edit an event');
select is((select location from public.recurring_schedules where id = 'rec-a'), 'Main hall', 'a member cannot edit a schedule');
select is((select count(*)::int from public.calendar_events where id = 'evt-occ-1'), 1, 'a member cannot delete an occurrence');

select tests.as_user('carol');
select is((select count(*)::int from public.calendar_events), 0, 'outsiders read no events');
select is((select count(*)::int from public.recurring_schedules), 0, 'nor schedules');

select tests.as_user('dave');
select is((select count(*)::int from public.calendar_events), 0, 'the other organization admin reads no events of Org A');
update public.calendar_events set title = 'Hacked' where id = 'evt-set';
select tests.reset();
select is((select title from public.calendar_events where id = 'evt-set'), 'With setlist', 'and cannot edit them');

-- Deleting what an event points to ------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok($$ delete from public.setlists where id = 'set-a' $$, 'an admin deletes a linked setlist');
select is((select setlist_id from public.calendar_events where id = 'evt-set'), null, 'the event stays and is unlinked');
select lives_ok($$ delete from public.recurring_schedules where id = 'rec-a' $$, 'an admin deletes a schedule');
select is((select count(*)::int from public.calendar_events where id in ('evt-occ-1', 'evt-occ-2')), 2, 'its materialized occurrences stay');
select is((select count(*)::int from public.calendar_events where id in ('evt-occ-1', 'evt-occ-2') and series_id is null and occurrence_date is not null), 2,
    'unlinked from the series, keeping their date');
select lives_ok(format($$ insert into public.recurring_schedules (id, organization_id, title) values ('rec-a', %L, 'Recreated') $$, tests.org('Org A')),
    'a schedule id can be created again');
select lives_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time, series_id, occurrence_date)
    values ('evt-occ-3', %L, 'x', now() + interval '5 days', 'rec-a', '2030-05-12') $$, tests.org('Org A')),
    'and the old unlinked occurrences do not block it');

select * from finish();
rollback;
