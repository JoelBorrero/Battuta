import 'dart:async';

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:battuta/features/sync/domain/services/cloud_sync_service.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service implements CloudSyncService {
  _Service(this.result);

  CloudSyncResult result;

  @override
  bool get isSyncing => false;

  @override
  DateTime? get lastSyncedAt => null;

  @override
  Future<CloudSyncResult> syncAll({String? teamId}) async => result;

  @override
  Future<CloudSyncResult> pushLocalChanges() async => result;

  @override
  Future<CloudSyncResult> pullRemoteChanges({String? teamId}) async => result;
}

/// Versions and setlists pulled by a sync reach the lists without a restart.
void main() {
  joinsInFlightSync();
  Song song(String id) => Song(
    id: id,
    title: 'Song $id',
    artist: 'A',
    key: 'G',
    tempo: 80,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('a sync that pulled rows reloads the repertoire', () async {
    final songs = InMemorySongRepository(initialSongs: [song('a')]);
    final service = _Service(CloudSyncResult.success());
    final container = ProviderContainer(
      overrides: [
        songRepositoryProvider.overrideWithValue(songs),
        setlistRepositoryProvider.overrideWithValue(
          InMemorySetlistRepository(),
        ),
        cloudSyncServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    expect((await container.read(repertoireProvider.future)).length, 1);

    // Nothing pulled: the list is left alone.
    await songs.saveSong(song('b'));
    await container.read(cloudSyncProvider.notifier).triggerSync();
    expect(container.read(repertoireProvider).value, hasLength(1));

    service.result = CloudSyncResult.success(pulledCount: 1);
    await container.read(cloudSyncProvider.notifier).triggerSync();
    expect((await container.read(repertoireProvider.future)).length, 2);
  });
}

class _SlowService implements CloudSyncService {
  final calls = <Completer<CloudSyncResult>>[];

  @override
  bool get isSyncing => calls.isNotEmpty;

  @override
  DateTime? get lastSyncedAt => null;

  @override
  Future<CloudSyncResult> syncAll({String? teamId}) {
    final c = Completer<CloudSyncResult>();
    calls.add(c);
    return c.future;
  }

  @override
  Future<CloudSyncResult> pushLocalChanges() => syncAll();

  @override
  Future<CloudSyncResult> pullRemoteChanges({String? teamId}) => syncAll();
}

/// Rapid taps on a "Syncing…" entry: the second trigger joins the first sync
/// instead of failing with "already active".
void joinsInFlightSync() {
  test('a trigger while a sync runs waits for the same result', () async {
    final service = _SlowService();
    final container = ProviderContainer(
      overrides: [cloudSyncServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(cloudSyncProvider.notifier);

    final first = notifier.triggerSync();
    final second = notifier.triggerSync();
    expect(service.calls, hasLength(1));
    expect(container.read(cloudSyncProvider).status, CloudSyncStatus.syncing);

    service.calls.single.complete(CloudSyncResult.success());
    expect((await first).isSuccess, isTrue);
    expect((await second).isSuccess, isTrue);
    expect(container.read(cloudSyncProvider).status, CloudSyncStatus.success);

    // Once finished, the next trigger starts a new sync.
    unawaited(notifier.triggerSync());
    expect(service.calls, hasLength(2));
  });
}
