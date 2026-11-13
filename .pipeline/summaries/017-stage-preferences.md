---
status: done
commit: (this commit)
base_sha: 63eb3a9
rounds: 1 of 3
---
# 017: Stage preferences

**Goal:** Make the mockup's chart text size, prefer flats and keep-screen-awake settings real, saved on the
device, and save the theme like the language.

## What changed
- **Device preferences storage.** `device_preferences_storage.dart` (the same `SecureApiKeyStorage` the
  language used) backs theme, language and stage preferences. `localeStorageProvider` is an alias; language
  keeps `battuta_selected_language`, so saved choices survive the update.
- **Theme saved.** `battuta_theme_mode`; System deletes the key. Default System.
- **Stage preferences.** `StagePreferences` (domain) and `stagePreferencesProvider`: chart text scale 0.8–1.6
  in 0.1 steps (default 1.0; "abc" → 1.0, 5.0 → 1.6, 0.79 → 0.8), prefer flats (default off), keep screen
  awake (default on). One key per field; read errors fall back to defaults.
- **No lost choices.** For theme, language and stage preferences a slow first read never overwrites a choice
  made while it loads.
- **Settings.** Chart text size slider (percent, semantic label) under Appearance; "Prefer flats when
  transposing" (`prefer_flats_row`) and "Keep screen awake on stage" (`keep_awake_row`) under General.
- **Chart text size.** `ChordLyricsView.chartTextScale` scales chord and lyric text on Song detail; no
  overflow at 160% on 320 pt (section names ellipsize, empty-state texts wrap).
- **Prefer flats.** `SongTransposer.transposeSong(preferSharps:)`: flats on forces flats (C +1 → Db); flats
  off keeps the key-signature spelling as before (G +3 → Bb). Chart, key tile, stepper preview, Transpose &
  save and every export use the same transposed song.
- **Keep screen awake.** `wakelock_plus` behind `ScreenWakeLock`: held while Live is open and the setting is
  on; released when leaving Live or turning the setting off; safe if the page closes mid-call; errors ignored
  on unsupported platforms.

## Decisions
- Flats off means "keep the song's spelling", not "force sharps": users who never touch the setting see the
  same output as before.
- Setlist key pills show the stored key override (nothing is transposed there), so they are unchanged.

## Deferred
- Live renders no chart yet, so chart text size and flats apply to Song detail only (Live performance view).
- Wake lock is not reference-counted (backlog).
- Settings sync status card overflow at 320 pt with large system text (pre-existing; backlog).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1308 passed, 9 skipped, 1 known date-dependent failure.
