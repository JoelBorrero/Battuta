import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Section', () {
    test('includes unique id and nullable externalSyncId for v1.1 sync (Checklist Requirement)', () {
      const syncUuid = 'propresenter-group-uuid-12345';
      const section = Section(
        id: 'sec-intro',
        name: 'Intro',
        externalSyncId: syncUuid,
        repeatCount: 2,
        orderIndex: 0,
      );

      expect(section.id, equals('sec-intro'));
      expect(section.name, equals('Intro'));
      expect(section.externalSyncId, equals(syncUuid));
      expect(section.isSynced, isTrue);

      const unlinkedSection = Section(
        id: 'sec-verse',
        name: 'Verse 1',
        externalSyncId: null,
      );
      expect(unlinkedSection.externalSyncId, isNull);
      expect(unlinkedSection.isSynced, isFalse);
    });

    test('calculates totalMeasures, totalTicks, and performance ticks with repeats', () {
      final measure1 = Measure(
        number: 1,
        events: [
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.parse('C4'),
            rhythmicValue: RhythmicValue.whole,
          ),
        ],
      );
      final measure2 = Measure(
        number: 2,
        events: [
          NoteEvent.note(
            id: 'e2',
            pitch: Pitch.parse('G4'),
            rhythmicValue: RhythmicValue.whole,
          ),
        ],
      );

      final chorus = Section(
        id: 'sec-chorus',
        name: 'Chorus',
        measures: [measure1, measure2],
        repeatCount: 2,
      );

      expect(chorus.totalMeasures, equals(2));
      expect(chorus.totalTicks, equals(3840)); // 1920 + 1920
      expect(chorus.totalPerformanceTicks, equals(7680)); // 3840 * 2
    });

    test('copyWith updates properties and clears externalSyncId', () {
      const section = Section(
        id: 's1',
        name: 'Bridge',
        externalSyncId: 'old-uuid',
      );

      final updated = section.copyWith(name: 'Bridge 2', repeatCount: 3);
      expect(updated.name, equals('Bridge 2'));
      expect(updated.repeatCount, equals(3));
      expect(updated.externalSyncId, equals('old-uuid'));

      final cleared = section.copyWith(clearExternalSyncId: true);
      expect(cleared.externalSyncId, isNull);
      expect(cleared.isSynced, isFalse);
    });

    test('equality and toString', () {
      const s1 = Section(id: 's1', name: 'Outro');
      const s2 = Section(id: 's1', name: 'Outro');
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1.toString(), contains('Outro'));
    });
  });
}
