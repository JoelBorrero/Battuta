# Battuta 🎵

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#license)
[![Tests](https://img.shields.io/badge/Tests-234%20Passed-brightgreen)](test/)

**Battuta** *(Italian: "beat" or "downbeat")* is an advanced music rehearsal, lead-sheet companion, and notation companion designed for worship teams, band directors, and live musicians. It combines embedded offline database persistence, music-theory transposition engines, interactive staff notation editing, and Gemini-powered Optical Music Recognition (OMR).

---

## ✨ Features & User Utilities

### 📚 1. Repertoire Management (100% Offline SQLite)
- **Local-First Architecture**: Powered by Drift SQLite, ensuring complete CRUD functionality in Airplane Mode with zero network dependency.
- **Instant Search & Filter**: Real-time filtering across song titles, artists, and categorization tags without UI lag.
- **Rich Metadata Badges**: At-a-glance visibility for musical key, tempo BPM, meter, and custom tags on every song card.
- **Setlist Management**: Organize repertoire into ordered performance setlists with per-song key overrides and custom performance notes.

### ✍️ 2. Song Creation & Dynamic Section Editor
- **Full-Featured Song Builder**: Accessible via `/repertoire/new` and `/repertoire/:songId/edit` with field validation for title, composer/artist, key, tempo, meter, notes, and tags.
- **All 30 Musical Keys**: Complete circle-of-fifths support for all 15 major and 15 minor keys, including enharmonic spellings (e.g., C♯, D♭, F♯, G♭).
- **Tap-Tempo Counter**: Rapidly tap the tempo button to calculate and set the exact BPM of a song.
- **Dynamic Section Builder**:
  - **Quick Template Chips**: Instant one-tap insertion of common sections (*Intro*, *Verse 1*, *Verse 2*, *Pre-Chorus*, *Chorus*, *Bridge*, *Outro*).
  - **Repeat Multipliers**: Configurable repeat counts (`1×`, `2×`, `3×`, etc.) for rehearsal cues.
  - **Section Reordering**: Move sections up, down, or reorder freely.
  - **Quick Chord Parser**: Type chord progressions in plain text (e.g., `C | G/B | Am7 | Fmaj7`) to automatically parse and tokenize them into chord charts.
  - **Interactive Chord Dialog**: Fine-tune chord roots, accidentals, harmonic qualities (major, minor, 7th, maj7, dim, aug, sus2, sus4, add9), slash bass notes, and beat lengths.
  - **Lyrics & Rehearsal Notes**: Multiline lyrics layout and section-specific rehearsal reminders.

### 🔍 3. Interactive Lead Sheet Viewer & Music Theory Engine
- **Live Transposition**: Transpose any song by $\pm N$ semitones on the fly. The engine updates the root key, slash chord bass notes, and chord qualities dynamically with an option to persist the transposed key back to the database.
- **Printable PDF Lead Sheets**: Generate professional vector PDF lead sheets with SMuFL Bravura music font glyphs, measure barlines, headers, and metadata using the `printing` package for AirPrint, printing, and file sharing.
- **MIDI Reference Exporter**: Export SMF Type 0/1 MIDI files at standard 480 PPQ with tempo meta-events, time signatures, guide tone pitches, and inter-measure note tie merging for playback in DAWs or rehearsal apps.

### 📷 4. Gemini AI Optical Music Recognition (OMR)
- **AI-Powered Sheet Music Ingestion**: Scan physical sheet music directly from camera or import from your photo library.
- **Dual Recognition Schemas**:
  - **Schema A (Full Lead Sheet)**: Extracts the complete structural lead sheet: title, composer, key signature, tempo, meter, and measures with chords and lyrics.
  - **Schema B (Pitch-Only Snippet)**: Extracts isolated melodic systems and note sequences for rhythm quantizing.
- **Automatic Repertoire Ingestion**: Scanned scores map seamlessly into editable `Song` entities via `ScoreSongMapper` and save directly into your offline library.

### 🎼 5. Interactive Staff Canvas & Notation Editor
- **Bravura SMuFL Vector Font**: Native musical glyphs for treble/bass clefs, standard noteheads, accidentals, flags, rests, and barlines.
- **CustomPainter StaffCanvas**: Renders clean 5-line musical staves, measures, and chord symbols.
- **Spatial Hit-Testing & Drag-and-Snap**: Tap or drag noteheads vertically across diatonic pitch steps (C4 through B5) with automatic snapping and ledger line calculations.
- **'Tap-First' Rhythm Editor Toolbar**: One-tap duration assignment (whole, half, quarter, eighth, sixteenth, 32nd notes), dotted and triplet modifiers, rest conversion, capacity validation, and measure progress indicators.

### ⚙️ 6. Settings, Theming & API Security
- **Dynamic Theming**: Seamless switching between Light, Dark, and System modes with immediate app-wide reactivity.
- **Secure Gemini API Key Storage**: Stored in platform secure hardware (Keychain on macOS/iOS, Keystore on Android) with key masking, validation, clipboard paste, and `.env` fallback.
- **Open Source Attribution**: Built-in interactive third-party licenses browser.

---

## 🏗️ Architecture

Battuta follows a **Feature-First Clean Architecture** with pure Dart domain modeling:

```
lib/
├── app/                          # Core app infrastructure
│   ├── config/                   # Constants, environment configurations
│   ├── routes/                   # GoRouter navigation graph & shell route
│   ├── shell/                    # Scaffold with persistent bottom navigation bar
│   └── theme/                    # AppTheme, palettes, typography, theme provider
│
├── core/                         # Shared kernel
│   ├── database/                 # Drift SQLite setup, tables, DAOs & providers
│   ├── errors/                   # Failures & Exception hierarchies
│   ├── services/                 # Secure API key storage & environment service
│   ├── usecases/                 # Base UseCase contracts
│   └── utils/                    # Extensions, math helpers, logger
│
└── features/                     # Feature modules
    ├── repertoire/               # Song library, lead sheets, transposer & editor
    │   ├── data/                 # Drift repositories & in-memory testing repo
    │   ├── domain/               # Song, Section, Chord, Key entities & services
    │   └── presentation/         # Pages (Repertoire, Editor, Detail) & providers
    ├── scanner/                  # Gemini OMR camera capture & image processing
    │   ├── data/                 # Gemini API integration & image capture service
    │   ├── domain/               # FullSheet & PitchOnly OMR mappers & schemas
    │   └── presentation/         # ScannerPage, ScanFlowModal & ScanController
    ├── score/                    # Pure Dart notation tree & rendering engine
    │   ├── data/                 # PDF generator & MIDI file exporter services
    │   ├── domain/               # Score, Measure, Pitch, RhythmicValue entities
    │   └── presentation/         # StaffCanvas, RhythmToolbar & Progress Bar
    ├── live_session/             # Real-time multi-device sync (WebSocket preview)
    ├── sync/                     # LiveSyncService abstract interface
    └── settings/                 # App preferences, theme toggle & API key dialog
```

### Architectural Principles

1. **Domain Layer is Pure Dart**: Entities (`Song`, `Score`, `Measure`, `MusicalKey`, `Pitch`) have zero dependencies on Flutter UI or platform plugins.
2. **Inversion of Control**: Data sources and repositories implement abstract domain interfaces (`SongRepository`, `ScoreRepository`, `OmrRepository`).
3. **State Management via Riverpod**: Declarative state management, code-generated notifiers, and dependency injection across the widget tree.
4. **Resilient Testing**: In-memory SQLite (`NativeDatabase.memory()`) automatically activates during test runs to ensure instant, isolated test execution.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.47+ / Dart 3.13+ |
| **State Management** | Riverpod 3.x with Riverpod Generator |
| **Navigation** | GoRouter 18.x with ShellRoute |
| **Data Persistence** | Drift (SQLite) with drift_flutter |
| **AI / OMR** | Google Gemini 2.5 Flash API (Multimodal Structured Outputs) |
| **Typography & Glyphs** | Steinberg Bravura SMuFL Font |
| **Document Export** | `pdf` & `printing` packages |
| **Audio & MIDI** | Pure Dart 480 PPQ Standard MIDI File (SMF) Engine |
| **Secure Storage** | `flutter_secure_storage` |
| **Functional Programming**| `fpdart` (`Either`, `Option`) |
| **Code Generation** | `freezed`, `json_serializable`, `build_runner` |
| **Testing** | `flutter_test`, `mocktail` |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.47.0
- Dart SDK ≥ 3.13.0
- macOS with Xcode (for iOS/macOS) or Android Studio (for Android)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/JoelBorrero/Battuta.git
cd Battuta

# 2. Install dependencies
flutter pub get

# 3. Generate models, database code, and Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# 4. (Optional) Provide a Gemini API key for OMR scanning
# Create a .env file in the root directory:
echo "GEMINI_API_KEY=your_api_key_here" > .env
# Or enter it inside the app under Settings > API Configuration.

# 5. Run the application
flutter run
```

---

## 🧪 Testing & Quality Assurance

Battuta enforces strict quality assurance with **234 automated tests** covering unit, widget, and domain logic:

```bash
# Run the full test suite
flutter test

# Run static analysis (0 warnings / 0 errors enforced)
flutter analyze
```

### Test Coverage Highlights
- **Domain Logic**: Mathematical time signature capacity, circle-of-fifths transposition, and pitch arithmetic.
- **Repository Tests**: Full SQLite CRUD operations verifying offline airplane mode persistence.
- **OMR Parsers**: Deterministic verification of Schema A and Schema B JSON payloads.
- **Custom Painter & Canvas**: Golden tests and spatial hit-testing for notehead dragging and ledger line snapping.
- **Widget Flow**: Complete UI coverage of Song Editor, Song Detail, Transposer, Repertoire, Settings, and Scanner pages.

---

## 📄 License

Proprietary — All rights reserved. Designed and developed for worship teams and musical bands.
