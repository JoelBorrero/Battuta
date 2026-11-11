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
-- Schema shape, profiles, sign-up trigger, search, anonymous access
-- ============================================================================

select has_table('public', t, t || ' exists')
from unnest(array['profiles','organizations','organization_members','bands','band_members',
    'invite_links','invitations','songs','song_versions','version_shares','scores','sections',
    'measures','note_events','chord_symbols','organization_repertoire',
    'setlists','setlist_items','calendar_events','recurring_schedules','event_assignments',
    'member_absences','notifications','organization_archive_requests',
    'organization_archive_approvals','workspace_quotas','workspace_usage']) as t;

select hasnt_table('public', t, t || ' was dropped')
from unnest(array['teams','team_members','team_groups']) as t;

select is((select count(*)::int from information_schema.columns
           where table_schema = 'public' and column_name in ('is_demo', 'team_id')),
          0, 'no is_demo or team_id columns remain');
select hasnt_column('public', 'profiles', 'email', 'profiles never stores email');

select is((select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
           where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
          0, 'RLS is enabled on every public table');

select is((select count(*)::int from pg_policies
           where schemaname = 'public' and roles::text like '%public%'),
          0, 'no policy is granted to the public pseudo-role');
select is((select array_agg(tablename::text order by tablename) from pg_policies
           where schemaname = 'public' and roles::text like '%anon%'),
          array['chord_symbols','measures','note_events','scores','sections','song_versions','songs'],
          'anon policies exist only on the song content tables (public versions)');
select hasnt_column('public', 'organization_members', 'availability', 'free-text availability was dropped');

-- Sign-up trigger -------------------------------------------------------------
select tests.create_user('Alice_Smith', '  Alice Smith ');
select is((select username from public.profiles where id = (select id from auth.users where email = 'Alice_Smith@example.test')),
          'alice_smith', 'username is stored lowercase');
select is((select display_name from public.profiles where username = 'alice_smith'),
          'Alice Smith', 'display name is trimmed');

select tests.create_user('bob');
select is((select display_name from public.profiles where username = 'bob'),
          'bob', 'display name defaults to the username');

select throws_ok($$ select tests.create_user('ALICE_SMITH') $$, '23505', 'username_taken',
                 'duplicate username (case-insensitive) is rejected with a clear error');
select throws_ok($$ select tests.create_user('ab') $$, '22023', 'invalid_username', 'too short');
select throws_ok($$ select tests.create_user('bad name') $$, '22023', 'invalid_username', 'space');
select throws_ok($$ select tests.create_user('bad-name') $$, '22023', 'invalid_username', 'dash');
select throws_ok($$ select tests.create_user(repeat('a', 31)) $$, '22023', 'invalid_username', 'too long');
select throws_ok($$ insert into auth.users (id, email) values (gen_random_uuid(), 'nometa@example.test') $$,
                 '22023', 'invalid_username', 'sign-up without a username is rejected');

select tests.create_user('carol');
select tests.create_user('dave', 'Dave The Drummer');

-- is_username_available (usable before sign-up) -------------------------------
select tests.as_anon();
select is(public.is_username_available('free_name'), true, 'free username is available (anon)');
select is(public.is_username_available('  BOB '), false, 'taken username (any case) is not available');
select is(public.is_username_available('x'), false, 'invalid username is not available');

-- Anonymous access --------------------------------------------------------------
select throws_ok($$ select * from public.profiles $$, '42501', null, 'anon cannot read profiles');
select throws_ok($$ select * from public.organizations $$, '42501', null, 'anon cannot read organizations');
select is((select count(*)::int from public.songs), 0, 'anon reads no songs when nothing is public');
select throws_ok($$ select * from public.invite_links $$, '42501', null, 'anon cannot read invite links');
select throws_ok($$ select public.create_organization('Nope') $$, '42501', null, 'anon cannot create organizations');
select throws_ok($$ select public.join_with_invite_link('x') $$, '42501', null, 'anon cannot join');
select throws_ok($$ select * from public.search_profiles('bob') $$, '42501', null, 'anon cannot search profiles');

-- Profile visibility and updates ------------------------------------------------
select tests.as_user('alice_smith');
select is((select count(*)::int from public.profiles), 1, 'a user with no shared organization sees only themself');
select lives_ok($$ update public.profiles set display_name = 'Alice S' where username = 'alice_smith' $$,
                'user can update own display name');
select throws_ok($$ update public.profiles set username = 'x' where username = 'alice_smith' $$,
                 '23514', null, 'username format is enforced on update');
select throws_ok($$ update public.profiles set username = 'BOB' where username = 'alice_smith' $$,
                 '23505', null, 'username uniqueness is enforced on update');
update public.profiles set display_name = 'Hacked' where username = 'bob';
select throws_ok($$ update public.profiles set id = gen_random_uuid() where username = 'alice_smith' $$,
                 '42501', null, 'profile id cannot be changed');

select tests.reset();
select is((select display_name from public.profiles where username = 'bob'), 'bob',
          'a user cannot edit someone else''s profile');
select is((select display_name from public.profiles where username = 'alice_smith'), 'Alice S',
          'own profile update persisted');

-- search_profiles -----------------------------------------------------------------
select tests.as_user('alice_smith');
select is((select count(*)::int from public.search_profiles('bo')), 0, 'queries under 3 characters return nothing');
select is((select username from public.search_profiles('bob')), 'bob', 'search by username prefix');
select is((select username from public.search_profiles('DRUMMER')), 'dave', 'search by display name, case-insensitive');
select is((select count(*)::int from public.search_profiles('alice')), 0, 'search excludes the caller');
select is((select count(*)::int from public.search_profiles('%%%')), 0, 'LIKE wildcards are escaped (%)');
select is((select count(*)::int from public.search_profiles('___')), 0, 'LIKE wildcards are escaped (_)');
select is((select count(*)::int from information_schema.columns
           where table_schema = 'public' and table_name = 'profiles' and column_name like '%mail%'),
          0, 'search result source has no email column');

-- Deleting a user keeps the profile as a deactivated tombstone ---------------------------
select tests.reset();
select lives_ok($$ delete from auth.users where email = 'carol@example.test' $$, 'user can be deleted');
select is((select count(*)::int from public.profiles where username = 'carol'), 1, 'profile survives the auth user');
select ok((select deactivated_at is not null from public.profiles where username = 'carol'), 'and is marked deactivated');
select tests.as_user('alice_smith');
select is((select count(*)::int from public.search_profiles('carol')), 0, 'deactivated users are not searchable');
select is(public.is_username_available('carol'), false, 'deactivated usernames stay reserved');

select * from finish();
rollback;
