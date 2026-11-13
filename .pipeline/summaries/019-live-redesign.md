---
status: done
commit: (this commit)
base_sha: ce2aaf3
rounds: 1 of 3
---
# 019: Live session header and section chips

**Goal:** Restyle the existing Live page to the "Battuta Screens" mockup without building the performance view.

## What changed
- **Header.** LIVE badge (`StageStatusPill`, pings once when the session connects, muted when standalone) with
  the HOSTING / SYNCED / STANDALONE state, and End (`live_end_button`) while connected. End asks for
  confirmation ("End the live session?"), then calls the existing `disconnect()`.
- **Section chips.** `DirectorControlBar.queuedSectionId`: active solid amber, queued amber outline with
  "· NEXT", others muted; uppercase.
- **Cue banner.** Brand roles; a one-shot arrival flare per new cue (keyed by sequence number), instant under
  Reduce Motion.
- **Page.** Director / Follower as `StageSegmentedControl`, cards as `StageCard`, stop / disconnect in a
  danger-wash style; no `Colors.grey` / `Colors.white` left.
- **Tests.** The Live page tests use the fake wake lock (they reached the real plugin before).

## Decisions
- End reuses `disconnect()` (stop hosting / leave); no new session-ending behaviour. It duplicates
  "Stop Host Server" / "Disconnect" for now; the performance view will settle one control.
- The queued outline is solid, not dashed.

## Deferred
- A cue's free-text label never matches a section, so cues never light a chip (backlog).
- Active section and queued label are not cleared on disconnect (pre-existing; backlog).
- Active chip matching is case-sensitive, queued is case-insensitive (backlog).
- The End test uses a real loopback socket with fixed delays (backlog).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1328 passed, 9 skipped, 1 known date-dependent failure.
