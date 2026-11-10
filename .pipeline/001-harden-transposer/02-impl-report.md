---
status: ready-for-review
round: 1
---
# Implementation report

## Done (map to acceptance criteria)
- [x] Defect 1 (custom chord loses suffix): CONFIRMED (test failed: got `D`). Fixed in `SongTransposer.transposeChord`, which now rebuilds the custom label as newRoot + original suffix + `/newBass`. `Cmaj7#11` +2 -> `Dmaj7#11`.
- [x] Defect 2 (custom slash chord): CONFIRMED (got `D/A`). Fixed by the same change. `C7sus4/G` +2 -> `D7sus4/A`.
- [x] Defect 3 (enharmonic Fb/E#/Cb/B#): did NOT reproduce. Tests added and pass without a fix.
- [x] Defect 4 (negative/large semitones): did NOT reproduce. Tests added and pass.
- [x] Defect 5 (non-chord bracket tags): did NOT reproduce. `[Intro] [Chorus] [x2] [Verse 1] [Bridge] [am] [en]` untouched, `[Am] [Em]` transposed. Test added.
- [x] Defect 6 (transposeSong unparseable key): no throw reproduced. `am` and `Dm` parse. But `"D minor"` stayed `"D minor"` while the chords moved, which is an inconsistent key. CONFIRMED and fixed with a new private `_transposeLooseKey` fallback (root plus m/min/minor/maj/major). `''` and `'garbage'` stay unchanged. Round-trip tests (sharp-only and flat-only, N in 1,2,5,7,11) pass without a fix.
- [x] Edge cases: lowercase custom root `cmaj7#11` -> `Dmaj7#11` (confirmed failing before, fixed). `C/9` does not throw, giving `D/9` (passes already).
- [x] Existing tests unchanged; only a new group `SongTransposer hardening` was added.

## Deviations from plan (and why)
- Added `_transposeLooseKey` for `"D minor"`-style keys. This is the "sensible key string" part of defect 6 and stays inside `song_transposer.dart`. `musical_key.dart` is untouched.

## Commands run and results
- Before fix, `flutter test test/features/repertoire/domain/services/song_transposer_test.dart`: 5 new tests failed (custom suffix, custom slash, custom ChordCell label, lowercase custom root, loose key).
- `flutter test test/features/repertoire/domain/services/`: all 28 pass.
- `flutter analyze`: No issues found.
- `flutter test`: 486 tests, all passed.
- `dart format` was run on the two touched files.

## Known gaps / doubts
- The custom-label rebuild assumes the label begins with the chord's root. The parser guarantees this, but a hand-built `ChordCell` with a mismatched `customLabel` would produce a wrong suffix.
- `_transposeLooseKey` only handles the m/min/minor/maj/major suffixes. Other free-form keys are left unchanged.
- Nothing committed. No branches were created.

# Round 2

## Done
- [x] `SongTransposer.transposeChord` now returns the cell completely unchanged (root, bass and label) when it is a custom chord whose `customLabel` does not start with `chord.root` (case-insensitive). Examples are `N.C.` and `Riff`. Suffix rebuilding is unchanged for labels that do start with the root.
- [x] Added test `custom label not starting with root is left unchanged` (`N.C.` and `Riff`, root `C`, +2). `Cmaj7#11` and `C7sus4/G` tests still pass.

## Commands run and results
- `flutter analyze`: see below
- `flutter test`: see below

## Known gaps
- Nothing committed. Deferred minors and nits from triage are untouched.
