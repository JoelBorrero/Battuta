# Battuta — Current MVP State & Architecture Roadmap

> **Current Status**: MVP Phase Complete & Verified  
> **Last Updated**: November 6, 2026  
> **Automated Test Suite**: 275 / 275 Tests Passing (100%)  
> **Static Analysis**: 0 Issues Found (`flutter analyze`)  
> **Repository**: [JoelBorrero/Battuta](https://github.com/JoelBorrero/Battuta) (Branch: `main`)

---

## 1. Executive Summary & Product Invariants

**Battuta** *(Italian: "beat" or "downbeat")* is an offline-first lead sheet digitizer, rehearsal companion, and notation editor tailored for worship teams, band directors, and live performing musicians.

### Core Architectural Invariants:
1. **Offline-First by Design**:
   - All core capabilities—song library management, chord chart transposition, staff notation editing, setlist ordering, band calendar scheduling, PDF generation, and MIDI export—operate 100% locally with zero internet dependency via embedded Drift SQLite.
2. **Anti-Material Stage-Ready Visual Identity**:
   - Designed specifically for iPadOS and macOS stage environments (glare reduction, immediate readability, high contrast).
   - **Dark Mode**: Deep obsidian background (`#121316`), elevated slate cards with 1px borders (`#2D3139`), crisp off-white text, and stage amber/gold accents (`#E5A93C`).
   - **Light Mode**: Rehearsal pearl background (`#F8F9FA`), pure white cards (`#FFFFFF`) with subtle 1px border (`#E1E4E8`), charcoal slate text (`#1A1C20`), deep slate staff lines (`#24272C`), and transparent ripple/ink splashes.
   - **No Default Material Elevation**: Surfaces are flat and flush; all touch targets meet Apple HIG ($\ge 44 \times 44$ pt); flexible rows prevent `RenderFlex` overflows.
3. **Disciplined 6-Stage Engineering Standards**:
   - Every modification adheres to: **Analyze → Plan → Implement → Test → Review → Fix** (codified in `.agents/skills/dev-cycle/SKILL.md` and `AGENTS.md`).

---

## 2. Completed Tickets & Feature Delivery Matrix

### A. Foundational Architecture & Core Epics (Pre-MVP / MVP)

| Ticket / Tag | Domain / Module | Summary of Implementation | Verification Status |
| :--- | :--- | :--- | :--- |
| `ticket-86e3yy41e` | **Core Architecture** | Feature-First Clean Architecture structure, Riverpod dependency injection, GoRouter stage shell. | ✅ Verified |
| `ticket-86e3yy41f` | **Music Theory Domain** | Mathematical time signature validation, beat capacity calculation, `fromGeminiPitchList` factory. | ✅ 100% Tested |
| `ticket-86e3yy41g` | **Score Domain** | Pure Dart Score hierarchy (`Score`, `Section`, `Measure`, `Pitch`, `RhythmicValue`), v1.1 sync hooks. | ✅ 100% Tested |
| `ticket-86e3yy41n` | **Security & Config** | Secure API key storage (Keychain/Keystore), masking, validation, `.env` fallback. | ✅ 100% Tested |
| `ticket-86e3yy41r` | **Database & Persistence** | Embedded Drift SQLite database (`NativeDatabase`), DAOs, Repertoire CRUD, memory DB for tests. | ✅ 100% Tested |
| `ticket-86e3yy41t` | **Gemini OMR (Schema A)**| Full lead sheet extraction service, JSON schema validation, structural song mapping. | ✅ 100% Tested |
| `ticket-86e3yy421` | **Gemini OMR (Schema B)**| Melodic snippet and pitch-only extraction, system bounds mapping, rhythmic quantizer. | ✅ 100% Tested |
| `ticket-86e3yy422` | **SMuFL Font Engine** | Bundled Bravura SMuFL vector font, music glyph constants (clefs, notes, accidentals, rests). | ✅ 100% Tested |
| `ticket-86e3yy423` | **Staff Canvas** | CustomPainter `StaffCanvas` rendering 5-line staves, measure barlines, chords, section headers. | ✅ 100% Tested |
| `ticket-86e3yy427` | **Pitch & Notehead Mapping**| `StaffPitchMapper` (C4–B5), dynamic ledger lines, unassigned pitch styling, warning badges. | ✅ 100% Tested |
| `ticket-86e3yy428` | **Scanner & Camera** | Camera capture flow, photo library import, aspect-ratio cropping modal (`ScanFlowModal`). | ✅ 100% Tested |
| `ticket-86e3yy429` | **Spatial Drag & Snap** | Spatial hit-testing, vertical drag-and-snap gesture detector for intuitive note repositioning. | ✅ 100% Tested |
| `ticket-86e3yy42e` | **Rhythm Toolbar** | Tap-first duration assignment (whole to 32nd), dotted/triplet modifiers, measure progress bar. | ✅ 100% Tested |
| `ticket-86e3yy42h` | **PDF Generation** | Vector PDF lead sheet generator using Bravura SMuFL font for AirPrint and file sharing. | ✅ 100% Tested |
| `ticket-86e3yy42k` | **MIDI Export** | SMF Type 0/1 MIDI file exporter at 480 PPQ, tempo meta-events, tie merging. | ✅ 100% Tested |
| `ticket-86e3yy42q` | **Post-MVP Interfaces** | Pure Dart abstract contracts for LiveSync, PitchShiftedAudioPlayer, and QuantizationInputEngine. | ✅ 100% Tested |
| `feat-song-editor-crud`| **Interactive Repertoire**| Dynamic song editor, section builder, live transposer ($\pm N$ semitones), lyrics & chord dialog. | ✅ 100% Tested |

---

### B. Recent Feature Enhancements & UX Polish

1. **Interactive Notation Audio Auditioning & Melody Preview**:
   - Real-time sound synthesis triggered on note selection, touch tap, or vertical drag.
   - Calculates exact physical frequencies:
     $$f = 440 \times 2^{\frac{\text{MIDI} - 69}{12}}$$
   - Full melody playback preview with tempo controls and active note tracking.
2. **Visual Note Selection Polish**:
   - Glowing amber outline (`#E5A93C`, 2.5px width) for the active note.
   - Floating pitch badge displaying diatonic pitch step (e.g. `C4`, `G4`, `A5`) and accidental indicators.
3. **Team Roster & Musician Multi-Role Specialization**:
   - Full member management (Add, Edit, Delete).
   - Multi-role support: musicians can hold concurrent assignments (e.g., *Pianist* + *Vocalist* + *Acoustic Guitarist*).
   - Smart tessitura auto-discard: selecting pure instrument roles automatically unsets and clears vocal range options.
4. **Band Calendar & Recurring Scheduling Engine**:
   - Dedicated Band Calendar tab with calendar-based service scheduling.
   - Offline mathematical recurrence engine (`EventRecurrenceCalculator`) supporting:
     - Weekly Sunday Services
     - Weekly Thursday Band Rehearsals
     - 1st Sunday of the Month (e.g., Communion Service)
     - 2nd, 3rd, and Last Sunday of the Month (e.g., Youth Praise Nights)
     - Bi-weekly (every 14 days) and Monthly cadences
   - Series generator for 1, 4, 6, 12, or 24 occurrences across month/year rollover boundaries.
   - Musician lineup assignment with attendance status tracking (*Confirmed*, *Tentative*, *Declined*).
5. **Anti-Material Light Theme**:
   - Tailored for bright rehearsal spaces (`#F8F9FA` pearl background, slate text, `#E5A93C` amber accents, `#E1E4E8` card borders, transparent ripple splash).
6. **Layout Polish & Zero-Overflow Assurance**:
   - Fixed horizontal and vertical `RenderFlex` overflows in `PracticePlayerBar`, `TeamPage` roster cards, and `ScoreEditorPage`.

---

## 3. Current Architecture & Codebase Map

```
lib/
├── app/
│   ├── config/                     # Environment configuration & constants
│   ├── routes/                     # GoRouter declarative navigation & shell route
│   ├── shell/                      # Stage-ready persistent bottom navigation shell
│   └── theme/                      # AppTheme (Dark & Light anti-material themes)
│
├── core/
│   ├── database/                   # Drift SQLite schema, DAOs, and database provider
│   ├── errors/                     # Failure and exception hierarchies
│   ├── services/                   # ApiKeyService (Secure storage, masking, .env)
│   ├── usecases/                   # Base UseCase contracts
│   └── utils/                      # Math helpers, date extensions, logger
│
├── features/
│   ├── repertoire/                 # Song library, lead sheet viewer, editor & transposer
│   │   ├── data/                   # Drift repositories, in-memory test mocks
│   │   ├── domain/                 # Song, Section, Chord, MusicalKey entities & mappers
│   │   └── presentation/           # RepertoirePage, SongEditorPage, SongDetailPage
│   │
│   ├── scanner/                    # Optical Music Recognition (Gemini AI)
│   │   ├── data/                   # GeminiOmrRepository, ImagePickerService
│   │   ├── domain/                 # Schema A & B JSON parsers & mappers
│   │   └── presentation/           # ScannerPage, ScanFlowModal, ScanController
│   │
│   ├── score/                      # Pure Dart Notation Engine & Editor
│   │   ├── data/                   # PdfLeadSheetGenerator, MidiFileExporter
│   │   ├── domain/                 # Score, Measure, Pitch, RhythmicValue entities
│   │   └── presentation/           # StaffCanvas, NoteheadPainter, RhythmToolbar
│   │
│   ├── audio/                      # Audio Player & Synth Auditioning
│   │   ├── domain/                 # Synthesizer pitch math & audio contracts
│   │   └── presentation/           # PracticePlayerBar, note auditioning hooks
│   │
│   ├── team/                       # Band Roster & Calendar Scheduling
│   │   ├── domain/                 # TeamMember, ServiceEvent, RecurrenceCalculator
│   │   └── presentation/           # TeamPage, ServiceCalendarProvider, lineups
│   │
│   ├── sync/                       # Live Stage Sync Contracts (v1.1)
│   │   └── domain/services/        # LiveSyncService (ProPresenter, WebSockets)
│   │
│   └── settings/                   # User Preferences & Security
│       └── presentation/           # SettingsPage, ApiKeyDialog, theme toggles
```

---

## 4. Test Suite & Verification Metrics

- **Total Test Cases**: **275 Passing Tests**
- **Test Categories**:
  - `test/core/`: Failure classes, secure storage, environment fallbacks.
  - `test/features/repertoire/`: Song serialization, chord parsing, transposition engine, DAO queries.
  - `test/features/scanner/`: Schema A/B OMR mappers, crop controllers, camera modals.
  - `test/features/score/`: SMuFL glyphs, staff layout, vertical drag-and-snap, PDF export, MIDI export.
  - `test/features/team/`: Roster CRUD, multi-role validation, tessitura discards, recurrence math (ordinal Sundays, leap years), calendar series generation.
  - `test/features/audio/`: Oscillator pitch math, frequency calculations, practice bar controls.
  - `test/app/`: Navigation routing, theme switching, AppTheme styling verification.
- **Static Analysis**: `flutter analyze` reports **0 issues found** across all packages.

---

## 5. Remaining Architecture Decisions & Post-MVP Roadmap

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                           POST-MVP ROADMAP                             │
  ├───────────────────┬───────────────────┬────────────────────────────────┤
  │ v1.1 Live Stage   │ v1.2 Audio Stems  │ v1.3 Advanced OMR              │
  │ Synchronization   │ & Real-time Pitch │ & Polyphonic Notation          │
  └───────────────────┴───────────────────┴────────────────────────────────┘
```

### Epic 1: Live Stage Synchronization (v1.1)
- **Current State**: Abstract contract [`LiveSyncService`](file:///Users/joelborrero/Projects/Battuta/lib/features/sync/domain/services/live_sync_service.dart) defined and tested with mock fixtures.
- **Key Architecture Decisions Remaining**:
  1. **Stage Presentation Protocol**:
     - *Option A*: Direct ProPresenter 7.9+ REST API + WebSocket listener (proven standard in church and live production).
     - *Option B*: Local LAN peer-to-peer WebSocket mesh (Bonjour / mDNS discovery on iPadOS/macOS) for director-to-band-member device sync without ProPresenter.
     - *Recommendation*: Hybrid approach—ProPresenter integration for sanctuary stage displays + local LAN WebSocket mesh for band member tablets.
  2. **Director vs. Follower Conflict Handling**:
     - Resolving simultaneous section transitions during live performance (leader lock vs. queue override).
     - Visual cue latency: Ensuring the amber "NEXT: CORO" cue arrives $\ge 2$ measures before the downbeat.

### Epic 2: Audio Engine & Stem Playback (v1.2)
- **Current State**: Lightweight WebAudio/synthesizer pitch auditioning and melody preview implemented.
- **Key Architecture Decisions Remaining**:
  1. **Playback Engine Selection**:
     - *Option A*: `flutter_soloud` (high-performance C++ audio engine with low latency, pitch shifting, and stem mixing).
     - *Option B*: Native platform audio via Dart FFI with SoundTouch / Rubber Band library for high-fidelity independent tempo/pitch stretching.
  2. **Multi-Track Backing Stem Storage**:
     - Local audio file storage strategy using `path_provider` application documents directory vs. compressed SQLite BLOBs (for small rehearsal samples).
  3. **A/B Practice Loop Precision**:
     - Sub-millisecond boundary loop point precision to prevent audio clicking on beat repetition.

### Epic 3: Notation Engine Polyphony & Multi-Page View (v1.3)
- **Current State**: Single-voice diatonic staves (C4–B5) with chord symbols and rhythmic toolbar.
- **Key Architecture Decisions Remaining**:
  1. **Polyphonic Chords & Voices**:
     - Rendering multiple noteheads sharing a single stem on the same beat (e.g. keyboard chords, vocal harmonies).
  2. **Multi-Page & Continuous Vertical Scroll**:
     - Transitioning `StaffCanvas` from a single section canvas to an indexed multi-system page view suitable for 3–5 page lead sheets.
  3. **Syllable-to-Note Lyric Alignment**:
     - Rendering lyrics directly below the corresponding notehead stems rather than in a separate section text block.

### Epic 4: On-Device OMR & Cloud Synchronization (v1.4)
- **Current State**: Cloud Gemini OMR (`gemini-3.8-flash`) via secure API key.
- **Key Architecture Decisions Remaining**:
  1. **Offline OMR Fallback**:
     - Investigating lightweight on-device ML models (CoreML on Apple silicon, TensorFlow Lite on Android) for basic staff detection and pitch estimation when completely disconnected from the internet.
  2. **Multi-Device Cloud Backup**:
     - Defining a sync mechanism (e.g., Supabase, CloudKit, or Firebase Firestore) that layers cleanly over Drift SQLite without compromising the offline-first invariant.

---

## 6. Development Workflow & Engineering Standards

All contributors and AI pairing sessions must operate within the documented standards:
- **Operating Standards**: [`AGENTS.md`](file:///Users/joelborrero/Projects/Battuta/AGENTS.md)
- **Workflow Skill**: [`.agents/skills/dev-cycle/SKILL.md`](file:///Users/joelborrero/Projects/Battuta/.agents/skills/dev-cycle/SKILL.md) (invoke with `/dev-cycle`)
- **Verification Rule**: No branch or ticket is complete without passing both `flutter analyze` (0 issues) and `flutter test` (100% pass rate).

