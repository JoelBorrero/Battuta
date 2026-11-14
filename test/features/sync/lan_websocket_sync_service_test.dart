import 'dart:async';
import 'dart:io';

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

    group('LAN hosting', () {
      test('binds to every IPv4 interface', () async {
        await director.startDirectorServer(port: 0);
        expect(director.serverAddress, InternetAddress.anyIPv4);
      });

      test('falls back to an ephemeral port when the port is taken', () async {
        final taken = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(taken.close);

        final port = await director.startDirectorServer(port: taken.port);

        expect(port, isNot(taken.port));
        expect(port, isPositive);
      });

      test('lists followers by the device name they send in hello', () async {
        final named = LanWebSocketSyncService(deviceName: 'Joel iPad');
        final other = LanWebSocketSyncService(deviceName: 'Ana Galaxy');
        addTearDown(named.dispose);
        addTearDown(other.dispose);
        final port = await director.startDirectorServer(port: 0);

        await named.connect('127.0.0.1', port);
        await other.connect('127.0.0.1', port);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(director.connectedFollowersCount, 2);
        expect(
          director.followerNames,
          unorderedEquals(['Joel iPad', 'Ana Galaxy']),
        );

        await other.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(director.followerNames, ['Joel iPad']);
      });

      test('connect times out when the host never answers', () async {
        // Accepts TCP but never completes the WebSocket handshake.
        final mute = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(mute.close);
        final slow = LanWebSocketSyncService(
          connectTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(slow.dispose);

        await expectLater(
          slow.connect('127.0.0.1', mute.port),
          throwsA(
            isA<LiveConnectException>().having(
              (e) => e.reason,
              'reason',
              LiveConnectFailure.timeout,
            ),
          ),
        );
        expect(slow.status, LiveSyncStatus.error);
      });

      test('connect reports an unreachable host', () async {
        final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = closed.port;
        await closed.close();

        await expectLater(
          followerA.connect('127.0.0.1', port),
          throwsA(
            isA<LiveConnectException>().having(
              (e) => e.reason,
              'reason',
              LiveConnectFailure.unreachable,
            ),
          ),
        );
      });

      test('follower reconnects after the director restarts', () async {
        final follower = LanWebSocketSyncService(
          reconnectDelays: const [
            Duration(milliseconds: 50),
            Duration(milliseconds: 100),
          ],
        );
        addTearDown(follower.dispose);
        final port = await director.startDirectorServer(port: 0);
        await follower.connect('127.0.0.1', port);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(director.connectedFollowersCount, 1);

        final statuses = <LiveSyncStatus>[];
        final sub = follower.statusStream.listen(statuses.add);
        addTearDown(sub.cancel);

        // Director goes away and comes back on the same port.
        await director.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(follower.status, LiveSyncStatus.reconnecting);
        await director.startDirectorServer(port: port);

        for (var i = 0; i < 40 && director.connectedFollowersCount < 1; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(director.connectedFollowersCount, 1);
        expect(follower.status, LiveSyncStatus.connected);
        expect(statuses, contains(LiveSyncStatus.reconnecting));

        // Frames flow again.
        final queued = Completer<String>();
        final qSub = follower.queuedSectionStream.listen(queued.complete);
        addTearDown(qSub.cancel);
        await director.queueNextSection('coro');
        expect(await queued.future.timeout(const Duration(seconds: 1)), 'coro');
      });

      test('a relaunched director is heard after a reconnect', () async {
        final follower = LanWebSocketSyncService(
          reconnectDelays: const [Duration(milliseconds: 50)],
        );
        addTearDown(follower.dispose);
        final port = await director.startDirectorServer(port: 0);
        await follower.connect('127.0.0.1', port);
        for (var i = 0; i < 40; i++) {
          await director.jumpNowSection('s$i');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(follower.activeSectionId, 's39');

        // The director app is killed and relaunched: a brand new service
        // whose sequence numbers start over, on the same port.
        await director.disconnect();
        final relaunched = LanWebSocketSyncService();
        addTearDown(relaunched.dispose);
        await relaunched.startDirectorServer(port: port);
        for (var i = 0; i < 40 && relaunched.connectedFollowersCount < 1; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(relaunched.connectedFollowersCount, 1);

        final jumped = Completer<String>();
        final sub = follower.activeSectionStream.listen(jumped.complete);
        addTearDown(sub.cancel);
        await relaunched.jumpNowSection('coro'); // sequence number 1
        expect(await jumped.future.timeout(const Duration(seconds: 1)), 'coro');
      });

      test('two concurrent hosting starts leave a single server', () async {
        final results = await Future.wait([
          director.startDirectorServer(port: 0),
          director.startDirectorServer(port: 0),
        ]);
        final bound = director.serverPort;
        expect(bound, results.last);

        // The first server was closed: its port no longer answers.
        await expectLater(
          Socket.connect(
            InternetAddress.loopbackIPv4,
            results.first,
            timeout: const Duration(milliseconds: 500),
          ),
          throwsA(isA<SocketException>()),
        );

        // And after End the bound port can be bound again.
        await director.disconnect();
        final again = await ServerSocket.bind(InternetAddress.anyIPv4, bound!);
        await again.close();
      });

      test('a superseded connect failure leaves the newer one alone', () async {
        final mute = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(mute.close);
        final follower = LanWebSocketSyncService(
          connectTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(follower.dispose);
        final port = await director.startDirectorServer(port: 0);

        final slow = follower.connect('127.0.0.1', mute.port);
        final slowResult = expectLater(
          slow,
          throwsA(isA<LiveConnectException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await follower.connect('127.0.0.1', port);
        await slowResult;

        expect(follower.status, LiveSyncStatus.connected);
        // Still followed: a dropped socket must trigger a reconnect.
        await director.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(follower.status, LiveSyncStatus.reconnecting);
      });

      test('Leave stops the reconnect attempts', () async {
        final follower = LanWebSocketSyncService(
          reconnectDelays: const [Duration(milliseconds: 30)],
        );
        addTearDown(follower.dispose);
        final port = await director.startDirectorServer(port: 0);
        await follower.connect('127.0.0.1', port);
        await director.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(follower.status, LiveSyncStatus.reconnecting);

        await follower.disconnect();
        await director.startDirectorServer(port: port);
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(follower.status, LiveSyncStatus.disconnected);
        expect(director.connectedFollowersCount, 0);
      });
    });
  });
}
