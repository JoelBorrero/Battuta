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
-- Invite links (token / QR) and invitations by username
-- alice admin + bob member of Org A; dave admin of Org B; the rest are outsiders.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','dave','eve','frank','gina','hank','ivy','jan','kim']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select tests.as_user('dave');
select public.create_organization('Org B');
select tests.reset();
insert into public.organization_members (organization_id, user_id) values (tests.org('Org A'), tests.uid('bob'));
insert into public.bands (id, organization_id, name) values
    ('00000000-0000-0000-0000-0000000000a1', tests.org('Org A'), 'Band A1'),
    ('00000000-0000-0000-0000-0000000000b1', tests.org('Org B'), 'Band B1');

-- create_invite_link ---------------------------------------------------------------
select tests.as_user('bob');
select throws_ok(format($$ select public.create_invite_link(%L) $$, tests.org('Org A')),
    '42501', 'not_admin', 'member cannot create an invite link');
select tests.as_user('carol');
select throws_ok(format($$ select public.create_invite_link(%L) $$, tests.org('Org A')),
    '42501', 'not_admin', 'outsider cannot create an invite link');
select tests.as_anon();
select throws_ok(format($$ select public.create_invite_link(%L) $$, tests.org('Org A')),
    '42501', null, 'anon cannot create an invite link');

select tests.as_user('alice');
select tests.save('plain_id', (public.create_invite_link(tests.org('Org A'))).id::text);
select tests.save('plain', (select token from public.invite_links where id = tests.get('plain_id')::uuid));
select is(length(tests.get('plain')), 64, 'token is long and random');
select ok((select expires_at > now() + interval '6 days' and expires_at < now() + interval '8 days'
           from public.invite_links where id = tests.get('plain_id')::uuid), 'default expiry is 7 days');
select is((select use_count from public.invite_links where id = tests.get('plain_id')::uuid), 0, 'use_count starts at 0');
select isnt((select token from public.create_invite_link(tests.org('Org A'))), tests.get('plain'), 'tokens are unique');
select throws_ok(format($$ select public.create_invite_link(%L, null, interval '0') $$, tests.org('Org A')),
    '22023', 'invalid_expiry', 'zero expiry rejected');
select throws_ok(format($$ select public.create_invite_link(%L, null, interval '-1 day') $$, tests.org('Org A')),
    '22023', 'invalid_expiry', 'negative expiry rejected');
select throws_ok(format($$ select public.create_invite_link(%L, null, interval '1 day', 0) $$, tests.org('Org A')),
    '22023', 'invalid_max_uses', 'max_uses < 1 rejected');
select throws_ok(format($$ select public.create_invite_link(%L, %L) $$, tests.org('Org A'), tests.band('Band B1')),
    'P0001', 'band_not_in_organization', 'band from another organization rejected');
select tests.save('band_id', (public.create_invite_link(tests.org('Org A'), tests.band('Band A1'))).id::text);
select tests.save('band', (select token from public.invite_links where id = tests.get('band_id')::uuid));

select is((select count(*)::int from public.invite_links), 3, 'admin reads invite links');
select tests.as_user('bob');
select is((select count(*)::int from public.invite_links), 0, 'members cannot read invite links (tokens stay secret)');
select throws_ok(format($$ insert into public.invite_links (organization_id, expires_at) values (%L, now() + interval '1 day') $$,
    tests.org('Org A')), '42501', null, 'invite links cannot be inserted directly');
select tests.as_user('alice');
select throws_ok(format($$ insert into public.invite_links (organization_id, expires_at) values (%L, now() + interval '1 day') $$,
    tests.org('Org A')), '42501', null, 'not even by admins');
select throws_ok(format($$ update public.invite_links set max_uses = 99 where id = %L $$, tests.get('plain_id')),
    '42501', null, 'invite links cannot be updated directly');

-- join_with_invite_link --------------------------------------------------------------------
select tests.as_user('carol');
select is((select role from public.join_with_invite_link(tests.get('plain'))), 'member', 'join returns a plain member');
select is((select count(*)::int from public.organization_members where user_id = tests.uid('carol')), 1, 'membership created');
select is((select organization_id from public.organization_members where user_id = tests.uid('carol')),
    tests.org('Org A'), 'joined the right organization');
select is((select count(*)::int from public.organizations), 1, 'new member can read the organization');
select tests.reset();
select is((select use_count from public.invite_links where id = tests.get('plain_id')::uuid), 1, 'use_count incremented');

select tests.as_user('carol');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('plain')), 'joining twice succeeds');
select tests.reset();
select is((select count(*)::int from public.organization_members where user_id = tests.uid('carol')), 1, 'no duplicate membership row');
select is((select use_count from public.invite_links where id = tests.get('plain_id')::uuid), 1, 'existing member does not consume a use');

-- Link with a band: new member joins the band; existing member gets added to it too.
select tests.as_user('eve');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('band')), 'join with a band link');
select tests.reset();
select is((select count(*)::int from public.band_members where member_id = tests.member('Org A', 'eve')
           and band_id = tests.band('Band A1')), 1, 'new member joined the band');
select tests.as_user('carol');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('band')), 'existing member uses a band link');
select tests.reset();
select is((select count(*)::int from public.organization_members where user_id = tests.uid('carol')), 1, 'still one membership row');
select is((select count(*)::int from public.band_members where member_id = tests.member('Org A', 'carol')), 1,
    'existing member was added to the band');
select tests.as_user('bob');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('band')), 'bob uses the band link');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('band')), 'and again (idempotent band add)');
select tests.reset();
select is((select count(*)::int from public.band_members where member_id = tests.member('Org A', 'bob')), 1, 'band membership not duplicated');

-- Errors ---------------------------------------------------------------------------------------
select tests.as_user('frank');
select throws_ok($$ select public.join_with_invite_link('not-a-real-token') $$, 'P0002', 'invite_not_found', 'unknown token');
select throws_ok($$ select public.join_with_invite_link(null) $$, 'P0002', 'invite_not_found', 'null token');
select tests.as_anon();
select throws_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('plain')), '42501', null, 'anon cannot join');

-- Revoke
select tests.as_user('bob');
select throws_ok(format($$ select public.revoke_invite_link(%L) $$, tests.get('plain_id')), '42501', 'not_admin',
    'member cannot revoke');
select tests.as_user('dave');
select throws_ok(format($$ select public.revoke_invite_link(%L) $$, tests.get('plain_id')), '42501', 'not_admin',
    'admin of another organization cannot revoke');
select tests.as_user('alice');
select throws_ok($$ select public.revoke_invite_link(gen_random_uuid()) $$, 'P0002', 'invite_not_found', 'unknown link');
select ok((select revoked_at is not null from public.revoke_invite_link(tests.get('plain_id')::uuid)), 'admin revokes a link');
select tests.save('revoked_at', (select revoked_at::text from public.invite_links where id = tests.get('plain_id')::uuid));
select lives_ok(format($$ select public.revoke_invite_link(%L) $$, tests.get('plain_id')), 'revoking twice is harmless');
select is((select revoked_at::text from public.invite_links where id = tests.get('plain_id')::uuid), tests.get('revoked_at'),
    'second revoke keeps the original timestamp');
select tests.as_user('frank');
select throws_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('plain')), 'P0001', 'invite_revoked',
    'revoked link cannot be used');
select tests.reset();
select is((select count(*)::int from public.organization_members where user_id = tests.uid('frank')), 0, 'no membership after failure');

-- Expired
select tests.as_user('alice');
select tests.save('exp_id', (public.create_invite_link(tests.org('Org A'))).id::text);
select tests.reset();
update public.invite_links set expires_at = now() - interval '1 minute' where id = tests.get('exp_id')::uuid;
select tests.save('exp', (select token from public.invite_links where id = tests.get('exp_id')::uuid));
select tests.as_user('frank');
select throws_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('exp')),
    'P0001', 'invite_expired', 'expired link');

-- Used up
select tests.as_user('alice');
select tests.save('one_id', (public.create_invite_link(tests.org('Org A'), null, interval '1 day', 1)).id::text);
select tests.reset();
select tests.save('one', (select token from public.invite_links where id = tests.get('one_id')::uuid));
select tests.as_user('gina');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('one')), 'single-use link works once');
select tests.as_user('hank');
select throws_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('one')), 'P0001', 'invite_used_up',
    'used-up link is rejected');
select tests.reset();
select is((select use_count from public.invite_links where id = tests.get('one_id')::uuid), 1, 'use_count capped at max_uses');
select is((select count(*)::int from public.organization_members where user_id = tests.uid('hank')), 0, 'no membership after used-up');
select is((select count(*)::int from public.organization_members where role = 'admin' and organization_id = tests.org('Org A')), 1,
    'joining never creates admins');

-- ============================ invite by username =============================================
select tests.as_user('bob');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'frank') $$, tests.org('Org A')), '42501', 'not_admin',
    'member cannot invite');
select tests.as_user('carol');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'frank') $$, tests.org('Org A')), '42501', 'not_admin',
    'outsider cannot invite');
select tests.as_anon();
select throws_ok(format($$ select public.invite_user_by_username(%L, 'frank') $$, tests.org('Org A')), '42501', null, 'anon cannot invite');

select tests.as_user('alice');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'nobody_here') $$, tests.org('Org A')),
    'P0002', 'user_not_found', 'unknown username');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'ALICE') $$, tests.org('Org A')),
    'P0001', 'cannot_invite_self', 'cannot invite yourself');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'bob') $$, tests.org('Org A')),
    'P0001', 'already_member', 'already a member');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'frank', %L) $$, tests.org('Org A'), tests.band('Band B1')),
    'P0001', 'band_not_in_organization', 'band of another organization');
select is((select count(*)::int from public.profiles where username = 'frank'), 0, 'frank is invisible before any invitation');

select tests.save('inv_frank', (public.invite_user_by_username(tests.org('Org A'), '  FRANK ')).id::text);
select is((select status from public.invitations where id = tests.get('inv_frank')::uuid), 'pending', 'invitation is pending');
select is((select invited_by from public.invitations where id = tests.get('inv_frank')::uuid), tests.uid('alice'), 'invited_by recorded');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'frank') $$, tests.org('Org A')),
    'P0001', 'already_invited', 'one pending invitation per user and organization');
select is((select count(*)::int from public.profiles where username = 'frank'), 1, 'admin can see the invited user''s profile');

-- Visibility of the invitation
select tests.as_user('frank');
select is((select count(*)::int from public.invitations), 1, 'invitee sees the invitation');
select is((select name from public.organizations), 'Org A', 'invitee can read the inviting organization''s name');
select is((select count(*)::int from public.organization_members), 0, 'invitee cannot read the roster yet');
select is((select count(*)::int from public.profiles where username = 'alice'), 1, 'invitee can see the inviter''s profile');
select tests.as_user('bob');
select is((select count(*)::int from public.invitations), 0, 'members cannot see invitations');
select tests.as_user('carol');
select is((select count(*)::int from public.invitations), 0, 'others cannot see invitations');
select tests.as_user('alice');
select is((select count(*)::int from public.invitations), 1, 'admin sees organization invitations');
select throws_ok(format($$ update public.invitations set status = 'accepted' where id = %L $$, tests.get('inv_frank')),
    '42501', null, 'invitations cannot be updated directly');
select tests.as_user('frank');
select throws_ok(format($$ update public.invitations set status = 'accepted' where id = %L $$, tests.get('inv_frank')),
    '42501', null, 'invitee cannot accept by updating the row');
select throws_ok(format($$ insert into public.invitations (organization_id, invited_user_id) values (%L, %L) $$,
    tests.org('Org A'), tests.uid('frank')), '42501', null, 'invitations cannot be inserted directly');

-- respond_to_invitation
select tests.as_user('carol');
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_frank')),
    'P0002', 'invitation_not_found', 'only the invitee can respond');
select tests.as_user('alice');
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_frank')),
    'P0002', 'invitation_not_found', 'an admin cannot accept on behalf of the invitee');
select tests.as_user('frank');
select throws_ok($$ select public.respond_to_invitation(gen_random_uuid(), true) $$, 'P0002', 'invitation_not_found', 'unknown invitation');
select is((select status from public.respond_to_invitation(tests.get('inv_frank')::uuid, true)), 'accepted', 'accept');
select is((select count(*)::int from public.organization_members where user_id = tests.uid('frank')), 1, 'membership created on accept');
select is((select role from public.organization_members where user_id = tests.uid('frank')), 'member', 'accepted as plain member');
select ok((select responded_at is not null from public.invitations where id = tests.get('inv_frank')::uuid), 'responded_at set');
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_frank')),
    'P0001', 'invitation_not_pending', 'responding twice (accept)');
select throws_ok(format($$ select public.respond_to_invitation(%L, false) $$, tests.get('inv_frank')),
    'P0001', 'invitation_not_pending', 'responding twice (decline after accept)');
select tests.as_anon();
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_frank')), '42501', null, 'anon denied');

-- Decline, then re-invite
select tests.as_user('alice');
select tests.save('inv_ivy', (public.invite_user_by_username(tests.org('Org A'), 'ivy')).id::text);
select tests.as_user('ivy');
select is((select status from public.respond_to_invitation(tests.get('inv_ivy')::uuid, false)), 'declined', 'decline');
select is((select count(*)::int from public.organizations), 0, 'declining does not grant access');
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_ivy')),
    'P0001', 'invitation_not_pending', 'cannot accept after declining');
select tests.reset();
select is((select count(*)::int from public.organization_members where user_id = tests.uid('ivy')), 0, 'no membership after decline');
select tests.as_user('alice');
select lives_ok(format($$ select public.invite_user_by_username(%L, 'ivy') $$, tests.org('Org A')), 're-invite after decline');

-- Cancel
select tests.as_user('alice');
select tests.save('inv_jan', (public.invite_user_by_username(tests.org('Org A'), 'jan')).id::text);
select tests.as_user('bob');
select throws_ok(format($$ select public.cancel_invitation(%L) $$, tests.get('inv_jan')), '42501', 'not_admin', 'member cannot cancel');
select tests.as_user('dave');
select throws_ok(format($$ select public.cancel_invitation(%L) $$, tests.get('inv_jan')), '42501', 'not_admin',
    'admin of another organization cannot cancel');
select tests.as_user('alice');
select throws_ok($$ select public.cancel_invitation(gen_random_uuid()) $$, 'P0002', 'invitation_not_found', 'unknown invitation');
select is((select status from public.cancel_invitation(tests.get('inv_jan')::uuid)), 'cancelled', 'admin cancels');
select throws_ok(format($$ select public.cancel_invitation(%L) $$, tests.get('inv_jan')), 'P0001', 'invitation_not_pending',
    'cancelling twice');
select throws_ok(format($$ select public.cancel_invitation(%L) $$, tests.get('inv_frank')), 'P0001', 'invitation_not_pending',
    'cannot cancel an accepted invitation');
select tests.as_user('jan');
select throws_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_jan')),
    'P0001', 'invitation_not_pending', 'cannot accept a cancelled invitation');

-- Invitation with a band
select tests.as_user('alice');
select tests.save('inv_kim', (public.invite_user_by_username(tests.org('Org A'), 'kim', tests.band('Band A1'))).id::text);
select tests.as_user('kim');
select lives_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_kim')), 'accept an invitation with a band');
select tests.reset();
select is((select count(*)::int from public.band_members where member_id = tests.member('Org A', 'kim')
           and band_id = tests.band('Band A1')), 1, 'invitee joined the band on accept');

-- Invitation accepted after joining by link: no duplicate membership
select tests.as_user('alice');
select tests.save('inv_hank', (public.invite_user_by_username(tests.org('Org A'), 'hank')).id::text);
select tests.as_user('hank');
select public.join_with_invite_link((select tokens.t from (select tests.get('band') as t) tokens));
select lives_ok(format($$ select public.respond_to_invitation(%L, true) $$, tests.get('inv_hank')), 'accept after joining by link');
select tests.reset();
select is((select count(*)::int from public.organization_members where user_id = tests.uid('hank')), 1, 'still a single membership row');

-- Invite to an organization from another organization admin is isolated
select tests.as_user('dave');
select throws_ok(format($$ select public.invite_user_by_username(%L, 'gina') $$, tests.org('Org A')), '42501', 'not_admin',
    'admin of Org B cannot invite into Org A');
select lives_ok(format($$ select public.invite_user_by_username(%L, 'gina') $$, tests.org('Org B')),
    'but can invite into Org B (users may belong to several organizations)');

-- Notifications created by invitations (and nothing for the cancelled one except its creation)
select tests.reset();
select is(tests.notifs('frank', 'invitation'), 1, 'inviting a user notifies them');
select is((select payload ->> 'organization_name' from public.notifications
           where recipient_id = tests.uid('frank') and type = 'invitation'), 'Org A',
          'invitation notification carries the organization name');
select is(tests.notifs('alice', 'invitation'), 0, 'the inviter is not notified');

-- Double submit by the same new user never surfaces a raw unique violation
select tests.as_user('alice');
select tests.save('dbl_id', (public.create_invite_link(tests.org('Org A'), null, interval '1 day', 5)).id::text);
select tests.reset();
select tests.save('dbl', (select token from public.invite_links where id = tests.get('dbl_id')::uuid));
select tests.as_user('jan');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('dbl')), 'first submit joins');
select lives_ok(format($$ select public.join_with_invite_link(%L) $$, tests.get('dbl')), 'second submit is a no-op');
select tests.reset();
select is((select use_count from public.invite_links where id = tests.get('dbl_id')::uuid), 1,
    'use_count bumped once for the same user');

select * from finish();
rollback;
