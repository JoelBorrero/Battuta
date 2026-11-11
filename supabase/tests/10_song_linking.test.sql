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
-- Song linking: normalized identity, find_or_create_song, move_version_to_song,
-- empty songs, search, and the removal of merge.
-- alice and bob are in Org A; carol is an outsider.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol']) as u;

-- Merge is gone -----------------------------------------------------------------------------
select hasnt_table('public', 'song_merge_requests', 'merge requests are gone');
select hasnt_column('public', 'songs', 'merged_into_id', 'songs no longer redirect');
select hasnt_function('public', 'request_song_merge', 'request_song_merge is gone');
select hasnt_function('public', 'respond_to_song_merge', 'respond_to_song_merge is gone');
select hasnt_function('public', 'resolve_song', 'resolve_song is gone');
select has_column('public', 'songs', 'normalized_key', 'songs have a normalized key');
select has_index('public', 'songs', 'songs_normalized_key_idx', 'and it is unique');

-- Normalization ----------------------------------------------------------------------------
select is(public.normalize_song_text('  Tú  Fidelidad! '), 'tu fidelidad', 'accents, case, punctuation, spaces');
select is(public.normalize_song_text('Don''t Stop'), 'dont stop', 'apostrophes vanish');
select is(public.normalize_song_text('Way Maker (Live)'), 'way maker live', 'parentheses become spaces');
select isnt(public.normalize_song_text('Way Maker (Live)'), public.normalize_song_text('Way Maker'),
    'a live version is a different song');

-- find_or_create_song ------------------------------------------------------------------------
select tests.as_anon();
select throws_ok($$ select public.find_or_create_song('Way Maker', 'Sinach') $$, '42501', null, 'anon cannot call it');

select tests.as_user('alice');
select tests.save('wm', public.find_or_create_song('Way Maker', 'Sinach')::text);
select is(public.find_or_create_song('way  maker', 'SINACH')::text, tests.get('wm'), 'case and spaces: same song');
select is(public.find_or_create_song('Way Maker', ' Sinach ')::text, tests.get('wm'), 'trimmed: same song');
select is((select created_by from public.songs where id = tests.get('wm')::uuid), tests.uid('alice'), 'the first caller is the creator');
select is((select title from public.songs where id = tests.get('wm')::uuid), 'Way Maker', 'with the title as typed');
select isnt(public.find_or_create_song('Way Maker (Live)', 'Sinach')::text, tests.get('wm'), '(Live) is another song');
select tests.save('tf', public.find_or_create_song('Tú Fidelidad', 'Marcos Witt')::text);
select is(public.find_or_create_song('Tu fidelidad', 'marcos witt')::text, tests.get('tf'), 'accents do not split songs');
select throws_ok($$ select public.find_or_create_song('   ', 'x') $$, '23514', null, 'a blank title is refused');

-- A song whose only version is private to alice still resolves for bob.
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, visibility)
    values ('00000000-0000-0000-0000-0000000000a1', %L, %L, 'Alice WM', 'private') $$,
    tests.get('wm'), tests.uid('alice')), 'alice attaches a private version');
select tests.as_user('bob');
select is((select count(*)::int from public.songs where id = tests.get('wm')::uuid), 0, 'bob cannot see that song');
select is(public.find_or_create_song('WAY MAKER', 'sinach')::text, tests.get('wm'), 'but typing it finds the same song');
select is((select count(*)::int from public.songs), 0, 'and it revealed nothing else');
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, visibility)
    values ('00000000-0000-0000-0000-0000000000b1', %L, %L, 'Bob WM', 'private') $$,
    tests.get('wm'), tests.uid('bob')), 'bob attaches his version to it');
select is((select count(*)::int from public.songs where id = tests.get('wm')::uuid), 1, 'now bob sees the song');
select is((select count(*)::int from public.song_versions where song_id = tests.get('wm')::uuid), 1,
    'but only his own version');
select tests.reset();
select is((select count(*)::int from public.song_versions where song_id = tests.get('wm')::uuid), 2, 'one song holds both versions');
select is((select count(*)::int from public.songs where normalized_key = 'way maker|sinach'), 1, 'exactly one song');

-- Direct inserts and renames respect the key --------------------------------------------------
select tests.as_user('alice');
select throws_ok(format($$ insert into public.songs (title, artist, created_by) values ('WAY MAKER', 'Sinach', %L) $$,
    tests.uid('alice')), 'P0001', 'song_exists', 'a direct duplicate insert is refused');
select lives_ok(format($$ insert into public.songs (id, title, artist, created_by)
    values ('00000000-0000-0000-0000-000000000002', 'Goodness', 'Bethel', %L) $$, tests.uid('alice')), 'alice creates another song');
select lives_ok($$ update public.songs set title = 'Goodness of God' where id = '00000000-0000-0000-0000-000000000002' $$,
    'the creator renames it');
select is((select normalized_key from public.songs where id = '00000000-0000-0000-0000-000000000002'),
    'goodness of god|bethel', 'and the key follows');
select throws_ok(format($$ update public.songs set title = 'Way Maker', artist = 'sinach' where id = '00000000-0000-0000-0000-000000000002' $$),
    'P0001', 'song_exists', 'renaming onto another song is refused');
select tests.as_user('bob');
select lives_ok(format($$ update public.songs set title = 'Hijack' where id = %L $$, tests.get('wm')), 'a non-creator update runs...');
select tests.reset();
select is((select title from public.songs where id = tests.get('wm')::uuid), 'Way Maker', '...but changes nothing');

-- move_version_to_song -----------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label, visibility)
    values ('00000000-0000-0000-0000-0000000000b2', %L, %L, 'Bob wrong', 'public') $$,
    tests.get('wm'), tests.uid('bob')), 'bob attaches a version to the wrong song');
-- find_or_create_song needs a signed-in caller (tests.reset() clears the JWT claims).
select tests.as_user('bob');
select tests.save('wrong', public.find_or_create_song('Goodness of God', 'Bethel')::text);
select tests.as_anon();
select throws_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Bob wrong'), tests.get('wrong')),
    '42501', null, 'anon cannot move');
select tests.as_user('carol');
select throws_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Bob wrong'), tests.get('wrong')),
    '42501', 'not_version_owner', 'someone who can see a version cannot move it');
select throws_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Alice WM'), tests.get('wrong')),
    'P0002', 'version_not_found', 'a private version of another user looks unknown');
select tests.as_user('alice');
select throws_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Bob wrong'), tests.get('wrong')),
    '42501', 'not_version_owner', 'another member cannot move it either');
select tests.as_user('bob');
select throws_ok(format($$ select public.move_version_to_song(%L, gen_random_uuid()) $$, tests.version('Bob wrong')),
    'P0002', 'song_not_found', 'the target must exist');
select throws_ok($$ select public.move_version_to_song(gen_random_uuid(), null) $$, 'P0002', null, 'unknown version');

select tests.as_user('bob');
select lives_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Bob wrong'), tests.get('wrong')),
    'the owner moves the version');
select is((select song_id from public.song_versions where label = 'Bob wrong'), tests.get('wrong')::uuid, 'it is under the new song');
select is((select visibility from public.song_versions where label = 'Bob wrong'), 'public', 'and keeps its visibility');
select is((select owner_id from public.song_versions where label = 'Bob wrong'), tests.uid('bob'), 'and its owner');
select lives_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Bob wrong'), tests.get('wrong')),
    'moving to the same song is a no-op');

-- Empty songs disappear ------------------------------------------------------------------------
select tests.reset();
select is((select count(*)::int from public.songs where id = tests.get('wrong')::uuid), 1, 'the target song exists while it holds bob''s version');
select tests.as_user('bob');
select lives_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Bob wrong'), tests.get('wm')),
    'bob moves it to the right song');
select tests.reset();
select is((select count(*)::int from public.song_versions where song_id = tests.get('wm')::uuid), 3, 'three versions now');
select is((select count(*)::int from public.songs where id = tests.get('wrong')::uuid), 0, 'the emptied song is removed');

-- A song loses its last version by move: gone
select tests.as_user('bob');
select tests.save('solo', public.find_or_create_song('Solo Song', 'Nobody')::text);
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label)
    values ('00000000-0000-0000-0000-0000000000b3', %L, %L, 'Solo V') $$, tests.get('solo'), tests.uid('bob')), 'a song with one version');
select lives_ok(format($$ select public.move_version_to_song(%L, %L) $$, tests.version('Solo V'), tests.get('wm')), 'its version moves away');
select tests.reset();
select is((select count(*)::int from public.songs where id = tests.get('solo')::uuid), 0, 'the emptied song is removed');

-- ... or by delete
select tests.as_user('bob');
select tests.save('solo2', public.find_or_create_song('Solo Two', 'Nobody')::text);
select lives_ok(format($$ insert into public.song_versions (id, song_id, owner_id, label)
    values ('00000000-0000-0000-0000-0000000000b4', %L, %L, 'Solo2 V') $$, tests.get('solo2'), tests.uid('bob')), 'another one-version song');
select lives_ok($$ delete from public.song_versions where label = 'Solo2 V' $$, 'its owner deletes the version');
select tests.reset();
select is((select count(*)::int from public.songs where id = tests.get('solo2')::uuid), 0, 'the song is removed');
select is((select count(*)::int from public.songs where id = tests.get('wm')::uuid), 1, 'songs with versions stay');

-- Search ----------------------------------------------------------------------------------------
select tests.as_user('bob');
select is((select count(*)::int from public.search_songs('way maker')), 1, 'finds by title');
select is((select version_count from public.search_songs('maker')), 3, 'counts only the versions bob can see (his 3, not alice''s private one)');
select is((select count(*)::int from public.search_songs('Way Maker Sinach')), 1, 'title and artist together');
select is((select count(*)::int from public.search_songs('way makr')), 1, 'tolerates typos');
select is((select count(*)::int from public.search_songs('  ')), 0, 'blank query finds nothing');
select is((select count(*)::int from public.search_songs('zzzz nothing')), 0, 'no match');
select tests.as_user('carol');
select is((select count(*)::int from public.search_songs('way maker')), 1, 'carol sees the song through bob''s public version');
select is((select version_count from public.search_songs('way maker')), 1, 'with only the public version counted');
select tests.as_anon();
select throws_ok($$ select * from public.search_songs('way') $$, '42501', null, 'anon cannot search');

select * from finish();
rollback;
