import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamGroup Entity', () {
    test('constructs with defaults and required fields', () {
      const group = TeamGroup(
        id: 'group-1',
        name: 'Band Alpha',
      );

      expect(group.id, equals('group-1'));
      expect(group.name, equals('Band Alpha'));
      expect(group.description, isNull);
      expect(group.colorValue, equals(0xFFE5A93C));
    });

    test('supports copyWith for partial immutability updates', () {
      const group = TeamGroup(
        id: 'group-1',
        name: 'Band Alpha',
        description: 'Original description',
        colorValue: 0xFF4A90E2,
      );

      final updated = group.copyWith(
        name: 'Band Beta',
        colorValue: 0xFF50E3C2,
      );

      expect(updated.id, equals('group-1'));
      expect(updated.name, equals('Band Beta'));
      expect(updated.description, equals('Original description'));
      expect(updated.colorValue, equals(0xFF50E3C2));
    });

    test('implements value equality with Equatable', () {
      const g1 = TeamGroup(
        id: 'group-1',
        name: 'Band Alpha',
        description: 'Arrangement team',
        colorValue: 0xFFE5A93C,
      );

      const g2 = TeamGroup(
        id: 'group-1',
        name: 'Band Alpha',
        description: 'Arrangement team',
        colorValue: 0xFFE5A93C,
      );

      const g3 = TeamGroup(
        id: 'group-2',
        name: 'Band Beta',
      );

      expect(g1, equals(g2));
      expect(g1 == g3, isFalse);
      expect(g1.hashCode, equals(g2.hashCode));
    });
  });
}
