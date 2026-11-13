---
status: done
commit: (this commit)
base_sha: 95edad1
rounds: 1 of 3
---
# 013: Repertoire redesign

**Goal:** Lay out the Repertoire tab like the "Battuta Screens" mockup while keeping every feature.

## What changed
- **Header.** `StageAppBar.large("Repertoire")` with Discover (icon, key `discover_chip`), Inbox and the
  profile avatar.
- **Scope picker.** A pill (logo tile, name, chevron) opening a sheet with My library (`scope_mine`) and each
  organization (`scope_org_<id>`); organization settings sit next to it.
- **Search row.** A 46 pt inline field ("Search title, artist or tag", en + es) opening the existing search,
  followed by the sync icon and the ⋮ import/export menu.
- **Songs / Setlists.** `StageSegmentedControl` with counts.
- **Song rows.** Title, muted "artist · BPM · meter" line (meter hidden for 4/4, missing parts skipped),
  `StageKeyPill`; organization rows use the same layout.
- **Setlist rows.** Month/day date stamp from `eventDate`, or a neutral list tile when there is none.
- **Add.** Icon-only FAB. The add/import sheet uses brand roles instead of 4 hex literals and `Colors.purple`.
- **Scrolling.** Header, picker, search and list are one scroll view (`OrgRepertoireView` builds a sliver),
  which fixes the 52 px overflow at 320–375 × 700 with an organization repertoire (backlog item from 011).

## Decisions
- Search hint says "tag", not the mockup's "key": search does not match keys.
- Sync and organization settings moved out of the app bar so the header fits 320 pt.
- The Songs/Setlists cross-fade is gone: the content is now slivers.
- On wide windows, import and scan are reached through the ⋮ menu (no separate icons).

## Deferred
- To 014: title scales down instead of ellipsizing at 320 pt; ≥ 44 pt hit areas for segments and the scope pill.
- To 015: confirm the date stamp shows the same day in every time zone.
- Backlog: English-only labels in the ⋮ menu; `song_import_modal.dart` still has one `Color(0x222E86DE)`.

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1250 passed, 9 skipped, 1 known date-dependent failure
("Calendar as a member adds, edits and deletes an absence").
