---
status: done
commit: "feat(sharing): link every version to one song and remove merge"
base_sha: ee9f1c6
rounds: 1 of 3 (+ main-session fixes)
---
# 010: Every version belongs to a song: match at creation, move instead of merge

**Goal:** the user's model, like LaCuerda. A song is the work (title + artist), and each person's version is
its own full sheet (lyrics + chords), always linked to one song. Songs are matched at creation, a misattached
version can be moved, and merge is removed.

> The migration, its pgTAP file and the integration tests were written and desk-checked but **not run**
> (Docker down): see "Verify first" in `.pipeline/backlog.md`. The adversary's one major (a pgTAP step run
> without a signed-in user) was fixed by the main session afterwards, together with three cheap minors.

## What changed
- **Server** (`supabase/migrations/20261111000100_song_linking.sql`, earlier migrations untouched):
  - `songs.normalized_key` is set by trigger: lower-case, accent-free, punctuation stripped, whitespace
    collapsed `title|artist`, and **unique**. Existing exact duplicates are joined onto the oldest song first.
  - `find_or_create_song(title, artist)` (security definer) returns the id of that song across all songs,
    including ones whose versions are private, creating it if missing. It returns only an id.
  - `search_songs` (security invoker) only returns songs the caller can see, with visible version counts.
    It uses accent/case-insensitive prefix plus trigram similarity.
  - `move_version_to_song(version_id, song_id)` is owner-only.
  - A trigger deletes a song once its last version is deleted or moved away, and tolerates a concurrent
    attach.
  - Renaming a song onto another song's name raises `song_exists`.
  - The `song_versions` insert policy no longer requires seeing the song, so a version can join a song whose
    other versions are private.
  - **Merge removed:** `song_merge_requests`, the merge RPCs, `merged_into_id`, `resolve_song` and its trigger,
    and old merge notifications. `can_see_song`, `can_view_profile` and `fork_song_version` are redefined
    without merge.
  - pgTAP: new `10_song_linking.test.sql`; merge assertions removed or adapted in `01`, `06` and `08`. The
    README is updated.
- **App:**
  - **Suggestions while typing:** a `SongSuggestionsPanel` in the editor for new songs, and a
    `linkSongBeforeSave` sheet for scan and URL import. They search the device cache plus `search_songs`
    online, with a cache-only fallback offline. Picking a song fixes title and artist to it; otherwise the
    panel marks "New song" as the current choice. Batch text and backup imports rely on the server dedupe.
  - **Move to another song:** owner only, from the viewer and the editor. It is queued locally (Drift v5
    `moveDirty`) and applied by the next sync, with a fallback if the target song is gone.
  - **Sync:** a version without a linked song is pushed through `find_or_create_song`, so no random song ids.
    A rename that collides with another song adopts the real name.
  - **Merge removed** from screens, routes, the inbox, providers, strings (en and es), error codes,
    notification types and sync. Stray rows map to `NotificationType.unknown`.
  - **009 fixes:**
    - A viewer whose version a sync removed shows "This version is no longer available".
    - Versions opened from Discover or Other versions stay cached until the viewer closes.
    - Once the fork RPC has returned, no local copy is made.

## Decisions
- `find_or_create_song` matches across private songs so two people never create duplicates. It only confirms
  that a song with exactly the typed title and artist exists.
- Attaching a version to a song id lets you read that song's title and artist. This relies on song ids being
  unguessable UUIDs that only reach people who can already see the song (documented in the backlog).
- Moves are always queued and applied on sync, even online. The creator of a song can move their own version
  too.

## Deferred
See `.pipeline/backlog.md` (010 section and "Verify first").

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1099 passed (integration files skipped). SQL desk-checked only.
