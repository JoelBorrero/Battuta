import 'dart:async';

import 'package:battuta/features/sync/data/lan_websocket_sync_service.dart';
import 'package:battuta/features/sync/domain/models/sync_cue_payload.dart';
import 'package:battuta/features/sync/domain/services/live_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncCuePayload', () {
    test('serializes to and from JSON faithfully', () {
      const payload = SyncCuePayload(
        songId: 'song-123',
        currentSectionId: 'verse-1',
        nextSectionLabel: 'NEXT: CORO',
        triggerMeasureIndex: 16,
        leaderTimestampMs: 1700000000000,
        sequenceNumber: 42,
      );

      final json = payload.toJson();
      final restored = SyncCuePayload.fromJson(json);

      expect(restored, equals(payload));
      expect(restored.nextSectionLabel, 'NEXT: CORO');
      expect(restored.triggerMeasureIndex, 16);
      expect(restored.sequenceNumber, 42);
    });

    test('supports copyWith', () {
      const payload = SyncCuePayload(
        songId: 'song-123',
        currentSectionId: 'verse-1',
        nextSectionLabel: 'NEXT: CORO',
        triggerMeasureIndex: 16,
        leaderTimestampMs: 1700000000000,
        sequenceNumber: 1,
      );

      final modified = payload.copyWith(
        nextSectionLabel: 'NEXT: PUENTE',
        triggerMeasureIndex: 24,
      );

      expect(modified.nextSectionLabel, 'NEXT: PUENTE');
      expect(modified.triggerMeasureIndex, 24);
      expect(modified.songId, 'song-123');
    });
  });

  group('LanWebSocketSyncService', () {
    late LanWebSocketSyncService director;
    late LanWebSocketSyncService followerA;
    late LanWebSocketSyncService followerB;

    setUp(() {
      director = LanWebSocketSyncService(initialMode: LiveSyncMode.director);
      followerA = LanWebSocketSyncService(initialMode: LiveSyncMode.follower);
      followerB = LanWebSocketSyncService(initialMode: LiveSyncMode.follower);
    });

    tearDown(() async {
      await followerA.dispose();
      await followerB.dispose();
      await director.dispose();
    });

    test(
      'starts director server on ephemeral port and accepts followers',
      () async {
        final port = await director.startDirectorServer(port: 0);
        expect(port, isPositive);
        expect(director.status, LiveSyncStatus.connected);

        await followerA.connect('127.0.0.1', port);
        await followerB.connect('127.0.0.1', port);

        // Brief yield for socket handshake
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(followerA.status, LiveSyncStatus.connected);
        expect(followerB.status, LiveSyncStatus.connected);
        expect(director.connectedFollowersCount, 2);
      },
    );

    test('Director broadcasts 2-measure lookahead cue to all followers', () async {
      final port = await director.startDirectorServer(port: 0);
      await followerA.connect('127.0.0.1', port);
      await followerB.connect('127.0.0.1', port);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final cueACompleter = Completer<SyncCuePayload>();
      final cueBCompleter = Completer<SyncCuePayload>();

      final subA = followerA.cueStream.listen(cueACompleter.complete);
      final subB = followerB.cueStream.listen(cueBCompleter.complete);

      // Current measure is 14; 2-measure lookahead should trigger at measure 16
      final emitted = director.emitLookaheadCue(
        songId: 'song-cuerdas',
        currentSectionId: 'verso-2',
        nextSectionLabel: 'NEXT: CORO',
        currentMeasureIndex: 14,
        lookaheadMeasures: 2,
      );

      expect(emitted.triggerMeasureIndex, 16);
      expect(emitted.nextSectionLabel, 'NEXT: CORO');

      final receivedA = await cueACompleter.future.timeout(
        const Duration(milliseconds: 500),
      );
      final receivedB = await cueBCompleter.future.timeout(
        const Duration(milliseconds: 500),
      );

      expect(receivedA.songId, 'song-cuerdas');
      expect(receivedA.triggerMeasureIndex, 16);
      expect(receivedA.nextSectionLabel, 'NEXT: CORO');

      expect(receivedB.songId, 'song-cuerdas');
      expect(receivedB.triggerMeasureIndex, 16);
      expect(receivedB.nextSectionLabel, 'NEXT: CORO');

      await subA.cancel();
      await subB.cancel();
    });

    test('Director broadcasts jumpNowSection and queueNextSection', () async {
      final port = await director.startDirectorServer(port: 0);
      await followerA.connect('127.0.0.1', port);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final queueCompleter = Completer<String>();
      final jumpCompleter = Completer<String>();

      final qSub = followerA.queuedSectionStream.listen(
        queueCompleter.complete,
      );
      final jSub = followerA.activeSectionStream.listen(jumpCompleter.complete);

      await director.queueNextSection('coro');
      final queuedSec = await queueCompleter.future.timeout(
        const Duration(milliseconds: 500),
      );
      expect(queuedSec, 'coro');

      await director.jumpNowSection('coro');
      final activeSec = await jumpCompleter.future.timeout(
        const Duration(milliseconds: 500),
      );
      expect(activeSec, 'coro');

      await qSub.cancel();
      await jSub.cancel();
    });

    test('LeaderLock: Follower override attempt does not hijack live stage, but is queued as request', () async {
      final port = await director.startDirectorServer(port: 0);
      await followerA.connect('127.0.0.1', port);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Director is currently performing 'intro'
      await director.jumpNowSection('intro');
      expect(director.activeSectionId, 'intro');

      final requestCompleter = Completer<SyncCuePayload>();
      final sub = director.followerRequestStream.listen(
        requestCompleter.complete,
      );

      // Follower tries to force jump to 'puente'
      await followerA.jumpNowSection('puente');

      final request = await requestCompleter.future.timeout(
        const Duration(milliseconds: 500),
      );

      // LeaderLock check: Director's active section MUST remain 'intro'
      expect(director.activeSectionId, 'intro');
      expect(director.pendingFollowerRequests.length, 1);
      expect(request.currentSectionId, 'puente');
      expect(request.nextSectionLabel, 'REQUEST: jump');

      await sub.cancel();
    });

    test(
      'calculateLookaheadMeasure pure helper returns current + lookahead',
      () {
        expect(LanWebSocketSyncService.calculateLookaheadMeasure(10), 12);
        expect(
          LanWebSocketSyncService.calculateLookaheadMeasure(
            10,
            lookaheadMeasures: 4,
          ),
          14,
        );
      },
    );
  });
}
