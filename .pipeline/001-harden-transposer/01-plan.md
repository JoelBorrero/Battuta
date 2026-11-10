---
status: approved
base_sha: 4827802edf7734a55244d40eed7970685fc89b29
round: 1
---
# Harden chord transposition (SongTransposer / ChordParser)

## Goal
Transposing songs must never corrupt or silently drop chord information. Fix the cases below
and lock them in with tests.

## Suspected defects (to confirm with a failing test FIRST)
1. **Custom chords lose their suffix.** `ChordParser.parseChord('Cmaj7#11')` yields
   `ChordQuality.custom` with `customLabel = token`. `transposeChord` then does
   `copyWith(root: newRoot, customLabel: null)`, so `displayLabel` falls back to
   `root + quality.symbol` and the suffix is lost (verify what `ChordQuality.custom.symbol` is).
   Expected: `transposeChordString('Cmaj7#11', 2)` → `Dmaj7#11`.
2. **Custom chord with slash bass**, e.g. `C7sus4/G`, must transpose root and bass and keep the suffix.
3. **Enharmonic/accidental handling** for `Fb`, `E#`, `Cb`, `B#` roots and flat keys: result uses the
   target key's sharp/flat preference consistently (`preferSharps`).
4. **Negative and large semitones** (`-1`, `-13`, `25`) wrap correctly.
5. **Non-chord bracket tags** (`[Intro]`, `[Chorus]`, `[x2]`, `[Verse 1]`, `[Em]` vs lowercase word `[am]`/`[en]`)
   are left untouched; real chords in the same line are transposed.
6. **`transposeSong`** with an unparseable `song.key` (e.g. empty, "Dm" vs "D minor", lowercase "am") does not throw
   and keeps a sensible key string. Round-trip: transposing +N then −N returns original chords for sharp-only and
   flat-only songs.

If any suspected defect does NOT reproduce, say so in the impl report and skip it (do not invent a fix).

## Non-goals
- No UI changes, no new dependencies, no change to `ChordCell` JSON shape or the freezed/generated files.
- No changes to the song text parser or scrapers.

## Acceptance criteria (testable)
- [ ] Each confirmed defect has a test that failed before the fix and passes after.
- [ ] Defect 1 and 2 examples above produce the expected strings.
- [ ] Existing `song_transposer_test.dart` tests still pass unchanged (only additions allowed there).
- [ ] `flutter analyze` → 0 issues; `flutter test` → 100% pass.

## Files in scope
- `lib/features/repertoire/domain/services/song_transposer.dart` (fixes)
- `test/features/repertoire/domain/services/song_transposer_test.dart` (new tests)
- `lib/features/repertoire/domain/entities/musical_key.dart` only if a defect is proven to originate there

## Steps
1. Read `song_transposer.dart`, `chord_cell.dart`, `chord_quality.dart`, `musical_key.dart`, and the existing test file.
2. Add failing tests for each suspected defect; run them and record which fail.
3. Fix minimal code per confirmed defect.
4. Re-run targeted tests, then analyze and full suite.

## Edge cases to handle
- Custom label whose root differs in case (`am7b5` style input) → root normalised upper-case.
- Slash chord with non-note bass (`C/9`?): leave untouched rather than throw.

## Verify
- `flutter test test/features/repertoire/domain/services/`
- `flutter analyze` → 0 issues
- `flutter test` → 100% pass
