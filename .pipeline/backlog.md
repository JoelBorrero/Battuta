# Pipeline backlog

Deferred findings that must not be forgotten. When a task closes, add anything it deferred here; when an
item is fixed, delete it (the fixing task's summary records it).

## From 001: harden transposer
- Sharp/flat spelling on free-form keys: `b minor` +2 → `Db minor` instead of `C# minor`.
- Hand-built custom labels that only look root-prefixed (`Cat` with root `C` → `Dat`).
- Chords with two slashes (`C7sus4/Bb/D`).

## From 002: Supabase schema
Planned into a later slice:
- **004:** existing local setlists still use their old ids; give them UUIDs when they sync.
- Deactivated users' email stays in `auth.users` (needs a server-side scrub job).
- **005:** archive has no undo; say so in the archive confirmation UI.
- **006:** declined users can be re-invited repeatedly; removed members can rejoin with a still-valid link.
- **006:** merge-request spam: anyone who can see a song can keep sending its creator merge requests
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
- **005:** start `OrganizationsSyncCoordinator` and the providers; Team page still on the in-memory roster.
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
- **007:** wire `canAdministerOrganization` (today even admins get `not_admin` from the setlist repository).
- **008:** title/artist edits on a version whose song was created by someone else are reverted by sync; needs a
  UI rule (edit only your own song's title, or propose a merge).
- **008:** `updateSharing` exists only on `DriftSongRepository`, not on the `SongRepository` interface.
- Sharing changes (label, visibility, shares) have no edit time: the device that syncs last wins.
- A refused share after a successful visibility update leaves the version `organizations` with only the
  accepted shares (no rollback).
- Organization setlists: an admin can set a far-future `edited_at` and always win over other admins (clamp on
  the server).
- A client can record fork lineage from any visible version without the `song_version_forked` notification
  (only `fork_song_version` notifies).
- Integration test "making a version private removes it from the member" failed once (not reproduced in 8
  runs): possible flake.
