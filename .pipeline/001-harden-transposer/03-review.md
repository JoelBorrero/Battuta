---
verdict: APPROVE
round: 2
---
# Adversarial review (round 2)

## Verified independently
- `flutter analyze`: No issues found.
- `flutter test`: 487 tests, all passed.
- Diff vs base_sha touches only `song_transposer.dart` and its test file (AGENTS.md was already dirty before the task). No source edited by me; probes were throwaway scripts in the scratchpad.

## Round 1 findings
- [major] Non-root-prefixed custom labels corrupted (`N.C.` -> `D.C.`): RESOLVED. Guard at the top of `transposeChord` returns the cell unchanged. Verified `N.C.` (even with `bass: G`) and `Riff` are returned untouched; tests added at test file line ~140.
- [minor] Loose-key sharp/flat preference (`b minor` -> `Db minor`, `D minor`+1 -> `D# minor`): DEFERRED, unchanged, not blocking.
- [nit] case-insensitive accidental in loose regex (`DB minor`), and zero-semitone lowercase label: DEFERRED.

## Attack on the new fix
- Regression check holds: `Cmaj7#11`+2 -> `Dmaj7#11`, `C7sus4/G`+2 -> `D7sus4/A`, `cmaj7#11` -> `Dmaj7#11`, `bbmaj7#11` (root Bb) -> `Cmaj7#11`, hand-built label `cmaj7` with root C -> `Dmaj7`.
- Partial-root matches: the guard is only a case-insensitive prefix test, so a hand-built cell with root `C` and label `Cb`, `C#`, `Cat` or `Cx` passes it and is rewritten (`Cb` -> `Db`, `C#` -> `D#`, `Cat` -> `Dat`). Root `C#` with label `Csus` fails the prefix and is left unchanged (safe). Reachability: the parser and the Cifra importer always take the longest `[A-G][#b]?` as the root, so `Cb`/`C#` with root `C` cannot be produced by them. `Cat`-style words starting with A-G can come from the importer (root `C`, suffix `at`), but those are not chords in the first place. Result is a nit, not a defect with a realistic repro.
- Case mismatch: handled by lowercasing both sides; the rebuilt label uses the new upper-case root.
- Bass when label returned unchanged: root and bass are both left untransposed (`N.C.` with bass G stays root C, bass G), which is consistent and arguably correct for non-pitched labels.

## Findings
### [nit] Prefix guard accepts partial-root matches
- Where: `song_transposer.dart:93-101`
- Scenario: hand-built `ChordCell(root: 'C', quality: custom, customLabel: 'Cat')` +2 -> `Dat`.
- Suggested fix (optional): additionally require the character after the root not to be `#` or `b` when the root has no accidental, or require a valid suffix via `ChordParser`'s suffix regex.

Verdict: APPROVE (no blockers or majors).
