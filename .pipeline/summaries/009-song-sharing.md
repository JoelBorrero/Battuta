---
status: done
commit: "feat(sharing): add version sharing, other versions, fork and Discover"
base_sha: de1bdb5
rounds: 1 of 3
---
# 009: Song sharing: visibility, shares, versions, fork and public songs

**Goal:** owners control who sees each version, everyone can browse a song's versions and fork one into
their own library, and public songs can be discovered.

> Run unattended under the user's delegation. The adversary approved round 1 with no blockers or majors.
> The integration suite (53 tests, 6 new) passed for the implementer, but the review could not confirm it
> because Docker hung again: re-run it first (backlog "Verify first").
> **Superseded in part:** after this task the user refined the model. Every version always belongs to a song,
> songs are matched at creation, and merge is removed. Task 010 reworks linking and removes merge.

## What changed (`lib/features/sharing/`)
- **Sharing sheet** (owner only, viewer and editor): label; Private, My organizations (only active,
  non-archived organizations) or Public. Changes go through `updateSharing`, now on the `SongRepository`
  interface; they are marked for sync and work offline.
- **Other versions:** a list of cached and online versions of the same song with no duplicates, plus a song
  page at `/songs/:id`.
- **Fork:**
  - Online it calls `fork_song_version`, which notifies the owner.
  - Offline it makes a local copy that keeps the lineage and the score.
  - The copy opens in the editor.
  - Sync: an offline fork whose parent went private uploads without the lineage, and starts a new song if
    the song became invisible too.
- **Title/artist rule:** only the song's creator edits them. `saveSong` keeps the stored values for anyone
  else, and local-mode songs stay editable. Drift v4 adds `songCreatorId`, with a migration test.
- **Merge requests** (removed again in 010): a merge sheet with a guard against duplicate pending requests,
  an approver page at `/merge-requests/:id`, and accept and decline.
- **Discover** (`/discover`, a chip in the Repertoire scope bar): online search of public versions, load more,
  open read-only and fork; signed-out and offline states.
- **Inbox:** fork and merge notifications open the new screens.
- **Strings:** en and es (902 keys each). Layout tests cover 320–1440 px; the whole viewer is tested from
  360 px because of a pre-existing `PracticePlayerBar` overflow.

## Decisions
- No server schema change.

## Deferred
See `.pipeline/backlog.md` (009 section). Fork and linking issues are planned into 010.

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1089 passed (the adversary re-ran it). Integration: 53 passed in
the implementer's run, **not confirmed by the review** (Docker hung).
