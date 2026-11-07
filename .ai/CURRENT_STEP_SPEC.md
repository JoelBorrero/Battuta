# Step Spec: TASK-101 Local LAN WebSocket LiveSync & Conflict Resolution

## Exact Files to Create / Modify
- `lib/features/sync/domain/models/sync_cue_payload.dart` (Create)
- `lib/features/sync/data/lan_websocket_sync_service.dart` (Create)
- `test/features/sync/lan_websocket_sync_service_test.dart` (Create)

## Domain & Data Architecture
- `SyncCuePayload`:
  - `songId` (String)
  - `currentSectionId` (String)
  - `nextSectionLabel` (String, e.g. "NEXT: CORO")
  - `triggerMeasureIndex` (int)
  - `leaderTimestampMs` (int)
  - `sequenceNumber` (int)
  - JSON serialization (`toJson`, `fromJson`) and value equality.
- `LanWebSocketSyncService` implementing `LiveSyncService`:
  - Uses `dart:io` (`HttpServer`, `WebSocketTransformer`, `WebSocket`).
  - Director Mode:
    - `Future<int> startDirectorServer({String address = '127.0.0.1', int port = 0})` binds server and returns port.
    - Manages active client `WebSocket` connections and broadcasts payloads.
    - `LeaderLock`: rejects follower direct overrides (stores as pending requests); enforces monotonic sequence numbers.
    - Automatic 2-measure lookahead calculation: `triggerMeasureIndex = currentMeasureIndex + 2`.
  - Follower Mode:
    - Connects via `connect(host, port)` using `WebSocket.connect('ws://$host:$port')`.
    - Validates sequence numbers to prevent out-of-order execution.
    - Exposes `statusStream`, `activeSectionStream`, `queuedSectionStream`, and `cueStream`.
  - Proper error handling and resource disposal on `disconnect()`.

## Tests
- Test Director starting on ephemeral port (0).
- Test 2 Followers connecting to Director.
- Test Director -> Followers broadcast of `SyncCuePayload`.
- Test Leader-lock conflict rejection: follower sending override message is rejected/queued as request.
- Test 2-measure lookahead calculation: given measure N, triggerMeasureIndex is N + 2.
