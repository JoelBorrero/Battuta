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
-- Deactivated accounts (Slack-style): history stays, access goes
-- Org A: alice + eve admins, bob member. Org C: carol sole admin/member.
-- Org D: dave admin + frank member. Org E: hank admin + ivy member.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','dave','eve','frank','hank','ivy','gina']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select tests.as_user('carol');
select public.create_organization('Org C');
select tests.as_user('dave');
select public.create_organization('Org D');
select tests.as_user('hank');
select public.create_organization('Org E');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role) values
    (tests.org('Org A'), tests.uid('eve'), 'admin'),
    (tests.org('Org A'), tests.uid('bob'), 'member'),
    (tests.org('Org D'), tests.uid('frank'), 'member'),
    (tests.org('Org E'), tests.uid('ivy'), 'member');
update public.profiles set avatar_url = 'https://example.test/bob.png' where username = 'bob';
insert into public.bands (id, organization_id, name) values
    ('00000000-0000-0000-0000-0000000000a1', tests.org('Org A'), 'Band A1');
insert into public.band_members (organization_id, band_id, member_id) values
    (tests.org('Org A'), tests.band('Band A1'), tests.member('Org A', 'bob'));
insert into public.calendar_events (id, organization_id, title, date_time, created_by) values
    ('evt-future', tests.org('Org A'), 'Future', now() + interval '2 days', tests.uid('alice')),
    ('evt-past', tests.org('Org A'), 'Past', now() - interval '2 days', tests.uid('alice'));
insert into public.event_assignments (organization_id, event_id, member_id, instrument) values
    (tests.org('Org A'), 'evt-future', tests.member('Org A', 'bob'), 'bass'),
    (tests.org('Org A'), 'evt-past', tests.member('Org A', 'bob'), 'bass');

-- bob authored a song version shared with Org A
insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-00000000f001', 'Bobs Song', 'Bob', tests.uid('bob'));
insert into public.song_versions (id, song_id, owner_id, label, visibility)
    values ('00000000-0000-0000-0000-00000000f101', '00000000-0000-0000-0000-00000000f001',
            tests.uid('bob'), 'Bob V', 'organizations');
insert into public.version_shares (version_id, organization_id)
    values ('00000000-0000-0000-0000-00000000f101', tests.org('Org A'));
insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (tests.org('Org A'), '00000000-0000-0000-0000-00000000f101', tests.uid('alice'));

-- A live invite link and a pending invitation for bob / by someone else
select tests.as_user('alice');
select tests.save('a_link', (public.create_invite_link(tests.org('Org A'))).id::text);
select tests.reset();
select tests.save('a_tok', (select token from public.invite_links where id = tests.get('a_link')::uuid));
select tests.as_user('dave');
select public.invite_user_by_username(tests.org('Org D'), 'gina');

-- Last admin rule ------------------------------------------------------------------------------
select tests.as_user('dave');
select throws_ok($$ select public.deactivate_account() $$, 'P0001', 'last_admin',
    'last admin of an organization with other active members cannot deactivate');
select tests.reset();
select ok((select deactivated_at is null from public.profiles where username = 'dave'), 'dave is unchanged');
select tests.as_anon();
select throws_ok($$ select public.deactivate_account() $$, '42501', null, 'anon cannot deactivate');

-- Deactivating a member --------------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok($$ select public.deactivate_account() $$, 'a member deactivates their account');
select tests.reset();
select ok((select deactivated_at is not null from public.profiles where username = 'bob'), 'profile is marked deactivated');
select is((select avatar_url from public.profiles where username = 'bob'), null, 'avatar is scrubbed');
select is((select display_name from public.profiles where username = 'bob'), 'bob', 'display name is kept for history');
select is((select count(*)::int from public.profiles where username = 'bob'), 1, 'username is kept');
select ok((select deactivated_at is not null from public.organization_members where id = tests.member('Org A', 'bob')),
    'membership is inactive, not deleted');
select is((select count(*)::int from public.band_members where member_id = tests.member('Org A', 'bob')), 0,
    'band memberships are removed');
select is((select count(*)::int from public.event_assignments where event_id = 'evt-future'), 0,
    'future assignments are removed');
select is((select count(*)::int from public.event_assignments
           where event_id = 'evt-past' and member_id = tests.member('Org A', 'bob')), 1,
    'past assignments stay, still pointing at the member');
select is((select count(*)::int from public.song_versions where owner_id = tests.uid('bob')), 1, 'authored versions stay');
select is((select count(*)::int from public.songs where created_by = tests.uid('bob')), 1, 'authored songs stay');
select is((select count(*)::int from public.organization_repertoire where version_id = '00000000-0000-0000-0000-00000000f101'), 1,
    'repertoire entries of the deactivated owner stay');
select is(tests.notifs('alice', 'event_unassigned'), 0, 'silent clean-up: no unassignment notification');

select tests.as_user('alice');
select is((select count(*)::int from public.song_versions where id = '00000000-0000-0000-0000-00000000f101'), 1,
    'shared version keeps its visibility for the organization');
select is((select deactivated_at is not null from public.organization_members where id = tests.member('Org A', 'bob')), true,
    'the roster shows the member as deactivated');
select is((select deactivated_at is not null from public.profiles where username = 'bob'), true,
    'co-members can still see the tombstone profile');

-- Gone from search, invites and joins -----------------------------------------------------------------
select is((select count(*)::int from public.search_profiles('bob')), 0, 'deactivated users disappear from search');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'bob') $$, tests.org('Org A')),
    'P0002', 'user_not_found', 'deactivated users cannot be invited');
select tests.as_user('bob');
select throws_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('a_tok')),
    'P0001', 'account_deactivated', 'a deactivated user cannot rejoin through a link');
select throws_ok($$ select public.create_organization('Zombie') $$, 'P0001', 'account_deactivated',
    'nor create organizations');
select throws_ok($$ select public.deactivate_account() $$, 'P0001', 'account_deactivated', 'deactivating twice reports it');
select is((select count(*)::int from public.organizations), 0, 'organization data is no longer visible to them');
select is((select count(*)::int from public.organization_members), 0, 'nor the roster');
update public.song_versions set label = 'Zombie edit' where id = '00000000-0000-0000-0000-00000000f101';
update public.profiles set display_name = 'Zombie' where username = 'bob';
select tests.reset();
select is((select label from public.song_versions where id = '00000000-0000-0000-0000-00000000f101'), 'Bob V',
    'a deactivated owner cannot edit their versions');
select is((select display_name from public.profiles where username = 'bob'), 'bob', 'nor their profile');

-- Pending invitations to the user are cancelled
select tests.as_user('dave');
select public.invite_user_by_username(tests.org('Org D'), 'ivy');
select tests.as_user('ivy');
select public.deactivate_account();
select tests.reset();
select is((select status from public.invitations where invited_user_id = tests.uid('ivy')), 'cancelled',
    'pending invitations to a deactivated user are cancelled');

-- Sole member archives the organization ------------------------------------------------------------------
select tests.as_user('carol');
select lives_ok($$ select public.deactivate_account() $$, 'the only member can deactivate');
select tests.reset();
select ok((select archived_at is not null from public.organizations where id = tests.org('Org C')),
    'their organization is archived');
select ok((select deactivated_at is not null from public.organization_members where id = tests.member('Org C', 'carol')),
    'their membership is inactive');

-- A last admin can leave the problem to others: promote, then deactivate ------------------------------------
select tests.as_user('dave');
select public.set_member_role(tests.member('Org D', 'frank'), 'admin');
select lives_ok($$ select public.deactivate_account() $$, 'after promoting someone else the admin can deactivate');
select tests.reset();
select ok((select archived_at is null from public.organizations where id = tests.org('Org D')), 'organization stays active');
select is((select count(*)::int from public.organization_members
           where organization_id = tests.org('Org D') and deactivated_at is null and role = 'admin'), 1,
    'one active admin remains');

-- Deleting the auth.users row never deletes profiles or content ---------------------------------------------
select tests.reset();
select lives_ok(format($$ delete from auth.users where id = %L $$, tests.uid('alice')),
    'deleting an admin''s auth user works while another admin exists');
select is((select count(*)::int from public.profiles where username = 'alice'), 1, 'profile stays');
select ok((select deactivated_at is not null from public.profiles where username = 'alice'), 'as a deactivated tombstone');
select is((select count(*)::int from public.calendar_events where created_by = tests.uid('alice')), 2,
    'content they created stays');
select is((select count(*)::int from auth.users where id = tests.uid('alice')), 0, 'the auth row is gone');

-- Admin with remaining active members cannot be deleted either
select tests.as_user('hank');
select public.invite_user_by_username(tests.org('Org E'), 'gina');
select tests.as_user('gina');
select public.respond_to_invitation((select id from public.invitations where invited_user_id = tests.uid('gina')
    and organization_id = tests.org('Org E')), true);
select tests.reset();
select throws_ok(format($$ delete from auth.users where id = %L $$, tests.uid('hank')),
    'P0001', 'last_admin', 'deleting the last admin''s auth user is blocked while others remain');
select is((select count(*)::int from public.profiles where username = 'hank' and deactivated_at is null), 1,
    'and nothing changed');

-- Deleting the only member's auth user archives the organization instead
select lives_ok(format($$ delete from auth.users where id = %L $$, tests.uid('eve')),
    'eve (admin of Org A with bob deactivated, alice deleted) can be deleted: nobody else is active');
select ok((select archived_at is not null from public.organizations where id = tests.org('Org A')),
    'Org A was archived as its last active member left');

select * from finish();
rollback;
