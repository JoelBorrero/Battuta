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

-- Direct deletes from storage tables are guarded by a trigger unless this flag is
-- set (the Storage API sets it); policies still decide which rows are visible.
create function tests.delete_objects(p_bucket text, p_name text default null) returns int
language plpgsql as $$
declare n int;
begin
    perform set_config('storage.allow_delete_query', 'true', true);
    delete from storage.objects where bucket_id = p_bucket and (p_name is null or name = p_name);
    get diagnostics n = row_count;
    return n;
end $$;

-- ============================================================================
-- Profile photos and organization logos: columns, constraints and the storage
-- policies of the avatars / organization-logos buckets.
-- alice admins Org A, bob is a member, carol is an outsider; Org B is archived.
-- ============================================================================

select tests.create_user(u) from unnest(array['alice','bob','carol']) as u;

select tests.as_user('alice');
select public.create_organization('Org A');
select public.create_organization('Org B');
select tests.reset();
insert into public.organization_members (organization_id, user_id, role)
    values (tests.org('Org A'), tests.uid('bob'), 'member');

-- Buckets ------------------------------------------------------------------------------------
select is((select public from storage.buckets where id = 'avatars'), true, 'avatars bucket is public');
select is((select file_size_limit from storage.buckets where id = 'organization-logos'), 2097152::bigint,
    'logos are limited to 2 MB');
select is((select allowed_mime_types from storage.buckets where id = 'avatars'),
    array['image/jpeg', 'image/png', 'image/webp'], 'only images are accepted');

-- Avatars ------------------------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('avatars', %L, auth.uid()) $$, tests.uid('bob')::text || '/one.jpg'),
    'bob can write into his own avatar folder');
select throws_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('avatars', %L, auth.uid()) $$, tests.uid('alice')::text || '/x.jpg'),
    '42501', null, 'bob cannot write into alice''s folder');
select throws_ok(
    $$ insert into storage.objects (bucket_id, name, owner) values ('avatars', 'loose.jpg', auth.uid()) $$,
    '42501', null, 'a path outside any user folder is refused');
select is(tests.delete_objects('avatars', tests.uid('bob')::text || '/one.jpg'), 1,
    'bob can delete his own object');
select lives_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('avatars', %L, auth.uid()) $$, tests.uid('bob')::text || '/two.jpg'),
    'bob uploads again');
select tests.as_user('carol');
select is((select count(*)::int from storage.objects where bucket_id = 'avatars'), 0,
    'carol cannot list bob''s object through the API');
select is(tests.delete_objects('avatars'), 0, 'carol cannot delete bob''s object');

-- profiles.avatar_path ---------------------------------------------------------------------
select tests.as_user('bob');
select lives_ok(
    format($$ update public.profiles set avatar_path = %L where id = auth.uid() $$,
           tests.uid('bob')::text || '/two.jpg'),
    'bob stores the path of his own object');
select throws_ok(
    format($$ update public.profiles set avatar_path = %L where id = auth.uid() $$,
           tests.uid('alice')::text || '/two.jpg'),
    '23514', null, 'a path in someone else''s folder is refused');

-- Deactivated accounts cannot write -------------------------------------------------------
select tests.reset();
update public.profiles set deactivated_at = now() where username = 'carol';
select tests.as_user('carol');
select throws_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('avatars', %L, auth.uid()) $$, tests.uid('carol')::text || '/c.jpg'),
    '42501', null, 'a deactivated account cannot upload');
select tests.reset();
update public.profiles set deactivated_at = null where username = 'carol';

-- Organization logos -----------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('organization-logos', %L, auth.uid()) $$, tests.org('Org A')::text || '/logo.jpg'),
    'an admin can write the logo of her organization');
select lives_ok(
    format($$ update public.organizations set logo_path = %L where id = %L $$,
           tests.org('Org A')::text || '/logo.jpg', tests.org('Org A')),
    'and store its path');
select throws_ok(
    format($$ update public.organizations set logo_path = %L where id = %L $$,
           tests.org('Org B')::text || '/logo.jpg', tests.org('Org A')),
    '23514', null, 'a logo path of another organization is refused');
select tests.as_user('bob');
select throws_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('organization-logos', %L, auth.uid()) $$, tests.org('Org A')::text || '/member.jpg'),
    '42501', null, 'a member cannot write the organization logo');
select is(tests.delete_objects('organization-logos'), 0, 'a member cannot delete the logo');
select tests.as_user('carol');
select throws_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('organization-logos', %L, auth.uid()) $$, tests.org('Org A')::text || '/out.jpg'),
    '42501', null, 'an outsider cannot write the organization logo');
select tests.as_user('alice');
select throws_ok(
    $$ insert into storage.objects (bucket_id, name, owner) values ('organization-logos', 'not-a-uuid/x.jpg', auth.uid()) $$,
    '42501', null, 'a folder that is not an organization id is refused');

-- Archived organization --------------------------------------------------------------------
select tests.reset();
update public.organizations set archived_at = now() where name = 'Org B';
select tests.as_user('alice');
select throws_ok(
    format($$ insert into storage.objects (bucket_id, name, owner)
              values ('organization-logos', %L, auth.uid()) $$, tests.org('Org B')::text || '/logo.jpg'),
    '42501', null, 'an archived organization''s logo cannot be written');

-- Description ------------------------------------------------------------------------------
select lives_ok(
    format($$ update public.organizations set description = %L where id = %L $$,
           repeat('x', 280), tests.org('Org A')),
    'a 280 character description is accepted');
select throws_ok(
    format($$ update public.organizations set description = %L where id = %L $$,
           repeat('x', 281), tests.org('Org A')),
    '23514', null, 'a 281 character description is refused');
select tests.as_user('bob');
select lives_ok(
    format($$ update public.organizations set description = 'mine' where id = %L $$, tests.org('Org A')),
    'a member''s description update runs (and matches no row)');
select tests.reset();
select isnt((select description from public.organizations where name = 'Org A'), 'mine',
    'a member cannot edit the description');

-- Deactivation clears the photo reference ---------------------------------------------------
select tests.reset();
update public.profiles set avatar_path = tests.uid('bob')::text || '/two.jpg' where username = 'bob';
select public._deactivate_user(tests.uid('bob'));
select is((select avatar_path from public.profiles where username = 'bob'), null,
    'deactivating an account clears its avatar path');

-- Search shows the path ---------------------------------------------------------------------
select tests.as_user('alice');
select lives_ok($$ select avatar_path from public.search_profiles('carol') $$,
    'search_profiles exposes avatar_path');

select * from finish();
rollback;
