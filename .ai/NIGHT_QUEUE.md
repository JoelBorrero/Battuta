# Battuta Overnight Execution Queue (v1.1 - v1.3 Foundations)

> **ARCHITECTURAL GUARDRAILS FOR OVERNIGHT AGENTS:**
> 1. **DO NOT MODIFY `pubspec.yaml`** unless a task explicitly says `ALLOW_PUBSPEC`. Prefer pure Dart / `dart:io` (`WebSocket`, `RawDatagramSocket`, `File`) to keep the 275 tests deterministic.
> 2. **275 Test Floor**: Every task MUST start at >=275 passing tests and increase the count.
> 3. **Anti-Material Stage UI**: Strictly use `#121316` (Dark), `#F8F9FA` (Light), `#E5A93C` (Amber accent), 1px borders (`#2D3139` / `#E1E4E8`), zero Material elevation, and >=44x44pt touch targets.

---

## [x] TASK-101: v1.1 Local LAN WebSocket LiveSync Implementation & Conflict Resolution
- **Epic**: Epic 1 — Live Stage Synchronization (v1.1)
- **Architectural Decision Locked**: Implement Option B + Hybrid foundation using pure `dart:io` (`HttpServer` + `WebSocketTransformer` for Director host, `WebSocket.connect` for Band Member followers) on top of the existing `lib/features/sync/domain/services/live_sync_service.dart` contract.
- **Scope**:
  1. Create `lib/features/sync/domain/models/sync_cue_payload.dart` (immutable model containing `songId`, `currentSectionId`, `nextSectionLabel` e.g., `"NEXT: CORO"`, `triggerMeasureIndex`, `leaderTimestampMs`, and `sequenceNumber`).
  2. Create `lib/features/sync/data/lan_websocket_sync_service.dart` implementing `LiveSyncService`:
     - Director Mode (`LeaderLock` conflict resolution: only messages from the active Host/Director IP or higher `sequenceNumber` from leader are accepted; follower override attempts are queued as requests).
     - Automatic 2-measure lookahead calculation for the amber `"NEXT: [SECTION]"` cue emission.
  3. Create `test/features/sync/lan_websocket_sync_service_test.dart` using loopback `127.0.0.1` ephemeral ports (`port: 0`) testing Director -> 2 Followers broadcast, leader-lock conflict rejection, and 2-measure lookahead cue timing.

---

## [ ] TASK-102: v1.1 Live Stage Sync Banner & Director Control Bar UI
- **Epic**: Epic 1 — Live Stage Synchronization (v1.1)
- **Scope**:
  1. Create `lib/features/sync/presentation/widgets/stage_cue_banner.dart`:
     - High-contrast Anti-Material banner displaying the incoming cue (e.g., glowing `#E5A93C` amber border + `"NEXT: CORO (in 2 bars)"`).
     - Zero Material elevation, `>= 44x44` pt dismiss/override targets, flexible row layout preventing `RenderFlex` overflow on narrow split-screen iPad views.
  2. Create Riverpod state notifier in `lib/features/sync/presentation/providers/live_sync_provider.dart` wiring `LiveSyncService` streams to UI state.
  3. Create widget tests in `test/features/sync/presentation/stage_cue_banner_test.dart` verifying Dark (`#121316`) and Light (`#F8F9FA`) rendering and zero overflow at `320x600` constraints.

---

## [ ] TASK-103: v1.2 A/B Practice Loop Engine & Local Stem Storage Manager
- **Epic**: Epic 2 — Audio Engine & Stem Playback (v1.2)
- **Architectural Decision Locked**: Implement concrete domain/data controllers for `PitchShiftedAudioPlayer` (`lib/features/audio/`) and local file storage metadata without adding fragile C++ FFI dependencies overnight.
- **Scope**:
  1. Create `lib/features/audio/domain/models/ab_loop_region.dart` enforcing sub-millisecond boundary validation (`startMicros < endMicros`, minimum loop duration guard, zero-crossing fade window calculation to prevent audio click).
  2. Create `lib/features/audio/data/local_stem_storage_service.dart` managing multi-track backing stem file paths per `songId` (e.g., Click, Guide, Keys, Bass, Drums) with an injectable directory provider for in-memory/temp directory testing.
  3. Extend `PracticePlayerBar` (`lib/features/audio/presentation/`) or its controller to support toggling `Loop A`, `Loop B`, and `Clear Loop` with `#E5A93C` amber active states.
  4. Add unit and widget tests in `test/features/audio/ab_loop_and_stems_test.dart`.

---

## [ ] TASK-104: v1.3 Polyphonic Chord Stack Model & Shared-Stem Layout Calculator
- **Epic**: Epic 3 — Notation Engine Polyphony & Multi-Page View (v1.3)
- **Scope**:
  1. Extend `lib/features/score/domain/` (backward-compatibly so all existing 275 tests pass) or add `PolyphonicVoiceCluster` to allow multiple `Pitch` instances on the same beat sharing a single stem and `RhythmicValue`.
  2. Create `lib/features/score/domain/services/chord_stem_layout_calculator.dart`:
     - Pure Dart geometry calculator that computes stem direction (based on average/extreme distance from middle line B4) and horizontal notehead offset rules for adjacent seconds (e.g., C4 + D4 where the upper notehead shifts right to avoid collision).
  3. Add comprehensive unit tests in `test/features/score/chord_stem_layout_calculator_test.dart` covering unisons, seconds (offset required), thirds/triads, and stem direction rules.

---

## [ ] TASK-105: v1.3 Syllable-to-Note Lyric Alignment Engine
- **Epic**: Epic 3 — Notation Engine Polyphony & Multi-Page View (v1.3)
- **Scope**:
  1. Create `lib/features/score/domain/services/lyric_syllable_tokenizer.dart` that splits raw section lyrics into hyphenated syllables (`"Glo-ria al Se-ñor"` -> `["Glo-", "ria al", "Se-", "ñor"]`) and maps them 1:1 against non-rest note events in a `Measure`.
  2. Update `StaffCanvas` / `NoteheadPainter` (`lib/features/score/presentation/`) to optionally render aligned lyric syllables centered below each notehead X-coordinate below the staff bottom ledger boundary.
  3. Add unit and canvas golden/widget tests in `test/features/score/lyric_syllable_alignment_test.dart`.