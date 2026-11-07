import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_setlist_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftSetlistRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftSetlistRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftSetlistRepository (Offline Airplane Mode)', () {
    test('performs full setlist CRUD operations offline', () async {
      final now = DateTime.now();
      final setlist = Setlist(
        id: 'set-easter',
        title: 'Easter Sunday',
        description: 'Sunrise outdoor service',
        eventDate: now,
        items: [
          const SetlistItem(
            id: 'item-1',
            songId: 'song-1',
            orderIndex: 0,
            keyOverride: 'D',
            tempoOverride: 75,
            notes: 'Acoustic intro',
          ),
          const SetlistItem(
            id: 'item-2',
            songId: 'song-2',
            orderIndex: 1,
            notes: 'Segues directly without pause',
          ),
        ],
        tags: const ['Easter', 'Acoustic'],
        createdAt: now,
        updatedAt: now,
      );

      // Save
      final saveResult = await repository.saveSetlist(setlist);
      expect(saveResult.isRight(), isTrue);

      // Retrieve
      final getResult = await repository.getSetlistById('set-easter');
      expect(getResult.isRight(), isTrue);

      final retrieved = getResult.getOrElse((_) => throw 'Failed');
      expect(retrieved.id, equals(setlist.id));
      expect(retrieved.title, equals('Easter Sunday'));
      expect(retrieved.songCount, equals(2));
      expect(retrieved.items.first.keyOverride, equals('D'));
      expect(retrieved.items.first.tempoOverride, equals(75));
      expect(
        retrieved.items.last.notes,
        equals('Segues directly without pause'),
      );

      // Update
      final updated = setlist.copyWith(title: 'Easter Sunday - 2nd Service');
      await repository.saveSetlist(updated);

      final reloaded = (await repository.getSetlistById('set-easter'))
          .getOrElse((_) => throw 'Failed');
      expect(reloaded.title, equals('Easter Sunday - 2nd Service'));

      // Delete
      final deleteResult = await repository.deleteSetlist('set-easter');
      expect(deleteResult.isRight(), isTrue);

      final notFound = await repository.getSetlistById('set-easter');
      expect(notFound.isLeft(), isTrue);
    });

    test('watchAllSetlists streams reactive updates', () async {
      final stream = repository.watchAllSetlists();
      final listEmissions = <List<Setlist>>[];
      final sub = stream.listen(listEmissions.add);

      await pumpEventQueue();
      expect(listEmissions.last, isEmpty);

      final now = DateTime.now();
      await repository.saveSetlist(
        Setlist(id: 'set-1', title: 'Set 1', createdAt: now, updatedAt: now),
      );

      await pumpEventQueue();
      expect(listEmissions.last.length, equals(1));
      expect(listEmissions.last.first.title, equals('Set 1'));

      await sub.cancel();
    });
  });
}
