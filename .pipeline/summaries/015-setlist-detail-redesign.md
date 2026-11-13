---
status: done
commit: (this commit)
base_sha: 45a1209
rounds: 1 of 3
---
# 015: Setlist detail redesign

**Goal:** Setlist detail matches the "Battuta Screens" mockup while keeping every setlist feature.

## What changed
- **Header.** "Setlist" with + (`setlist_add_songs`) and ⋮ (`setlist_menu`: edit info, delete); both hidden
  for read-only setlists.
- **Title block.** Shared `SetlistDateStamp` (month / day) beside a 24/800 title and the description line.
- **Stats.** Songs and Avg BPM (tempo override wins; missing / 0 BPM excluded; "–" when none).
- **Order card.** "Order" + "Drag to reorder"; one bordered card of rows: mono number, title (2 lines), meta
  "artist · N BPM" (2 lines), note line, key pill (override if set), remove (44 pt) and drag handle (44 pt).
  The page scrolls as one `SliverReorderableList`; read-only rows cannot be dragged.
- **States.** `StageEmptyState` ("Tap + to add songs and build your set."), deleted-song rows from the
  snapshot, read-only notice as a bottom bar.
- **Shared widgets.** `setlist_date_stamp.dart` (also used by the repertoire list), `setlist_item_row.dart`,
  `add_songs_to_setlist_sheet.dart` (restyled, same behaviour).

## Already correct, now covered by tests
- Reorder persists without off-by-one when moving an item down.
- `eventDate` is an instant (synced as UTC, read back local); the stamp shows the device-local day, also when
  run with `TZ=America/Los_Angeles`.

## Decisions
- No "Start live session" bar until Live can open a setlist (backlog: Live performance view).
- The per-row remove button stays although the mockup has none.

## Deferred
- The stamp shows month and day only; the old chip also showed the year (backlog).
- If a future date picker stores a calendar day as UTC midnight, `toLocal()` would show the previous day west
  of UTC (backlog).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1277 passed, 9 skipped, 1 known date-dependent failure.
