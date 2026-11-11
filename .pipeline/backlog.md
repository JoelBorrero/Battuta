# Pipeline backlog

Deferred findings that must not be forgotten. When a task closes, add anything it deferred here; when an
item is fixed, delete it (the fixing task's summary records it).

## From 001: harden transposer
- Sharp/flat spelling on free-form keys: `b minor` +2 → `Db minor` instead of `C# minor`.
- Hand-built custom labels that only look root-prefixed (`Cat` with root `C` → `Dat`).
- Chords with two slashes (`C7sus4/Bb/D`).

## From 002: Supabase schema
Planned into a later slice:
- Deactivated users' email stays in `auth.users` (needs a server-side scrub job).
- Removed members can rejoin with a still-valid invite link (the username search now shows "previously declined"; re-inviting declined users is still allowed).

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

## From 006: calendar
- Every 23505 maps to `BackendErrorCode.conflict`: cloud sync then says "Sync failed: conflict", and assigning
  the same member twice to one instrument shows a generic message. Add a dedicated string and include the
  server message in the sync description.
- DST tests depend on the host time zone (a UTC CI would not catch a regression): run the team tests with
  `TZ=America/New_York` and `TZ=Europe/Madrid` in CI.
- Bi-weekly and monthly cadences need an anchor date on `recurring_schedules`.
- A schedule with `pattern = 'none'` would project a daily phantom occurrence.
- "Find cover" lets you re-pick the member who declined (no-op).
- Alert dismissal ids repeat if the same member declines the same assignment again.
- The alerts banner shows for admins of archived organizations.

## From 007: invites and inbox
- **Live page overflows below 768 px** (pre-existing, `live_session_page.dart` lines ~160, 201, 307): needs its
  own fix task; the Live layout test only runs at ≥ 768 px.
- Join confirmation says "Join this organization?" without the name: needs an RPC that returns the organization
  name (and maybe member count) for a token before joining.
- A cold-start link may arrive twice (engine route + `app_links`); joining is idempotent, but verify on a device.
- Notification taps go to the tab, not the item (calendar event not highlighted; merge → repertoire,
  archive → Roster until 008/009 add the screens).
- Revoke/expiry: no universal https links (no web domain yet).
- A token captured in offline mode stays in memory until dismissed, "Continue offline", sign-out or account
  switch (the join still asks for confirmation).

## From 008: org repertoire and admin tools
- **Product decision:** the Gemini API key (and so scanning) is admin-only via `isCurrentUserAdminProvider`; a
  plain member cannot scan into their own library.
- No realtime for `organization_repertoire` (not in the realtime publication; needs a migration). The cache
  refreshes on first watch, sign-in/resync and after the admin's own add/remove.
- The repertoire scope (My library / organization) is not persisted across restarts.
- Failed-write rollback in `Repertoire.addSong/updateSong/deleteSong` restores the whole list snapshot: a newer
  change made meanwhile disappears from the UI until reload (DB stays correct). Roll back only the affected song.
- Callers that ignore the returned `Failure?` still show success on a failed local write: import modal
  (`song_import_modal.dart`), `repertoire_page.dart` add, `scanner_page.dart`, `score_editor_page.dart`.
- A repertoire version that can never be pulled (made private) keeps "Available after the next sync" and each
  tap runs a futile sync.
- Candidate search uses `id.in.(...)` with every version shared to the org (~200 shares approach URL limits;
  `version_shares` select capped at 1000 rows) and reads all pages eagerly: move to an RPC or view.

## From 009: song sharing
- `PracticePlayerBar` overflows by 25 px at 320 px (`practice_player_bar.dart:151`, pre-existing).
- Discover swallows a load-more failure when results already exist.
- Hard-coded English "(copy)" fallback label in `song_sharing_repository_impl.dart:146` (UI never reaches it).
- The "Owned by" banner says "another user" for versions opened from Discover (no owner name cached).
- A public version opened from Discover is removed by the next sync unless it is in reach (repertoire/setlists).

## From 010: song linking
- Attaching a version to a song id reveals that song's title/artist/creator (relaxed `song_versions` insert
  policy), and `move_version_to_song` tells whether a song id exists. Safe only while song ids stay unguessable
  and reach only people who can already see the song; revisit if ids are ever exposed more widely.
- Songs created by `find_or_create_song` whose first version push then fails stay as empty songs (reused on
  retry by the same key; no cleanup job).
- The song editor overflows below ~480 px (claimed pre-existing, not re-checked at base).
- Version pushes through `find_or_create_song`, move and rename collision are covered only by the integration
  suite.

## Ops
- After a Docker Desktop restart the local stack can come back without `supabase_auth_Battuta`; `supabase status` then has no keys and every integration test is skipped. Fix: `supabase stop && supabase start`.
