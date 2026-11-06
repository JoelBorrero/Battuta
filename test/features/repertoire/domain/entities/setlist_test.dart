import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Setlist and SetlistItem', () {
    test('SetlistItem serializes to and from JSON without loss', () {
      const item = SetlistItem(
        id: 'item-1',
        songId: 'song-123',
        orderIndex: 0,
        keyOverride: 'Bb',
        tempoOverride: 130,
        notes: 'Lead guitar starts with riff',
      );

      final json = item.toJson();
      final reloaded = SetlistItem.fromJson(json);

      expect(reloaded, equals(item));
      expect(reloaded.keyOverride, equals('Bb'));
      expect(reloaded.tempoOverride, equals(130));
      expect(reloaded.notes, equals('Lead guitar starts with riff'));
    });

    test('Setlist serializes to and from JSON preserving order and metadata', () {
      final now = DateTime.now();
      final setlist = Setlist(
        id: 'set-1',
        title: 'Sunday Morning Service',
        description: 'Easter special worship list',
        eventDate: now,
        items: [
          const SetlistItem(
            id: 'item-1',
            songId: 'song-1',
            orderIndex: 0,
            keyOverride: 'D',
          ),
          const SetlistItem(
            id: 'item-2',
            songId: 'song-2',
            orderIndex: 1,
          ),
        ],
        tags: const ['Sunday', 'Easter'],
        createdAt: now,
        updatedAt: now,
      );

      final json = setlist.toJson();
      final reloaded = Setlist.fromJson(json);

      expect(reloaded.id, equals(setlist.id));
      expect(reloaded.title, equals(setlist.title));
      expect(reloaded.description, equals(setlist.description));
      expect(reloaded.songCount, equals(2));
      expect(reloaded.items.first.keyOverride, equals('D'));
      expect(reloaded.tags, equals(['Sunday', 'Easter']));
    });

    test('copyWith updates properties and clears overrides', () {
      final now = DateTime.now();
      final setlist = Setlist(
        id: 's1',
        title: 'Old Title',
        description: 'Old Description',
        createdAt: now,
        updatedAt: now,
      );

      final updated = setlist.copyWith(title: 'New Title');
      expect(updated.title, equals('New Title'));
      expect(updated.description, equals('Old Description'));

      final clearedDesc = updated.copyWith(clearDescription: true);
      expect(clearedDesc.description, isNull);
    });
  });
}
