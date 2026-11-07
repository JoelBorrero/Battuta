# Step Spec: TASK-105 Syllable-to-Note Lyric Alignment Engine

## Exact Files to Create / Modify
- `lib/features/score/domain/services/lyric_syllable_tokenizer.dart` (Create)
- `lib/features/score/presentation/rendering/notehead_painter.dart` (Modify - lyric positioning below bottom ledger boundary)
- `test/features/score/lyric_syllable_alignment_test.dart` (Create)

## Domain Architecture
- `LyricSyllableTokenizer`:
  - `tokenize(String rawLyrics, {bool handleSinalefa = true}) -> List<String>`
    - Parses words, preserves intra-word hyphens (`"Glo-"`, `"Se-"`).
    - Detects synalepha (sinalefa / vowel elision across word boundaries: `"ria"` + `"al"` -> `"ria al"`).
    - Supports explicit tilde/underscore elisions (`"ria~al"` or `"ria_al"`).
  - `alignLyricsToMeasure(Measure measure, String rawLyrics, {bool handleSinalefa = true}) -> Measure`
    - Maps syllables 1:1 to sounding (non-rest) notes.
    - Preserves musical rests without syllables.
  - `alignLyricsToNotes(List<NoteEvent> events, String rawLyrics) -> List<NoteEvent>`

## Presentation Enhancements
- `NoteheadPainter.paintMeasureNotes`:
  - Compute lowest notehead/ledger line Y in the measure:
    `math.max(staffBottomY + 14.0, lowestBoundaryY + 10.0)`
  - Render aligned lyric syllables centered below each notehead X-coordinate, cleanly below the staff bottom ledger boundary.

## Tests
- Tokenizer splits standard hyphenated words (`"A-la-ba-ré"` -> `["A-", "la-", "ba-", "ré"]`).
- Tokenizer handles Spanish/Italian synalepha/elision (`"Glo-ria al Se-ñor"` -> `["Glo-", "ria al", "Se-", "ñor"]`).
- Tokenizer handles explicit elisions with `~` or `_`.
- 1:1 alignment against measure with mixed notes and rests: rests skipped, notes assigned syllables.
- Presentation / Widget test verifying lyrics render centered below noteheads without error.
