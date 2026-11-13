---
status: done
commit: (this commit)
base_sha: 5386337
rounds: 1 of 3
---
# 020: Song editor and scanner layout

**Goal:** Lay out the song editor and scanner to the "Battuta Screens" mockups without changing their behaviour.

## What changed
- **Editor.** Design-system layout with every field, tool, validator and key kept: title and artist, a
  "Musical setup" group (key and meter side by side), a tap-tempo card (round TAP button
  `song_tap_tempo_button`, beat dots, − / + stepper), tags, notes, and the section list.
- **Sections.** `song_editor_section_card.dart` (moved out of the page, renamed `EditableSection`): each
  section is a card with an uppercase amber label, repeat − / +, and 44 pt tools (move, duplicate, copy
  from, delete). Controllers are still created and disposed once by the page; cards keep `ValueKey(id)`.
- **Save.** 44 pt tall.
- **Scanner.** Viewfinder illustration, heading copy and two action tiles (`open_camera_button`,
  `choose_gallery_button`) calling the same handlers. The scan flow code is unchanged.
- **Strings.** New en + es strings for the tiles, tap tempo and chord entry hint.

## Decisions
- Kept from today's editor rather than the mockup: dropdowns / stepper for key, meter and BPM; expanded
  sections; separate chord and lyric fields; visible section tools instead of a menu.
- Scanner: no "Recent scans", no credit line and no "you review every section" copy (no data or flow for them).

## Deferred
- Tap-tempo beat dots stay lit while idle until the next tap (backlog).
- Tag / chord chip delete icons are under 44 pt (pre-existing; backlog).
- The tap-tempo test only checks the BPM changed; there is no clock seam (backlog).
- Scanner crop path stays broken (backlog from 012).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1332 passed, 9 skipped, 1 known date-dependent failure.
