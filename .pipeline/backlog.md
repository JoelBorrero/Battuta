# Pipeline backlog

Deferred findings that must not be forgotten. When a task closes, add anything it deferred here; when an
item is fixed, delete it (the fixing task's summary records it).

## ⚠ Verify first: integration tests not run (Docker was down)
Docker Desktop stopped responding on 2026-11-10 while 005 started, so tasks 005 onward were built and
reviewed without the local Supabase stack. Before relying on them:
1. Restart Docker Desktop, then `supabase start`.
2. `supabase db reset` (twice) and `supabase test db`.
3. `supabase db reset`, then `flutter test --tags supabase --run-skipped test/integration`.
4. Fix any failure, then remove this section. Tasks affected are listed below as they close.

Affected tasks: 005.

## From 001: harden transposer
- Sharp/flat spelling on free-form keys: `b minor` +2 → `Db minor` instead of `C# minor`.
- Hand-built custom labels that only look root-prefixed (`Cat` with root `C` → `Dat`).
- Chords with two slashes (`C7sus4/Bb/D`).

## From 002: Supabase schema
Planned into a later slice:
- Deactivated users' email stays in `auth.users` (needs a server-side scrub job).
- **008:** archive has no undo; say so in the archive confirmation UI.
- **007:** declined users can be re-invited repeatedly; removed members can rejoin with a still-valid link.
- **009:** merge-request spam: anyone who can see a song can keep sending its creator merge requests
  (with their own private title).

Small fixes, no slice yet:
- Old notifications stay after you're removed from an organization or demoted.
- Deactivated users can still read their own old notifications.
- The internal `battuta.silent` setting can be changed by a client through raw SQL.
- An assignment can be inserted with `responded_at` / `decline_reason` already set.
- Fork notification: `forked_by` may not resolve to a visible profile for the owner.
- A version switched organizations → public → organizations loses its repertoire rows until re-added.

Product / ops:
- Free plan quota values are placeholders.
- Signed-out viewers cannot see the author of a public song (profiles have no anon access).
- `auth.users` deletion was tested inside Postgres, not through the GoTrue admin API.

## From 003: org data layer
- Realtime arrays (e.g. `instruments`) have no integration test.
- Leaving an organization during an in-flight refresh of it can re-insert its members/events as orphans
  until the next refresh (`removeScope` is not tracked as a touch).
- A full A→B→A account round trip within one refresh can store B-token data under A.
- A row touched during a fetch and then deleted on the server with a missed delete event stays cached until
  the next refresh; the touched map grows if fetches always overlap.
- The realtime deactivation path in the coordinator does not check which account the error belongs to
  (the repository path does).
- One extra profile request per sign-in/session restore.

## From 004: song sync
- **008:** wire `canAdministerOrganization` (today even admins get `not_admin` from the setlist repository).
- **009:** title/artist edits on a version whose song was created by someone else are reverted by sync; needs a
  UI rule (edit only your own song's title, or propose a merge).
- **009:** `updateSharing` exists only on `DriftSongRepository`, not on the `SongRepository` interface.
- Sharing changes (label, visibility, shares) have no edit time: the device that syncs last wins.
- A refused share after a successful visibility update leaves the version `organizations` with only the
  accepted shares (no rollback).
- Organization setlists: an admin can set a far-future `edited_at` and always win over other admins (clamp on
  the server).
- A client can record fork lineage from any visible version without the `song_version_forked` notification
  (only `fork_song_version` notifies).
- Integration test "making a version private removes it from the member" failed once (not reproduced in 8
  runs): possible flake.

## From 005: auth gate and roster
- **Offline detection is slow:** postgrest retries every failed read 3 times (1 s + 2 s + 4 s), and
  supabase 2.16.5's `client.from()` ignores `PostgrestClientOptions.retryEnabled`/`retryCount` (only
  `client.rest.from()` honours them). An offline sync or refresh needs ~7 s per request to report `offline`, and
  macOS App Nap can stretch that a lot. Fix: route queries through `client.rest.from()` with a short retry
  policy, or upgrade supabase once `from()` honours the options. `cloud_sync_offline_test` has a 3-minute
  timeout because of this.
- `saveMember` is several writes, not a transaction: partial saves are explained to the user and retries re-read
  the roster, but a retry tapped before realtime delivers the earlier writes may be refused (nothing corrupts).
- Formatting-only churn remains in `song_editor_page.dart`, `supabase_auth_repository.dart`,
  `practice_player_bar.dart`, `supabase_cloud_sync_service.dart` (005 reformat slip).
- Spanish strings added in 005+ are not reviewed by a native speaker.
- The deferred deactivation-notice clear could, in theory, clear a brand-new notice with a synchronous guard
  (no realistic ordering found).
