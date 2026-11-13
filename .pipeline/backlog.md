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

## From 011: profile view
- Admins cannot leave an organization from the app (they must give up admin rights first); the old roster
  self-card Leave item is gone. Revisit if admins should leave while another admin remains.
- Formatting churn: `test/features/auth/supabase_auth_repository_test.dart` was reflowed by `dart format`
  together with the new tests.

## From 012: profile photos
- Not tried on a device: "Take photo" (camera) and iOS. Choose → crop → save / replace / remove and the logo
  were verified on Android.
- A session whose user no longer exists (e.g. after `supabase db reset`) stays "signed in": the profile says
  "connect to the internet" instead of signing out. Treat a missing profile for a signed-in user as signed out.
- "Versions" on My profile counts local-mode songs too, so a brand-new account shows the device's songs.
- Scanner crop never runs: `cropStaffSnippet` passes `XFile.fromData(...).path` (not a real file), so the
  cropper throws and the blanket catch returns the original bytes. Write the bytes to a temp file first.
- Invite / Manage / See all / Next up on a non-active organization silently switch the active organization;
  pass the organization id to those sheets, or tell the user with a snackbar.
- A deactivated user's old photo object stays in Storage (unlinked, unguessable path); needs a server-side
  cleanup job (with the email scrub from 002).
- The logo folder check accepts any uuid text form (uppercase, braced), only under the admin's own
  organization.
- "Upcoming" counts only the active organization while the other tiles count across organizations.
- A member demoted while the logo sheet is open sees the generic permission message, not "not admin".

## From 013: repertoire redesign
- The Repertoire ⋮ menu labels are hard-coded English ('More options', 'Import Song / Leadsheet',
  'Export Repertoire...'); move them to l10n.
  Same for the Song detail ⋮ export labels (ChordPro / JSON copy, PDF / MIDI export).
- `song_import_modal.dart` still has a `Color(0x222E86DE)` literal; replace with a brand role.
- Wide windows lost the one-tap import / scan icons (now in the ⋮ menu); show them in the search row at
  ≥ 480 pt if users miss them.
- Live performance view (song N of M, beat meter, lyric prompter, Previous / Cue / Next) is planned as its
  own task after the redesign series; it needs new session state (see 019). `LiveSessionPage` today is a
  static demo with a hard-coded song (`way-maker`). When Live can open a given song / setlist, add the
  mockups' "Go live" (Song detail, primary in the action bar) and "Start live session" (Setlist detail).
  Both were left out of 014/015 so no button promises something it can't do.

## From 015: setlist detail redesign
- The setlist date stamp shows month / day only (the old chip showed m/d/yyyy). Show the year when it is not
  the current year, in the stamp or the meta line.
- `eventDate` is shown with `toLocal()`. If a date picker is added that stores a calendar day as UTC
  midnight, store it as local noon or a date-only value, or users west of UTC see the previous day.
- Removing a song from a setlist has no confirmation or undo; consider an undo snackbar.

## From 016: settings redesign
- Settings → Server shows "Configure Project URL & Anon Key" instead of the active server. The host is
  available through `SupabaseConfigService.getActiveUrl()` (`supabaseConfigServiceProvider`); add a small
  `FutureProvider` and show the host (or "Battuta cloud" for the default).
- No widget test covers the sync status card states (ready, syncing, last synced at, offline, error).
- The footer's "♪" (U+266A) relies on the platform font; consider an inline icon.

## From 017: stage preferences
- Chart text size and prefer flats have no Live consumer yet (Live renders no chart); wire them into the Live
  performance view.
- `ScreenWakeLock` is not reference-counted: if `/live/:sessionId` is ever pushed over `/live`, popping it
  releases the lock while Live is still showing. Count holders when that route gets used.
- Settings sync status card overflows (~13 px) at 320 pt with 160% system text scale (pre-existing).
- Stage preference reads run one after another; `Future.wait` would load them together.

## From 018: team and calendar redesign
- The calendar's "follows today" selection moves at the next rebuild after midnight; add a midnight timer (or
  rebuild on app resume) if the app is often left open overnight.

## From 019: live redesign
- Cues never light the "· NEXT" chip: `SyncCuePayload` carries only a free-text label ("NEXT: CORO GLORIOSO"),
  never a section id. Add a section id to the cue payload and match on it.
- `activeSectionId` / `queuedSectionLabel` are not cleared on disconnect, so a stale chip state shows after End.
- Active chip matches case-sensitively, queued chip case-insensitively; use one rule.
- End duplicates "Stop Host Server" / "Disconnect"; keep one when the performance view lands.
- The Live End test binds a real loopback socket with fixed 100 ms delays; poll for the state (or fake the
  `LanWebSocketSyncService`) to avoid CI flakiness.

## From 020: editor and scanner layout
- Song editor tap-tempo beat dots stay lit while idle (pruning runs only on the next tap), contradicting the
  "wait 3 seconds to start over" hint; prune with a timer.
- Tag and chord `Chip` delete icons in the song editor are well under 44 pt.
- Tap tempo calls `DateTime.now()` directly; add a clock seam so the test can assert the exact BPM.
- The editor's Duplicate and Copy-from section icons look alike.
