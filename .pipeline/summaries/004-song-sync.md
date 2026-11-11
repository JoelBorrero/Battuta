---
status: done
commit: "feat(sync): sync songs, versions, scores and setlists with the new schema"
base_sha: 9963f45
rounds: 2 of 3
---
# 004: Songs, versions, scores and setlists sync with the new schema

**Goal:** signed in and online, the user's songs and setlists sync both ways with the 002 schema and stay
fully usable offline; songs created in local mode become the user's private versions on first sign-in.
No UI changes (sharing UI is 008).

## What changed
- **Mapping:** a local `Song` is one backend **version** (`Song.id` = `song_versions.id`). Drift v3 adds
  `songWorkId`, `ownerId`, `accountId`, `label`, `visibility`, `forkedFromVersionId`, shared organization ids,
  and sync state (`isDirty`, `sharingDirty`, `deletedAt` tombstone, `remoteUpdatedAt`, `editedAtMs`).
  Migration test from a real v2 database; old rows get `editedAtMs` from `updated_at`.
- **Ownership:** only rows owned by the signed-in account are pushed. Others' versions are cached read-only;
  saving or deleting them returns `PermissionFailure` with `notOwner`. Importing a song file strips ownership
  and sharing fields. Organization setlists are editable only when `canAdministerOrganization` allows it.
- **Offline cache:** my versions, versions in my organizations' repertoire and versions my setlists use.
  Public or shared versions outside that are fetched online only. Sync never blocks a local save.
- **Sync service** (`lib/features/sync/data/`, rewritten, no demo dependency). Each run:
  1. claims local-mode data;
  2. gives legacy setlist ids UUIDs;
  3. pushes versions, scores and setlists;
  4. pulls and reconciles.

  It stops if the signed-in account changes mid-run.
- **Conflicts:** newest **edit** wins. Clients stamp `edited_at` (millisecond precision, strictly increasing per
  row); the server never changes it, so merges and server updates cannot beat a pending edit. A row edited
  during its own push stays dirty.
- **Reconcile:** each pull compares `id` + `updated_at` of everything visible with what is stored. Clean synced
  rows no longer visible (deleted, made private, unshared, removed from repertoire) are removed; unsynced and
  local-mode rows are never touched; a failed pull aborts before removing anything. Merges move cached
  versions to the surviving song.
- **Sharing:** label, visibility and shares sync whenever they change (`DriftSongRepository.updateSharing`).
  Each organization share is added on its own; a share the server refuses (not a member) is reported once and
  the local copy takes the server's state. Network errors are retried on the next sync, never treated as a
  refusal.
- **Forks:** a version created as a fork keeps `forked_from_version_id` and is pushed after its parent.
- **First sign-in:** local-mode songs become private versions of that account; bundled `seed-*` songs are never
  uploaded; a second account on the same device claims nothing another account already claimed.
- **Setlists:** personal setlists (owner only) and organization setlists (members read, admins write) sync with
  per-item key and tempo overrides; items whose version disappeared keep the server's title snapshot.
- **Server:** new migration `20261110000100_personal_setlists_and_overrides.sql` (baseline untouched):
  personal setlists with owner-only RLS, `key_override` / `tempo_override`, client `edited_at`, and an insert
  policy that allows fork lineage only from a version the owner can see. pgTAP `08_personal_setlists.test.sql`;
  the 002 test about lineage now asserts the visible-parent rule.

## Decisions
- A pending local edit on a version deleted on another device re-creates it (a hard delete has no time to
  compare; keeping the owner's data is the safe choice). Documented in `supabase/README.md` section 6.
- Your own songs stay on the device after sign-out.
- Drift v3 was edited in place during the task because it had never been released.

## Deferred
See `.pipeline/backlog.md` (004 section).

## Verification
`supabase db reset` twice: clean. `supabase test db`: 683 passed. `flutter analyze`: 0 issues.
`flutter test`: 664 passed. Integration (`--tags supabase --run-skipped test/integration`): 41 passed.
