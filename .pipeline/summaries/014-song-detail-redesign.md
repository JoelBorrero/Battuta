---
status: done
commit: (this commit)
base_sha: 69e217a
rounds: 2 of 3
---
# 014: Song detail redesign

**Goal:** Song detail matches the "Battuta Screens" mockup, with an inline transpose preview and a bottom action.

## What changed
- **Header.** "Song" with an edit button (owners) and a ⋮ menu (`song_menu`): Transpose & save, Notation
  editor, ChordPro / JSON copy, PDF / MIDI export, Delete. Read-only shared songs hide edit and delete.
- **Title block.** 26/800 title, "artist · Original: key (BPM)" line, `StageStatRow` with Key (mono, amber,
  animated), BPM and Time.
- **Transpose stepper.** −, signed value, + (44 pt). Previews key, chart, stats and exports without saving;
  tapping the value resets; past ±11 wraps to 0. "Transpose & save" stores exactly what is previewed.
  While a preview is active the chart's Align Chords buttons are hidden, so alignment edits can never save a
  transposed song or be silently dropped.
- **Below.** Sharing (owners) / Fork to my library (non-owners and local-mode songs), practice audio (aligned
  with the other cards), tags, notes and view-mode `StageFilterPill`s.
- **Add to setlist.** Full-width primary action opening a sheet of setlists: "Already added" state, empty
  state; personal setlists when the song is in my library, organization setlists for admins when the song is
  in that repertoire.
- **Design system.** Segmented control 52 pt (44 pt segment hit area); `StageFilterPill` 36 pt with a 44 pt
  hit area; `StageLargeTitle` steps 28 → 22 pt before ellipsizing, so "Repertoire" fits at 320 pt. The
  repertoire scope pill is start-aligned and only its own 44 pt box is tappable. Docs updated.

## Already correct, now covered by tests
- The preview no longer double-transposes the chart (the page passes the transposed song with 0 semitones).

## Decisions
- No "Go live" button: `LiveSessionPage` is a static demo with a hard-coded song and cannot open a given song.
  Added back with the Live performance view (backlog).
- `practice_player_bar.dart` action row is a `Wrap` (it overflowed 25 px at 320 pt).

## Deferred
- ⋮ menu export labels are English-only (backlog, with the 013 menu labels).
- Formatting churn: `dart format` reflowed untouched lines in `chord_lyrics_view.dart` and its test.

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1270 passed, 9 skipped, 1 known date-dependent failure.
