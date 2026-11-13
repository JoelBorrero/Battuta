---
status: done
commit: (this commit)
base_sha: a75a596
rounds: 1 of 3
---
# 016: Settings redesign

**Goal:** Settings matches the "Battuta Screens" mockup, using brand colours only and readable in light mode.

## What changed
- **Layout.** `StageAppBar.large("Settings")` with `StageGroup` / `StageRow` sections: Appearance, General,
  Account and sync, Workspace resources & quota, About, and a footer with the version.
- **Appearance.** `StageSegmentedControl<ThemeMode>`: Stage (dark) / Rehearsal (light) / System.
- **General.** Language row (`language_tile`) opens a picker sheet (System / English / Español,
  `language_option_*`), saved through the existing locale provider.
- **Account and sync.** A status card (state, last synced, `sync_now_btn`) above one card of rows: account
  (sign in / create / signed-in user), Server (`supabase_config_tile`), and the admin Gemini key and OMR log rows.
- **Workspace quota.** `workspace_usage_group.dart`: brand roles only; readable in light mode.
- **Colours.** The 7 hex literals and `Colors.*` uses are gone from the settings page and its widgets.

## Decisions
- No demo-mode row: the app has no demo mode.
- The "API Configuration" header, the About tagline, the separate Version row and `language_segmented_btn` are
  gone (no behaviour attached); the version is the footer.
- Chart text size, prefer flats and keep screen awake are added by 017 with their providers.

## Deferred
- Server row shows its configuration hint, not the active server (backlog).
- No test for the sync status card states (backlog).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1281 passed, 9 skipped, 1 known date-dependent failure.
