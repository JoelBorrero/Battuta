import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ids', () {
    test('recognizes UUIDs', () {
      expect(SyncPolicy.isUuid('3f2b8c4e-1a2b-4c3d-8e9f-0a1b2c3d4e5f'), isTrue);
      expect(SyncPolicy.isUuid('3F2B8C4E-1A2B-4C3D-8E9F-0A1B2C3D4E5F'), isTrue);
      expect(SyncPolicy.isUuid('song_1700000000000'), isFalse);
      expect(SyncPolicy.isUuid('seed-way-maker'), isFalse);
      expect(SyncPolicy.isUuid(''), isFalse);
    });

    test('sample data is local only and never claimed', () {
      expect(SyncPolicy.isLocalOnly('seed-way-maker'), isTrue);
      expect(SyncPolicy.isClaimable('seed-setlist-sunday'), isFalse);
      expect(SyncPolicy.isClaimable('song_1700000000000'), isTrue);
    });
  });

  group('timestamps', () {
    test('equal instants normalize to the same text', () {
      final a = SyncPolicy.normalizeTimestamp(
        '2026-11-10T10:00:00.123456+00:00',
      );
      final b = SyncPolicy.normalizeTimestamp(
        '2026-11-10T11:00:00.123456+01:00',
      );
      expect(a, b);
      expect(a, endsWith('Z'));
    });

    test('garbage does not throw', () {
      expect(SyncPolicy.normalizeTimestamp(null), isNotEmpty);
    });
  });

  group('push (last write wins on edit time)', () {
    final t0 = DateTime.utc(2026, 11, 10, 10).millisecondsSinceEpoch;
    const minute = 60 * 1000;

    PushDecision decide({
      required int local,
      required int remoteEdit,
      String known = '2026-11-10T09:00:00.000Z',
      String remote = '2026-11-10T10:05:00.000Z',
    }) => SyncPolicy.decidePush(
      localEditedMs: local,
      knownRemoteUpdatedAt: known,
      remoteUpdatedAt: remote,
      remoteEditedMs: remoteEdit,
    );

    test('unchanged remote: push', () {
      expect(
        SyncPolicy.decidePush(
          localEditedMs: t0,
          knownRemoteUpdatedAt: 'A',
          remoteUpdatedAt: 'A',
          remoteEditedMs: t0 + minute,
        ),
        PushDecision.push,
      );
    });

    test('remote edited after the local edit: remote wins', () {
      expect(
        decide(local: t0, remoteEdit: t0 + 5 * minute),
        PushDecision.remoteWins,
      );
    });

    test(
      'local edit later than a remote edit that synced first: local wins',
      () {
        // B edited at 10:00 and pushed at 10:05; A edited at 10:03.
        expect(
          decide(local: t0 + 3 * minute, remoteEdit: t0),
          PushDecision.push,
        );
      },
    );

    test('a bump that is no edit (merge) never beats a local edit', () {
      // The backend copy's edit time is old; only updated_at moved.
      expect(
        decide(local: t0, remoteEdit: t0 - 60 * minute),
        PushDecision.push,
      );
    });

    test('the same edit time pushes (nothing is lost)', () {
      expect(decide(local: t0, remoteEdit: t0), PushDecision.push);
    });

    test('never synced rows push', () {
      expect(
        SyncPolicy.decidePush(
          localEditedMs: t0,
          knownRemoteUpdatedAt: null,
          remoteUpdatedAt: '2026-11-10T09:00:00.000Z',
          remoteEditedMs: t0 - minute,
        ),
        PushDecision.push,
      );
    });
  });

  group('delete', () {
    final deletedAt = DateTime.utc(2026, 11, 10, 10).millisecondsSinceEpoch;
    const hour = 60 * 60 * 1000;

    test('wins when the row was not edited elsewhere', () {
      expect(
        SyncPolicy.decideDelete(
          deletedAtMs: deletedAt,
          knownRemoteUpdatedAt: 'A',
          remoteUpdatedAt: 'A',
          remoteEditedMs: deletedAt + hour,
        ),
        DeleteDecision.deleteRemote,
      );
    });

    test('wins against an older remote edit', () {
      expect(
        SyncPolicy.decideDelete(
          deletedAtMs: deletedAt,
          knownRemoteUpdatedAt: '2026-11-10T07:00:00.000Z',
          remoteUpdatedAt: '2026-11-10T11:00:00.000Z',
          remoteEditedMs: deletedAt - 2 * hour,
        ),
        DeleteDecision.deleteRemote,
      );
    });

    test('loses against a newer remote edit', () {
      expect(
        SyncPolicy.decideDelete(
          deletedAtMs: deletedAt,
          knownRemoteUpdatedAt: '2026-11-10T07:00:00.000Z',
          remoteUpdatedAt: '2026-11-10T11:00:00.000Z',
          remoteEditedMs: deletedAt + hour,
        ),
        DeleteDecision.keepRemote,
      );
    });
  });

  group('edit times', () {
    test('nextEditMs is the clock, but strictly after the previous edit', () {
      final now = DateTime.utc(2026, 11, 10, 10);
      final ms = now.millisecondsSinceEpoch;
      expect(SyncPolicy.nextEditMs(null, now: now), ms);
      expect(SyncPolicy.nextEditMs(ms - 5, now: now), ms);
      // Same millisecond (or a clock that went back): still increasing.
      expect(SyncPolicy.nextEditMs(ms, now: now), ms + 1);
      expect(SyncPolicy.nextEditMs(ms + 10, now: now), ms + 11);
    });

    test('edit time text round-trips with millisecond precision', () {
      const ms = 1794304800123;
      final text = SyncPolicy.editedAtText(ms);
      expect(text, endsWith('Z'));
      expect(SyncPolicy.timestampMs(text), ms);
    });
  });

  group('pull', () {
    SyncRow row({
      bool dirty = false,
      String? remote = 'A',
      DateTime? deleted,
    }) => SyncRow(
      id: 'x',
      isDirty: dirty,
      remoteUpdatedAt: remote,
      deletedAt: deleted,
    );

    test('applies new rows and out of date clean rows', () {
      expect(
        SyncPolicy.shouldApplyRemote(local: null, remoteUpdatedAt: 'B'),
        isTrue,
      );
      expect(
        SyncPolicy.shouldApplyRemote(local: row(), remoteUpdatedAt: 'B'),
        isTrue,
      );
    });

    test('skips unchanged rows, dirty rows and tombstones', () {
      expect(
        SyncPolicy.shouldApplyRemote(local: row(), remoteUpdatedAt: 'A'),
        isFalse,
      );
      expect(
        SyncPolicy.shouldApplyRemote(
          local: row(dirty: true),
          remoteUpdatedAt: 'B',
        ),
        isFalse,
      );
      expect(
        SyncPolicy.shouldApplyRemote(
          local: row(deleted: DateTime.now()),
          remoteUpdatedAt: 'B',
        ),
        isFalse,
      );
    });
  });

  group('reconcile', () {
    test('removes only synced, clean rows that are no longer visible', () {
      final local = [
        const SyncRow(id: 'visible', isDirty: false, remoteUpdatedAt: 'A'),
        const SyncRow(id: 'unshared', isDirty: false, remoteUpdatedAt: 'A'),
        const SyncRow(
          id: 'edited-locally',
          isDirty: true,
          remoteUpdatedAt: 'A',
        ),
        const SyncRow(id: 'never-pushed', isDirty: true, remoteUpdatedAt: null),
        const SyncRow(
          id: 'local-sample',
          isDirty: false,
          remoteUpdatedAt: null,
        ),
        SyncRow(
          id: 'tombstone',
          isDirty: true,
          remoteUpdatedAt: 'A',
          deletedAt: DateTime.now(),
        ),
      ];
      expect(SyncPolicy.staleIds(local: local, visibleIds: {'visible'}), [
        'unshared',
      ]);
    });

    test('an empty visible set removes every synced clean row', () {
      expect(
        SyncPolicy.staleIds(
          local: const [SyncRow(id: 'a', isDirty: false, remoteUpdatedAt: 'A')],
          visibleIds: {},
        ),
        ['a'],
      );
    });
  });

  test('chunk splits lists', () {
    expect(SyncPolicy.chunk([1, 2, 3, 4, 5], 2), [
      [1, 2],
      [3, 4],
      [5],
    ]);
    expect(SyncPolicy.chunk(<int>[], 3), isEmpty);
  });
}
