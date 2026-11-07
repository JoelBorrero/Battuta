# Step Spec: TASK-103 A/B Practice Loop Engine & Local Stem Storage Manager

## Exact Files to Create / Modify
- `lib/features/audio/domain/models/ab_loop_region.dart` (Create)
- `lib/features/audio/data/local_stem_storage_service.dart` (Create)
- `lib/features/audio/presentation/providers/audio_practice_controller.dart` (Modify)
- `lib/features/audio/presentation/widgets/practice_player_bar.dart` (Modify)
- `test/features/audio/ab_loop_and_stems_test.dart` (Create)

## Domain & Data Architecture
- `AbLoopRegion`:
  - `startMicros`, `endMicros`, `fadeWindowMicros` (sub-millisecond precision).
  - Validation: `startMicros < endMicros`, minimum duration guard (e.g. >= 100,000 micros / 100ms).
  - Fade calculation: `calculateFadeCoefficients(int sampleCount)`.
- `StemTrack` & `LocalStemStorageService`:
  - `StemTrack(id, name, relativePath, volume, isMuted, isSolo)`.
  - `LocalStemStorageService({required Directory Function() baseDirResolver})` allowing in-memory/temp testing.
  - JSON persistence per song (`stems_<songId>.json`).
- `AudioPracticeController`:
  - Add `loopPointA`, `loopPointB`, `setLoopPointA()`, `setLoopPointB()`, `clearAbLoop()`.
  - Loop boundary enforcement during playback scrubbing/advancement.
- `PracticePlayerBar`:
  - A/B Loop action bar with buttons for "A", "B", and "Clear".
  - Active buttons highlighted in `#E5A93C` amber.
  - Touch targets >= 44x44pt; elevation: 0.

## Tests
- `AbLoopRegion` boundary validation and click-free fade calculation tests.
- `LocalStemStorageService` multi-stem registration, retrieval, and isolation tests using temp directory.
- `PracticePlayerBar` A/B loop UI toggle and amber styling widget tests.
