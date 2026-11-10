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
-- Archiving organizations: every current admin must approve; archived = read-only
-- Org X: alice + eve admins, bob + frank members. Org Z: alice, eve, gina admins.
-- Org D: dave sole admin and sole member. carol is an outsider.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','dave','eve','frank','gina']) as u;

select tests.as_user('alice');
select public.create_organization('Org X');
select public.create_organization('Org Z');
select tests.as_user('dave');
select public.create_organization('Org D');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role) values
    (tests.org('Org X'), tests.uid('eve'), 'admin'),
    (tests.org('Org X'), tests.uid('bob'), 'member'),
    (tests.org('Org X'), tests.uid('frank'), 'member'),
    (tests.org('Org Z'), tests.uid('eve'), 'admin'),
    (tests.org('Org Z'), tests.uid('gina'), 'admin');
insert into public.bands (id, organization_id, name) values
    ('00000000-0000-0000-0000-0000000000c1', tests.org('Org X'), 'Band X1');
insert into public.calendar_events (id, organization_id, title, date_time)
    values ('evt-x', tests.org('Org X'), 'Gig', now() + interval '3 days');

-- Who can request ---------------------------------------------------------------------
select tests.as_user('bob');
select throws_ok(format($$ select public.request_organization_archive(%L) $$, tests.org('Org X')),
    '42501', 'not_admin', 'member cannot request an archive');
select tests.as_user('carol');
select throws_ok(format($$ select public.request_organization_archive(%L) $$, tests.org('Org X')),
    '42501', 'not_admin', 'outsider cannot request an archive');
select throws_ok(format($$ select public.approve_organization_archive(%L) $$, tests.org('Org X')),
    '42501', 'not_admin', 'outsider cannot approve');
select tests.as_anon();
select throws_ok(format($$ select public.request_organization_archive(%L) $$, tests.org('Org X')),
    '42501', null, 'anon cannot request an archive');

-- Request needs every admin ----------------------------------------------------------------
select tests.as_user('alice');
select throws_ok(format($$ select public.approve_organization_archive(%L) $$, tests.org('Org X')),
    'P0001', 'archive_not_requested', 'cannot approve without a request');
select throws_ok(format($$ select public.cancel_organization_archive(%L) $$, tests.org('Org X')),
    'P0001', 'archive_not_requested', 'cannot cancel without a request');
select ok((select archived_at is null from public.request_organization_archive(tests.org('Org X'))),
    'one of two admins approving does not archive');
select throws_ok(format($$ select public.request_organization_archive(%L) $$, tests.org('Org X')),
    'P0001', 'archive_already_requested', 'only one open request at a time');
select is((select count(*)::int from public.organization_archive_approvals), 1, 'the requester counts as approved');
select tests.reset();
select is(tests.notifs('eve', 'archive_requested'), 1, 'other admins are notified of the request');
select is(tests.notifs('alice', 'archive_requested'), 0, 'the requester is not');
select is(tests.notifs('bob', 'archive_requested'), 0, 'plain members are not');

select tests.as_user('bob');
select is((select count(*)::int from public.organization_archive_requests), 1, 'members can see an open request');
select tests.as_user('carol');
select is((select count(*)::int from public.organization_archive_requests), 0, 'outsiders cannot');
select tests.as_user('bob');
select throws_ok(format($$ select public.cancel_organization_archive(%L) $$, tests.org('Org X')),
    '42501', 'not_admin', 'member cannot cancel');

-- Any admin can cancel -------------------------------------------------------------------------
select tests.as_user('eve');
select lives_ok(format($$ select public.cancel_organization_archive(%L) $$, tests.org('Org X')), 'another admin cancels');
select tests.reset();
select is((select count(*)::int from public.organization_archive_requests), 0, 'request is gone');
select is((select count(*)::int from public.organization_archive_approvals), 0, 'approvals are gone');
select is(tests.notifs('alice', 'archive_cancelled'), 1, 'the other admins are told it was cancelled');
select ok((select archived_at is null from public.organizations where id = tests.org('Org X')), 'still active');

-- An admin added while the request is open must approve too ---------------------------------------------
select tests.as_user('alice');
select public.request_organization_archive(tests.org('Org X'));
select public.set_member_role(tests.member('Org X', 'frank'), 'admin');
select tests.as_user('eve');
select ok((select archived_at is null from public.approve_organization_archive(tests.org('Org X'))),
    'eve approves but the new admin has not');
select lives_ok(format($$ select public.approve_organization_archive(%L) $$, tests.org('Org X')), 'approving twice is harmless');
select tests.as_user('frank');
select ok((select archived_at is not null from public.approve_organization_archive(tests.org('Org X'))),
    'the last current admin approves: archived');

-- Pending items at archive time ---------------------------------------------------------------------------
select tests.reset();
select is(tests.notifs('bob', 'archive_completed'), 1, 'every member is told');
select is(tests.notifs('alice', 'archive_completed'), 1, 'admins too');
select is((select count(*)::int from public.organization_archive_requests), 0, 'request closed');

-- Read-only for everyone ---------------------------------------------------------------------------------
select tests.as_user('alice');
select throws_ok(format($$ insert into public.bands (organization_id, name) values (%L, 'New') $$, tests.org('Org X')),
    '42501', null, 'admin cannot create bands in an archived organization');
select throws_ok(format($$ insert into public.calendar_events (id, organization_id, title, date_time)
    values ('evt-new', %L, 'x', now()) $$, tests.org('Org X')), '42501', null, 'nor events');
select throws_ok(format($$ insert into public.setlists (id, organization_id, title) values ('s-new', %L, 'x') $$, tests.org('Org X')),
    '42501', null, 'nor setlists');
select throws_ok(format($$ insert into public.event_assignments (organization_id, event_id, member_id, instrument)
    values (%L, 'evt-x', %L, 'keys') $$, tests.org('Org X'), tests.member('Org X', 'bob')), '42501', null, 'nor assignments');
update public.organizations set name = 'Renamed' where id = tests.org('Org X');
select is((select name from public.organizations where id = tests.org('Org X')), 'Org X', 'cannot rename');
select throws_ok(format($$ select public.create_invite_link(%L) $$, tests.org('Org X')),
    'P0001', 'organization_archived', 'no invite links');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'carol') $$, tests.org('Org X')),
    'P0001', 'organization_archived', 'no invitations');
select throws_ok(format($$ select public.set_member_role(%L, 'member') $$, tests.member('Org X', 'bob')),
    'P0001', 'organization_archived', 'no role changes');
select throws_ok(format($$ select public.remove_member(%L) $$, tests.member('Org X', 'bob')),
    'P0001', 'organization_archived', 'no removals');
select throws_ok(format($$ select public.request_organization_archive(%L) $$, tests.org('Org X')),
    'P0001', 'organization_archived', 'cannot archive twice');
select tests.as_user('bob');
update public.organization_members set notes = 'edit' where id = tests.member('Org X', 'bob');
select is((select notes from public.organization_members where id = tests.member('Org X', 'bob')), null,
    'members cannot edit their own profile in an archived organization');
select throws_ok(format($$ select public.record_gemini_scan_usage(%L, 1, 1) $$, tests.org('Org X')),
    'P0001', 'organization_archived', 'no usage metering');
select throws_ok(format($$ insert into public.member_absences (organization_id, member_id, starts_on, ends_on)
    values (%L, %L, current_date, current_date) $$, tests.org('Org X'), tests.member('Org X', 'bob')),
    '42501', null, 'no absences either');

-- History stays readable ------------------------------------------------------------------------------------
select is((select count(*)::int from public.bands), 1, 'members still read bands');
select is((select count(*)::int from public.organizations), 1, 'and the organization');
select is((select count(*)::int from public.calendar_events), 1, 'and events');
select is((select count(*)::int from public.organization_members), 4, 'and the roster');

-- Lists and joins -------------------------------------------------------------------------------------------
select is((select count(*)::int from public.my_organizations()), 0, 'archived organization is hidden from my_organizations');
select is((select count(*)::int from public.my_organizations(true)), 1, 'unless asked for');
select tests.as_user('carol');
select is((select count(*)::int from public.my_organizations(true)), 0, 'outsiders list nothing');

-- Links and invitations created before the archive no longer work
select tests.as_user('eve');
select tests.save('z_link', (public.create_invite_link(tests.org('Org Z'))).id::text);
select tests.reset();
select tests.save('z_tok', (select token from public.invite_links where id = tests.get('z_link')::uuid));
select tests.as_user('gina');
select tests.save('z_inv', (public.invite_user_by_username(tests.org('Org Z'), 'carol')).id::text);

-- Removing an admin completes a pending request ---------------------------------------------------------------
select tests.as_user('alice');
select public.request_organization_archive(tests.org('Org Z'));
select tests.as_user('eve');
select public.approve_organization_archive(tests.org('Org Z'));
select ok((select archived_at is null from public.organizations where id = tests.org('Org Z')), 'gina has not approved yet');
select tests.as_user('alice');
select lives_ok(format($$ select public.remove_member(%L) $$, tests.member('Org Z', 'gina')), 'the missing admin is removed');
select tests.reset();
select ok((select archived_at is not null from public.organizations where id = tests.org('Org Z')),
    'request completes once every remaining admin has approved');
select is((select status from public.invitations where id = tests.get('z_inv')::uuid), 'cancelled',
    'pending invitations are cancelled on archive');
select ok((select revoked_at is not null from public.invite_links where id = tests.get('z_link')::uuid),
    'invite links are revoked on archive');
select tests.as_user('carol');
select throws_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('z_tok')),
    'P0001', 'organization_archived', 'joining an archived organization fails');
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('z_inv')),
    'P0001', 'invitation_not_pending', 'cannot accept a cancelled invitation');

-- Members can still leave an archived organization
select tests.as_user('bob');
select lives_ok(format($$ select public.leave_organization(%L) $$, tests.org('Org X')), 'a member may leave an archived organization');

-- Sole admin and sole member: own approval archives immediately ---------------------------------------------------
select tests.as_user('dave');
select ok((select archived_at is not null from public.request_organization_archive(tests.org('Org D'))),
    'the only admin who is the only member archives at once');
select is((select count(*)::int from public.my_organizations()), 0, 'and it leaves their list');

select * from finish();
rollback;
