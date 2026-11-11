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

-- Number of rows a statement affected, as the calling role.
create function tests.affected(p_sql text) returns int language plpgsql as $$
declare n int;
begin
    execute p_sql;
    get diagnostics n = row_count;
    return n;
end $$;
grant execute on function tests.affected(text) to anon, authenticated;

-- ============================================================================
-- Personal setlists, overrides and the exactly-one-owner rule
-- Org A: alice admin, bob member. carol is an outsider.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role)
    values (tests.org('Org A'), tests.uid('bob'), 'member');

-- Versions: bob's private one, bob's version shared with Org A, a public one by alice.
select tests.as_user('bob');
select lives_ok(format($$ insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000001', 'Song One', 'Band', %L) $$, tests.uid('bob')), 'bob creates a song');
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, visibility, key) values
    ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000001', %1$L, 'V-private', 'private', 'G'),
    ('00000000-0000-0000-0000-0000000000a2', '00000000-0000-0000-0000-000000000001', %1$L, 'V-org', 'organizations', 'A') $$,
    tests.uid('bob')), 'bob creates versions');
select lives_ok(format($$ insert into public.version_shares (version_id, organization_id) values (%L, %L) $$,
    tests.version('V-org'), tests.org('Org A')), 'and shares one with Org A');
select tests.as_user('alice');
select lives_ok(format($$ insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000002', 'Song Two', 'Band', %L) $$, tests.uid('alice')), 'alice creates a song');
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, visibility) values
    ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-000000000002', %1$L, 'V-public', 'public'),
    ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000002', %1$L, 'V-alice-private', 'private') $$,
    tests.uid('alice')), 'with a public and a private version');

-- Shape ---------------------------------------------------------------------------------------
select has_column('public', 'setlists', 'owner_id', 'setlists have an owner');
select col_is_null('public', 'setlists', 'organization_id', 'and an optional organization');
select has_column('public', 'setlist_items', 'key_override', 'items have a key override');
select has_column('public', 'setlist_items', 'tempo_override', 'and a tempo override');

-- Creating personal setlists -------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(format($$ insert into public.setlists (id, owner_id, title) values ('p-bob', %L, 'Bob set') $$,
    tests.uid('bob')), 'a user creates a personal setlist');
select throws_ok(format($$ insert into public.setlists (id, owner_id, title) values ('p-fake', %L, 'x') $$,
    tests.uid('alice')), '42501', null, 'but not for someone else');
select throws_ok(format($$ insert into public.setlists (id, organization_id, owner_id, title)
    values ('p-both', %L, %L, 'x') $$, tests.org('Org A'), tests.uid('bob')),
    '42501', null, 'a setlist cannot have an organization and an owner');
select throws_ok($$ insert into public.setlists (id, title) values ('p-none', 'x') $$,
    '42501', null, 'nor neither');
select throws_ok(format($$ insert into public.setlists (id, organization_id, title) values ('o-bob', %L, 'x') $$,
    tests.org('Org A')), '42501', null, 'a plain member cannot create an organization setlist');

select tests.reset();
select throws_ok(format($$ insert into public.setlists (id, organization_id, owner_id, title)
    values ('p-both', %L, %L, 'x') $$, tests.org('Org A'), tests.uid('bob')),
    '23514', null, 'the table itself rejects an organization plus an owner');
select throws_ok($$ insert into public.setlists (id, title) values ('p-none', 'x') $$,
    '23514', null, 'and neither');
select tests.as_user('bob');

-- Items: any version the owner can see ---------------------------------------------------------
select lives_ok(format($$ insert into public.setlist_items
    (id, setlist_id, position, version_id, title_snapshot, key_override, tempo_override, notes) values
    ('00000000-0000-0000-0000-0000000000d1', 'p-bob', 0, %L, 'x', 'Bb', 90, 'slow intro'),
    ('00000000-0000-0000-0000-0000000000d2', 'p-bob', 1, %L, 'x', null, null, null),
    ('00000000-0000-0000-0000-0000000000d3', 'p-bob', 2, %L, 'x', null, null, null) $$,
    tests.version('V-private'), tests.version('V-org'), tests.version('V-public')),
    'bob adds his private, shared and a public version');
select is((select title_snapshot from public.setlist_items where position = 0), 'Song One', 'the title is snapshotted');
select is((select label_snapshot from public.setlist_items where position = 0), 'V-private', 'and the label');
select is((select key_override || tempo_override::text || notes from public.setlist_items where position = 0),
    'Bb90slow intro', 'overrides and notes round trip');
select throws_ok(format($$ insert into public.setlist_items (setlist_id, position, version_id, title_snapshot)
    values ('p-bob', 5, %L, 'x') $$, tests.version('V-alice-private')),
    '42501', null, 'a version the owner cannot see cannot be added');
select throws_ok($$ insert into public.setlist_items (setlist_id, position, title_snapshot, tempo_override)
    values ('p-bob', 5, 'x', 5) $$, '23514', null, 'tempo overrides are bounded');
select lives_ok($$ insert into public.setlist_items (setlist_id, position, title_snapshot)
    values ('p-bob', 6, 'Free text') $$, 'an item without a version keeps its snapshot');
select throws_ok(format($$ insert into public.setlist_items (setlist_id, organization_id, position, version_id, title_snapshot)
    values ('p-bob', %L, 7, null, 'x') $$, tests.org('Org A')),
    '42501', null, 'an organization item cannot be attached to a personal setlist');

-- Privacy ------------------------------------------------------------------------------------
select tests.as_user('alice');
select is((select count(*)::int from public.setlists where id = 'p-bob'), 0, 'other users do not see personal setlists');
select is((select count(*)::int from public.setlist_items where setlist_id = 'p-bob'), 0, 'nor their items');
select throws_ok($$ insert into public.setlist_items (setlist_id, position, title_snapshot)
    values ('p-bob', 9, 'x') $$, '42501', null, 'and cannot add items to them');
select is(tests.affected($$ update public.setlists set title = 'hijacked' where id = 'p-bob' $$), 0, 'or edit them');
select lives_ok($$ delete from public.setlists where id = 'p-bob' $$, 'delete of a foreign setlist is a no-op');
select tests.as_user('carol');
select is((select count(*)::int from public.setlists), 0, 'outsiders see none');
select tests.as_anon();
select throws_ok($$ select count(*) from public.setlists $$, '42501', null, 'anonymous users have no access');

-- Organization setlists stay admin-write, member-read --------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.setlists (id, organization_id, title) values ('o-alice', %L, 'Org set') $$,
    tests.org('Org A')), 'an admin creates an organization setlist');
select tests.as_user('bob');
select is((select count(*)::int from public.setlists where id = 'o-alice'), 1, 'members read it');
select is((select owner_id from public.setlists where id = 'o-alice'), null, 'it has no owner');
select is(tests.affected($$ update public.setlists set title = 'x' where id = 'o-alice' $$), 0, 'but cannot edit it');

-- A setlist never changes hands --------------------------------------------------------------
select tests.as_user('alice');
select throws_ok(format($$ update public.setlists set owner_id = %L, organization_id = null where id = 'o-alice' $$,
    tests.uid('alice')), '42501', null, 'organization and owner cannot be updated');
select lives_ok($$ update public.setlists set title = 'Renamed' where id = 'o-alice' $$, 'but the title can');

-- Tombstones ------------------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok($$ delete from public.song_versions where label = 'V-private' $$, 'bob deletes a version');
select is((select count(*)::int from public.setlist_items where setlist_id = 'p-bob' and position = 0
           and version_id is null and title_snapshot = 'Song One' and key_override = 'Bb'),
    1, 'the personal item becomes a tombstone with snapshot and overrides');
select tests.as_user('bob');
select lives_ok($$ update public.song_versions set visibility = 'private' where label = 'V-org' $$, 'private again');
select is((select count(*)::int from public.setlist_items where setlist_id = 'p-bob' and version_id is not null),
    2, 'a personal item keeps its link to a version the owner still sees');

-- Deleting a setlist deletes its items ------------------------------------------------------
select lives_ok($$ delete from public.setlists where id = 'p-bob' $$, 'bob deletes the setlist');
select tests.reset();
select is((select count(*)::int from public.setlist_items where setlist_id = 'p-bob'), 0, 'its items go with it');

-- Edit time: only clients write it, the server never touches it ---------------------------------
select has_column('public', 'song_versions', 'edited_at', 'versions have an edit time');
select has_column('public', 'scores', 'edited_at', 'scores too');
select has_column('public', 'setlists', 'edited_at', 'and setlists');

select tests.as_user('bob');
select lives_ok(format($$ update public.song_versions set edited_at = '2026-01-01T10:00:00.123Z', key = 'D'
    where id = %L $$, tests.version('V-org')), 'the owner stamps the edit time of a version');
select is((select edited_at from public.song_versions where id = tests.version('V-org')),
    '2026-01-01T10:00:00.123Z'::timestamptz, 'and it is kept with millisecond precision');
select tests.as_user('alice');
select lives_ok($$ update public.setlists set edited_at = '2026-01-02T10:00:00Z' where id = 'o-alice' $$,
    'an admin stamps the edit time of an organization setlist');
select is((select edited_at from public.setlists where id = 'o-alice'), '2026-01-02T10:00:00Z'::timestamptz,
    'and it is kept');

-- Moving a version to another song leaves the edit time alone.
select tests.as_user('bob');
select lives_ok(format($$ insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000003', 'Song Three', 'Band', %L) $$, tests.uid('bob')),
    'bob creates a second song');
select lives_ok($$ select public.move_version_to_song(tests.version('V-org'), tests.song('Song Three')) $$,
    'bob moves his version to it');
select is((select song_id from public.song_versions where id = tests.version('V-org')),
    tests.song('Song Three'), 'the version moved to the other song');
select is((select edited_at from public.song_versions where id = tests.version('V-org')),
    '2026-01-01T10:00:00.123Z'::timestamptz, 'but its edit time did not change');
select tests.reset();
update public.song_versions set key = 'E' where id = tests.version('V-org');
select is((select edited_at from public.song_versions where id = tests.version('V-org')),
    '2026-01-01T10:00:00.123Z'::timestamptz, 'no server-side write changes it (updated_at is separate)');

-- Removing a share (repertoire cleanup) leaves it alone as well.
select tests.as_user('bob');
select lives_ok(format($$ delete from public.version_shares where version_id = %L $$, tests.version('V-org')),
    'a share is removed');
select is((select edited_at from public.song_versions where id = tests.version('V-org')),
    '2026-01-01T10:00:00.123Z'::timestamptz, 'the edit time is still the owner''s');

-- Fork lineage: a client may record a parent it can see, not one it cannot.
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, forked_from_version_id)
    values ('00000000-0000-0000-0000-0000000000c1', %L, %L, 'Fork of public', %L) $$,
    tests.song('Song Three'), tests.uid('bob'), tests.version('V-public')),
    'a fork of a visible version keeps its parent');
select is((select forked_from_version_id from public.song_versions where label = 'Fork of public'),
    tests.version('V-public'), 'the lineage is stored');
select throws_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, forked_from_version_id)
    values ('00000000-0000-0000-0000-0000000000c2', %L, %L, 'Fork of secret', %L) $$,
    tests.song('Song Three'), tests.uid('bob'), tests.version('V-alice-private')),
    '42501', null, 'but the parent must be visible to the owner');

-- Deactivated users cannot write personal setlists -----------------------------------------------
select tests.as_user('bob');
select lives_ok($$ select public.deactivate_account() $$, 'bob deactivates');
select throws_ok(format($$ insert into public.setlists (id, owner_id, title) values ('p-late', %L, 'x') $$,
    tests.uid('bob')), '42501', null, 'and can no longer create personal setlists');

select * from finish();
rollback;
