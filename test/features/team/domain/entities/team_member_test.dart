import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VocalTessitura pitches', () {
    test('every tessitura round-trips through its min / max pitch', () {
      for (final t in VocalTessitura.values) {
        expect(VocalTessitura.fromPitches(t.minPitch, t.maxPitch), t);
      }
    });

    test('an unknown or partial range reads as instrumental', () {
      expect(VocalTessitura.fromPitches('C2', 'C6'), VocalTessitura.none);
      expect(VocalTessitura.fromPitches('C4', null), VocalTessitura.none);
      expect(VocalTessitura.fromPitches(null, null), VocalTessitura.none);
    });
  });

  group('TeamMember instruments', () {
    const member = TeamMember(
      id: 'm1',
      name: 'Ana',
      instruments: ['keys', 'theremin', 'leadVocal'],
    );

    test('known instruments become roles, unknown ones are ignored', () {
      expect(member.roles, [TeamRole.keys, TeamRole.leadVocal]);
      expect(member.hasVocalRole, isTrue);
      expect(member.hasInstrumentRole, isTrue);
    });

    test('editing roles keeps the instruments this app does not know', () {
      expect(member.instrumentsFor([TeamRole.drums]), ['drums', 'theremin']);
    });

    test('no instruments: no roles, primary role falls back to keys', () {
      const empty = TeamMember(id: 'm2', name: 'Bo');
      expect(empty.roles, isEmpty);
      expect(empty.role, TeamRole.keys);
      expect(empty.vocalRange, VocalTessitura.none);
    });

    test('equality covers the stored fields', () {
      expect(
        member,
        const TeamMember(
          id: 'm1',
          name: 'Ana',
          instruments: ['keys', 'theremin', 'leadVocal'],
        ),
      );
      expect(
        member == const TeamMember(id: 'm1', name: 'Ana', isMe: true),
        isFalse,
      );
    });
  });
}
