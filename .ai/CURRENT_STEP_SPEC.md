# Step Spec: TASK-102 Live Stage Sync Banner & Director Control Bar UI

## Exact Files to Create / Modify
- `lib/features/sync/presentation/providers/live_sync_provider.dart` (Create)
- `lib/features/sync/presentation/widgets/stage_cue_banner.dart` (Create)
- `test/features/sync/presentation/stage_cue_banner_test.dart` (Create)

## Domain / State / UI Architecture
- `LiveSyncUiState`:
  - `status`: `LiveSyncStatus` (disconnected, connecting, connected, etc.)
  - `mode`: `LiveSyncMode` (director, follower)
  - `activeSectionId`: String?
  - `queuedSectionLabel`: String?
  - `activeCue`: `SyncCuePayload?`
  - `pendingRequests`: List<SyncCuePayload>
- `LiveSyncNotifier`:
  - Injects `LiveSyncService` (defaults to a provider providing `LanWebSocketSyncService`).
  - Listens to service streams and cancels on dispose.
  - Exposes actions: `connect(host, port)`, `disconnect()`, `queueNext(sectionId)`, `jumpNow(sectionId)`, `dismissCue()`, `setSyncMode(mode)`.
- `StageCueBanner` (Presentation):
  - Displays cue message: e.g. "NEXT: CORO" or custom label.
  - Sub-label or measure info: e.g. "(in 2 bars)".
  - Amber `#E5A93C` border (1.5px / 2px flush), anti-material (elevation 0).
  - Background: `#121316` (Dark) with slight amber tint or `#FFFFFF` (Light) with 1px border.
  - Flexible layout: `Row` with `Expanded` text, preventing `RenderFlex` overflow at narrow widths (down to 320px).
  - Actions: Dismiss button and/or Jump Now action with minimum `44x44` touch target (`kMinInteractiveDimension`).
  - Director Control Bar helper or integrated director controls.

## Tests
- Widget test verifying Dark mode (`#121316`) rendering.
- Widget test verifying Light mode (`#F8F9FA`) rendering.
- Responsive test: renders without overflow under `320x600` tight viewport constraints.
- Tap test: dismiss button fires callback, meets `>= 44x44` hit target.
