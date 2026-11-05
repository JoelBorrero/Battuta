# Battuta 🎵

A music rehearsal & lead-sheet companion for worship teams and bands.

**Battuta** *(Italian: "beat" or "downbeat")* helps musicians manage their
repertoire, view chord charts and lead sheets, rehearse with audio tools, and
synchronize during live performances.

## Architecture

This project follows a **feature-first clean architecture** pattern:

```
lib/
├── app/                          # App-wide configuration
│   ├── config/                   # Constants, environment config
│   ├── routes/                   # GoRouter setup & route definitions
│   ├── shell/                    # Navigation shell (bottom nav)
│   └── theme/                    # Colors, typography, ThemeData
│
├── core/                         # Shared utilities across features
│   ├── errors/                   # Failure & Exception hierarchies
│   ├── usecases/                 # Abstract UseCase base classes
│   └── utils/                    # Extensions, logger, helpers
│
└── features/                     # Feature-first modules
    ├── repertoire/               # Song management & chord display
    │   ├── data/                 # DTOs, data sources, repo impls
    │   ├── domain/               # Entities, abstract repos, use cases
    │   └── presentation/         # Providers, pages, widgets
    ├── live_session/             # Real-time band sync (WebSocket)
    ├── scanner/                  # Gemini OMR camera capture
    └── settings/                 # App preferences & configuration
```

### Key Principles

- **Dependencies point inward**: Presentation → Domain ← Data
- **Domain layer is pure Dart**: No Flutter imports in entities or use cases
- **Features are isolated**: Cross-feature shared logic lives in `core/`
- **Riverpod for everything**: State management + dependency injection

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.47+ / Dart 3.13+ |
| State Management | Riverpod 3.x (with code generation) |
| Routing | go_router 18.x |
| Models | Freezed + json_serializable |
| Error Handling | fpdart (Either, Option) |
| Local Database | *Drift — coming in ticket #86e3yy41r* |
| AI/ML | *Gemini API — coming in tickets #86e3yy41t, #86e3yy421* |
| Testing | mocktail |

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.47.0
- Dart SDK ≥ 3.13.0
- Xcode (for iOS)
- Android Studio (for Android)

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd Battuta

# Install dependencies
flutter pub get

# Run code generation (freezed, riverpod_generator, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Code Generation

After modifying any `@freezed`, `@riverpod`, or `@JsonSerializable` classes:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild on save)
dart run build_runner watch --delete-conflicting-outputs
```

## Roadmap

See the [ClickUp Battuta board](https://app.clickup.com/) for the full backlog.
Current milestone focuses on:

1. ✅ Project scaffolding & clean architecture setup
2. ⬜ Secure API key storage & environment configuration
3. ⬜ Pure Dart score domain tree
4. ⬜ Embedded local database & repertoire CRUD
5. ⬜ Gemini OMR service integration
6. ⬜ Staff canvas & chord grid rendering
7. ⬜ Live session WebSocket sync

## License

Proprietary — All rights reserved.
