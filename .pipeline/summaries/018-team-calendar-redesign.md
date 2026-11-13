---
status: done
commit: (this commit)
base_sha: 2889d4a
rounds: 2 of 3
---
# 018: Team roster and band calendar redesign

**Goal:** Team matches the "Battuta Screens" roster and band calendar mockups, keeping every scheduling feature.

## What changed
- **Team page.** `StageAppBar.large("Team")`, organization switcher under the header, Roster / Calendar
  `StageSegmentedControl`; admins get an invite icon (roster) and an icon-only "new service" FAB (calendar).
- **Roster.** Filter pills, then one grouped card of member rows: initials or photo avatar (amber ring for
  you), name, "(You)", ADMIN outline badge, instruments line, bands line, notes, ⋮ with the member actions.
  Manage bands and recurring schedules are 44 pt icon buttons with tooltips.
- **Calendar.** `month_grid.dart`: month card with ‹ › navigation, locale week start, 44 pt tall cells, amber
  selected day, ringed today, dots on days with services (real and projected recurring). Below it: my
  absences, the admin alerts banner and every service under date headers. Tapping a day scrolls to its
  header (the list is built eagerly, so any day is reachable) or shows "No services on this day."
- **Selection.** Until the user picks a day or browses months, the selection follows today from
  `calendarClockProvider`; a pick stays across rebuilds and month browsing.
- **Service cards.** Time column, title, band, type, next-service highlight, lineup and assignments.
- **Shared.** `StageFilterPill` labels ellipsize instead of overflowing (long band names at 320 pt).

## Decisions
- Selecting a day scrolls, it doesn't filter, so every service stays visible.
- The roster stats card, `@username` and per-member band badges are dropped, following the mockup; no action is
  lost and bands remain as a text line.
- Day cells are ~40 pt wide at 320 pt (7 columns cannot reach 44 pt); 44 pt tall.

## Deferred
- "Follows today" moves at the next rebuild after midnight, not exactly at midnight (backlog).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1322 passed, 9 skipped, 1 known date-dependent failure.
