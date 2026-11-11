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
-- Songs, versions, visibility, scores, repertoire, setlists, forks (linking: 10_song_linking)
-- Org A: alice admin, bob member (song owner). Org B: dave admin.
-- carol is an outsider, zed a deactivated author.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol','dave','zed']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select tests.as_user('dave');
select public.create_organization('Org B');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role)
    values (tests.org('Org A'), tests.uid('bob'), 'member');

-- Creating songs and versions ---------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(format($$ insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000001', 'Song One', 'Band', %L) $$, tests.uid('bob')), 'user creates a song');
select throws_ok(format($$ insert into public.songs (title, artist, created_by) values ('Fake', 'x', %L) $$, tests.uid('alice')),
    '42501', null, 'cannot create a song as someone else');
select throws_ok($$ insert into public.songs (title, artist, created_by, normalized_key)
    values ('Sneaky', 'x', auth.uid(), 'sneaky|x') $$,
    '42501', null, 'normalized_key is not client-writable');
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, visibility) values
    ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000001', %1$L, 'V-private', 'private'),
    ('00000000-0000-0000-0000-0000000000a2', '00000000-0000-0000-0000-000000000001', %1$L, 'V-org', 'organizations'),
    ('00000000-0000-0000-0000-0000000000a3', '00000000-0000-0000-0000-000000000001', %1$L, 'V-public', 'public') $$,
    tests.uid('bob')), 'owner creates versions with each visibility');
select throws_ok(format($$ insert into public.song_versions (song_id, owner_id, label)
    values ('00000000-0000-0000-0000-000000000001', %L, 'Impostor') $$, tests.uid('alice')),
    '42501', null, 'cannot create a version owned by someone else');
-- A client may record the parent of a fork it creates offline, but only one it can see
-- (04 personal setlists / edit time migration).
select tests.as_user('alice');
select throws_ok(format($$ insert into public.song_versions (song_id, owner_id, label, forked_from_version_id)
    values ('00000000-0000-0000-0000-000000000001', %L, 'Fake fork', tests.version('V-private')) $$, tests.uid('alice')),
    '42501', null, 'forked_from_version_id cannot point at a version the owner cannot see');
select tests.as_user('bob');
select throws_ok(format($$ insert into public.version_shares (version_id, organization_id) values (tests.version('V-org'), %L) $$,
    tests.org('Org B')), '42501', null, 'owner cannot share to an organization they are not in');
select lives_ok(format($$ insert into public.version_shares (version_id, organization_id) values (tests.version('V-org'), %L) $$,
    tests.org('Org A')), 'owner shares to an organization they belong to');

-- A second work with only a private version (title must not leak)
select lives_ok(format($$ insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000002', 'Secret Song', 'Me', %L) $$, tests.uid('bob')), 'bob creates a second song');
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label)
    values ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-000000000002', %L, 'Secret V') $$,
    tests.uid('bob')), 'with a private version (the default visibility)');

-- Score tree on V-org and V-public
select lives_ok($$ insert into public.scores (id, version_id, title) values
    ('00000000-0000-0000-0000-00000000e001', tests.version('V-org'), 'Org score'),
    ('00000000-0000-0000-0000-00000000e002', tests.version('V-public'), 'Public score') $$, 'owner writes scores');
select lives_ok($$ insert into public.sections (id, score_id, name) values
    ('00000000-0000-0000-0000-00000000e101', '00000000-0000-0000-0000-00000000e001', 'Verse'),
    ('00000000-0000-0000-0000-00000000e102', '00000000-0000-0000-0000-00000000e002', 'Intro') $$, 'owner writes sections');
select lives_ok($$ insert into public.measures (id, section_id, measure_number) values
    ('00000000-0000-0000-0000-00000000e201', '00000000-0000-0000-0000-00000000e101', 1),
    ('00000000-0000-0000-0000-00000000e202', '00000000-0000-0000-0000-00000000e102', 1) $$, 'owner writes measures');
select lives_ok($$ insert into public.note_events (measure_id, pitch, duration_ticks) values
    ('00000000-0000-0000-0000-00000000e201', 'C4', 480), ('00000000-0000-0000-0000-00000000e202', 'D4', 480) $$, 'owner writes notes');
select lives_ok($$ insert into public.chord_symbols (measure_id, symbol) values
    ('00000000-0000-0000-0000-00000000e201', 'Cmaj7'), ('00000000-0000-0000-0000-00000000e202', 'G') $$, 'owner writes chords');
select is((select count(*)::int from public.song_versions), 4, 'owner sees all own versions');
select is((select count(*)::int from public.songs), 2, 'and both songs');

-- Visibility -------------------------------------------------------------------------------------------
select tests.as_anon();
select is((select array_agg(label order by label) from public.song_versions), array['V-public'],
    'anon reads the public version only');
select is((select count(*)::int from public.song_versions where label = 'V-org'), 0, 'anon does not read the organization-shared version');
select is((select array_agg(title order by title) from public.songs), array['Song One'],
    'anon sees the song of a public version, but not a song with only private versions');
select is((select count(*)::int from public.scores), 1, 'anon reads the public score');
select is((select count(*)::int from public.sections) + (select count(*)::int from public.measures)
        + (select count(*)::int from public.note_events) + (select count(*)::int from public.chord_symbols), 4,
    'and its whole tree (and nothing of the shared one)');
select throws_ok(format($$ insert into public.songs (title, artist, created_by) values ('x', 'x', %L) $$, tests.uid('bob')),
    '42501', null, 'anon cannot write songs');
select throws_ok($$ select * from public.version_shares $$, '42501', null, 'anon cannot read shares');
select throws_ok($$ select * from public.organization_repertoire $$, '42501', null, 'anon cannot read repertoire');

select tests.as_user('carol');
select is((select array_agg(label order by label) from public.song_versions), array['V-public'], 'outsider reads only the public version');
select is((select count(*)::int from public.scores), 1, 'outsider reads only the public score');
select is((select array_agg(title order by title) from public.songs), array['Song One'],
    'a private version does not leak its song title');

select tests.as_user('alice');
select is((select array_agg(label order by label) from public.song_versions), array['V-org','V-public'],
    'organization member reads shared + public, not private');
select is((select count(*)::int from public.scores), 2, 'and the scores of those versions');
select is((select count(*)::int from public.songs where title = 'Secret Song'), 0, 'private-only song stays invisible to members');
select tests.as_user('dave');
select is((select array_agg(label order by label) from public.song_versions), array['V-public'],
    'other organization does not see a version shared elsewhere');

-- Only the owner edits (admins included) -----------------------------------------------------------------
select tests.as_user('alice');
update public.song_versions set label = 'Hacked' where label = 'V-org';
delete from public.song_versions where label = 'V-org';
update public.songs set title = 'Hacked' where title = 'Song One';
delete from public.songs where title = 'Song One';
select throws_ok($$ insert into public.sections (score_id, name) values ('00000000-0000-0000-0000-00000000e001', 'Spam') $$,
    '42501', null, 'admin cannot add to a member''s score');
update public.scores set title = 'Hacked' where id = '00000000-0000-0000-0000-00000000e001';
delete from public.chord_symbols;
select throws_ok(format($$ insert into public.version_shares (version_id, organization_id) values (tests.version('V-public'), %L) $$,
    tests.org('Org A')), '42501', null, 'admin cannot share a member''s version');
select tests.reset();
select is((select count(*)::int from public.song_versions where label = 'V-org'), 1, 'admin cannot edit or delete another member''s version');
select is((select title from public.songs where id = '00000000-0000-0000-0000-000000000001'), 'Song One',
    'admin cannot edit or delete another member''s song');
select is((select title from public.scores where id = '00000000-0000-0000-0000-00000000e001'), 'Org score', 'nor the score');
select is((select count(*)::int from public.chord_symbols), 2, 'nor its chords');

select tests.as_user('bob');
select lives_ok($$ update public.song_versions set label = 'V-org', tempo = 90 where label = 'V-org' $$, 'owner edits own version');
select throws_ok(format($$ update public.song_versions set owner_id = %L where label = 'V-org' $$, tests.uid('alice')),
    '42501', null, 'ownership cannot be transferred');
select throws_ok($$ update public.song_versions set song_id = '00000000-0000-0000-0000-000000000002' where label = 'V-org' $$,
    '42501', null, 'versions move between songs only through move_version_to_song');

-- Repertoire ------------------------------------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-org'), %L) $$, tests.org('Org A'), tests.uid('alice')), 'admin adds a shared version to the repertoire');
select lives_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-public'), %L) $$, tests.org('Org A'), tests.uid('alice')), 'admin adds a public version');
select throws_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-private'), %L) $$, tests.org('Org A'), tests.uid('alice')),
    '42501', null, 'admin cannot add a version not visible to the organization (private)');
select throws_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-public'), %L) $$, tests.org('Org A'), tests.uid('bob')),
    '42501', null, 'added_by cannot be spoofed');
select tests.as_user('bob');
select throws_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-org'), %L) $$, tests.org('Org A'), tests.uid('bob')),
    '42501', null, 'a plain member (even the owner) cannot pick the repertoire');
select is((select count(*)::int from public.organization_repertoire), 2, 'members read the repertoire');
select tests.as_user('dave');
select throws_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-org'), %L) $$, tests.org('Org B'), tests.uid('dave')),
    '42501', null, 'a version shared only with Org A cannot enter Org B''s repertoire');
select lives_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-public'), %L) $$, tests.org('Org B'), tests.uid('dave')), 'but a public one can');
select tests.as_user('carol');
select is((select count(*)::int from public.organization_repertoire), 0, 'outsiders read no repertoire');

-- Setlists reference repertoire versions -----------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok(format($$ insert into public.setlists (id, organization_id, title) values ('set-1', %L, 'Sunday') $$,
    tests.org('Org A')), 'admin creates a setlist');
select lives_ok(format($$ insert into public.setlist_items (id, setlist_id, organization_id, position, version_id, title_snapshot)
    values ('00000000-0000-0000-0000-0000000000d1', 'set-1', %1$L, 1, tests.version('V-org'), 'ignored'),
           ('00000000-0000-0000-0000-0000000000d2', 'set-1', %1$L, 2, tests.version('V-public'), 'ignored') $$,
    tests.org('Org A')), 'admin adds repertoire versions to the setlist');
select is((select title_snapshot from public.setlist_items where position = 1), 'Song One', 'title is snapshotted from the song');
select is((select label_snapshot from public.setlist_items where position = 1), 'V-org', 'and the version label');
select throws_ok(format($$ insert into public.setlist_items (setlist_id, organization_id, position, version_id, title_snapshot)
    values ('set-1', %L, 3, tests.version('V-private'), 'x') $$, tests.org('Org A')),
    '23503', null, 'a version outside the repertoire cannot be in the setlist');
select tests.as_user('bob');
select is((select count(*)::int from public.setlist_items), 2, 'members read setlist items');
select throws_ok(format($$ insert into public.setlist_items (setlist_id, organization_id, position, version_id, title_snapshot)
    values ('set-1', %L, 3, tests.version('V-public'), 'x') $$, tests.org('Org A')),
    '42501', null, 'members cannot edit setlists');

-- Losing visibility removes the version from the repertoire, keeping a tombstone ------------------------------
select tests.as_user('bob');
select lives_ok($$ update public.song_versions set visibility = 'private' where label = 'V-org' $$, 'owner makes the version private');
select tests.reset();
select is((select count(*)::int from public.organization_repertoire where version_id = tests.version('V-org')), 0,
    'it leaves the repertoire of the organization');
select is((select count(*)::int from public.setlist_items where position = 1 and version_id is null
           and title_snapshot = 'Song One'), 1, 'the setlist entry becomes a tombstone with its title');
select is((select count(*)::int from public.setlist_items), 2, 'the setlist keeps both entries');
select is((select count(*)::int from public.version_shares where version_id = tests.version('V-org')), 0,
    'going private deletes the shares so no version uuid stays visible');
select tests.as_user('alice');
select is((select count(*)::int from public.version_shares where version_id = tests.version('V-org')), 0,
    'a plain member of the organization sees no share row of a private version');
select tests.as_user('bob');
select lives_ok($$ update public.song_versions set visibility = 'organizations' where label = 'V-org' $$, 'made shared again');
select tests.reset();
select is((select count(*)::int from public.organization_repertoire where version_id = tests.version('V-org')), 0,
    'it does not come back on its own');

-- Unsharing and public -> shared
select tests.as_user('bob');
select lives_ok(format($$ insert into public.version_shares (version_id, organization_id) values (tests.version('V-org'), %L) $$,
    tests.org('Org A')), 'owner shares it again (shares do not come back on their own)');
select tests.as_user('alice');
select lives_ok(format($$ insert into public.organization_repertoire (organization_id, version_id, added_by)
    values (%L, tests.version('V-org'), %L) $$, tests.org('Org A'), tests.uid('alice')), 'admin re-adds the shared version');
select tests.as_user('bob');
select lives_ok(format($$ delete from public.version_shares where version_id = tests.version('V-org') and organization_id = %L $$,
    tests.org('Org A')), 'owner unshares');
select tests.reset();
select is((select count(*)::int from public.organization_repertoire where version_id = tests.version('V-org')), 0,
    'unsharing removes it from that organization''s repertoire');
select tests.as_user('bob');
select lives_ok($$ update public.song_versions set visibility = 'organizations' where label = 'V-public' $$,
    'public version becomes organization-only without a share');
select tests.reset();
select is((select count(*)::int from public.organization_repertoire where version_id = tests.version('V-public')), 0,
    'it leaves every repertoire it was not shared to (Org A and Org B)');
select is((select count(*)::int from public.setlist_items where version_id is null), 2, 'setlist entries are tombstones');
update public.song_versions set visibility = 'public' where label = 'V-public';
update public.song_versions set visibility = 'organizations' where label = 'V-org';
insert into public.version_shares (version_id, organization_id) values (tests.version('V-org'), tests.org('Org A'));

-- Fork ---------------------------------------------------------------------------------------------------------
select tests.as_user('alice');
select tests.save('fork_id', (public.fork_song_version(tests.version('V-org'))).id::text);
select is((select owner_id from public.song_versions where id = tests.get('fork_id')::uuid), tests.uid('alice'), 'the fork is owned by the forker');
select is((select visibility from public.song_versions where id = tests.get('fork_id')::uuid), 'private', 'and private by default');
select is((select forked_from_version_id from public.song_versions where id = tests.get('fork_id')::uuid),
    tests.version('V-org'), 'with forked_from_version_id set');
select is((select song_id from public.song_versions where id = tests.get('fork_id')::uuid),
    '00000000-0000-0000-0000-000000000001'::uuid, 'under the same song');
select is((select label from public.song_versions where id = tests.get('fork_id')::uuid), 'V-org (copy)', 'default label');
select is((select tempo from public.song_versions where id = tests.get('fork_id')::uuid), 90, 'content is copied');
select is((select count(*)::int from public.scores where version_id = tests.get('fork_id')::uuid), 1, 'the score is copied');
select is((select count(*)::int from public.sections s join public.scores sc on sc.id = s.score_id
           where sc.version_id = tests.get('fork_id')::uuid), 1, 'with its sections');
select is((select count(*)::int from public.chord_symbols c join public.measures m on m.id = c.measure_id
           join public.sections s on s.id = m.section_id join public.scores sc on sc.id = s.score_id
           where sc.version_id = tests.get('fork_id')::uuid), 1, 'and chords');
select lives_ok($$ update public.song_versions set label = 'Alice take' where label = 'V-org (copy)' $$, 'the forker edits their copy');
select tests.as_user('bob');
select is((select count(*)::int from public.song_versions where label = 'Alice take'), 0, 'the original owner cannot see the private fork');
select is((select tempo from public.song_versions where label = 'V-org'), 90, 'original is untouched');
select tests.reset();
select is(tests.notifs('bob', 'song_version_forked'), 1, 'the original owner is notified');
select is(tests.notifs('alice', 'song_version_forked'), 0, 'the forker is not');

select tests.as_user('alice');
select throws_ok($$ select public.fork_song_version(tests.version('V-private')) $$, 'P0002', 'version_not_found',
    'cannot fork a version you cannot see');
select throws_ok($$ select public.fork_song_version(gen_random_uuid()) $$, 'P0002', 'version_not_found', 'nor an unknown one');
select tests.as_user('carol');
select throws_ok($$ select public.fork_song_version(tests.version('V-org')) $$, 'P0002', 'version_not_found',
    'an outsider cannot fork an organization-shared version');
select lives_ok($$ select public.fork_song_version(tests.version('V-public'), 'Carol arrangement') $$, 'anyone can fork a public version');
select is((select label from public.song_versions where owner_id = tests.uid('carol')), 'Carol arrangement', 'custom label');
select tests.as_anon();
select throws_ok($$ select public.fork_song_version(tests.version('V-public')) $$, '42501', null, 'anon cannot fork');
select tests.as_user('bob');
select lives_ok($$ select public.fork_song_version(tests.version('V-private'), 'Bob copy') $$, 'owner may fork their own version');
select tests.reset();
select is(tests.notifs('bob', 'song_version_forked'), 2, 'only forks by others notify: carol''s public fork did, bob''s own did not');

-- Fork of a deactivated owner's version
insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000003', 'Zed Song', 'Zed', tests.uid('zed'));
insert into public.song_versions (id, song_id, owner_id, label, visibility)
    values ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-000000000003', tests.uid('zed'), 'Zed V', 'public');
select public._deactivate_user(tests.uid('zed'));
select tests.as_user('alice');
select lives_ok($$ select public.fork_song_version(tests.version('Zed V')) $$, 'forking a deactivated owner''s version works');
select tests.reset();
select is(tests.notifs('zed', 'song_version_forked'), 0, 'deactivated owners are not notified');
select is((select visibility from public.song_versions where label = 'Zed V'), 'public', 'their version keeps its visibility');

select * from finish();
rollback;
