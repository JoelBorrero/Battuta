---
status: done
commit: 3095947
base_sha: 4827802
rounds: 2 of 3
---
# 001: Harden chord transposition

**Goal:** transposing a song must never corrupt or drop chord information.

## What changed
- **Custom chords keep their full name.** `Cmaj7#11` +2 → `Dmaj7#11`; `C7sus4/G` +2 → `D7sus4/A`. Root and
  bass move, the suffix is kept. Lowercase input (`cmaj7#11`) comes out with an uppercase root.
- **Labels that are not chords are left alone.** A custom label that does not start with its root (`N.C.`,
  `Riff`) is returned completely unchanged: root, bass and label.
- **Free-form song keys move with the chords.** `"D minor"` +2 → `"E minor"`. Keys that cannot be read
  (empty, `garbage`) stay as they are.

## Already correct, now covered by tests
- Enharmonic roots `Fb`, `E#`, `Cb`, `B#`.
- Negative and large shifts (−1, −13, +25).
- Section tags (`[Intro]`, `[Chorus]`, `[x2]`, `[Verse 1]`, `[am]`, `[en]`) stay as they are; real chords on
  the same line are transposed.
- Round trip: +N then −N returns the original chords (sharp-only and flat-only songs).

## Decisions
- All changes live in `lib/features/repertoire/domain/services/song_transposer.dart`. No UI, entity or
  `ChordCell` JSON changes; `musical_key.dart` untouched.
- Free-form key handling is a private helper in the transposer (`_transposeLooseKey`), handling only
  `m`/`min`/`minor`/`maj`/`major` suffixes, not a change to `MusicalKey`.

## Deferred
- Sharp/flat spelling on free-form keys: `b minor` +2 → `Db minor` instead of `C# minor` (comes from the
  existing "key contains `b` means flats" rule).
- Hand-built labels that only look like they start with the root (`Cat` with root `C` → `Dat`). The parser
  and importers cannot produce these.
- Chords with two slashes (`C7sus4/Bb/D`): already broken before this task, out of scope.

## Verification
`flutter analyze`: 0 issues. `flutter test`: 487 passed.
