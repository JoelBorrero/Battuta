/// Battuta — Team Member Entity & Enums.
///
/// Presentation model of an organization member (see
/// `OrganizationMember` in the organizations feature): instrument roles, vocal
/// tessitura (stored as a min/max pitch range) and the bands they belong to.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Instrument or production role within the band or worship team.
enum TeamRole {
  director('Worship Director', 'Director'),
  leadVocal('Lead Vocalist', 'Lead Vocals'),
  backingVocal('Backing Vocalist', 'Vocals'),
  acousticGuitar('Acoustic Guitar', 'Acoustic'),
  electricGuitar('Electric Guitar', 'Electric'),
  bass('Bass Guitar', 'Bass'),
  keys('Keys / Piano', 'Keys'),
  synth('Synthesizer', 'Synth'),
  drums('Drums / Percussion', 'Drums'),
  sound('Audio Engineer', 'Audio');

  const TeamRole(this.displayName, this.shortName);
  final String displayName;
  final String shortName;

  /// The role stored for an instrument string of the backend, or `null` for
  /// an instrument this app does not know.
  static TeamRole? fromInstrument(String instrument) {
    for (final role in values) {
      if (role.name == instrument) return role;
    }
    return null;
  }

  /// Localized full display name (e.g. Spanish vs English).
  String localizedName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return displayName;
    return switch (this) {
      TeamRole.director => 'Director de Alabanza',
      TeamRole.leadVocal => 'Voz Principal',
      TeamRole.backingVocal => 'Voz de Apoyo',
      TeamRole.acousticGuitar => 'Guitarra Acústica',
      TeamRole.electricGuitar => 'Guitarra Eléctrica',
      TeamRole.bass => 'Bajo Eléctrico',
      TeamRole.keys => 'Teclados / Piano',
      TeamRole.synth => 'Sintetizador',
      TeamRole.drums => 'Batería / Percusión',
      TeamRole.sound => 'Ingeniero de Sonido',
    };
  }

  /// Localized short badge name.
  String localizedShortName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return shortName;
    return switch (this) {
      TeamRole.director => 'Director',
      TeamRole.leadVocal => 'Voz Princ.',
      TeamRole.backingVocal => 'Voces',
      TeamRole.acousticGuitar => 'Acústica',
      TeamRole.electricGuitar => 'Eléctrica',
      TeamRole.bass => 'Bajo',
      TeamRole.keys => 'Teclas',
      TeamRole.synth => 'Sint.',
      TeamRole.drums => 'Batería',
      TeamRole.sound => 'Audio',
    };
  }

  /// True if this role is a singing / vocal role.
  bool get isVocal =>
      this == TeamRole.leadVocal || this == TeamRole.backingVocal;

  /// True if this role is an instrument.
  bool get isInstrument =>
      this == TeamRole.acousticGuitar ||
      this == TeamRole.electricGuitar ||
      this == TeamRole.bass ||
      this == TeamRole.keys ||
      this == TeamRole.synth ||
      this == TeamRole.drums;
}

/// Standard vocal range / tessitura classification.
///
/// The backend stores a free-form `min_pitch` / `max_pitch` pair; each
/// tessitura maps to one such pair ([minPitch], [maxPitch]).
enum VocalTessitura {
  none('Instrumental', '-', null, null),
  soprano('Soprano', 'S (C4–A5)', 'C4', 'A5'),
  alto('Alto', 'A (F3–D5)', 'F3', 'D5'),
  tenor('Tenor', 'T (B2–G4)', 'B2', 'G4'),
  baritone('Baritone', 'Bar (G2–E4)', 'G2', 'E4'),
  bass('Bass', 'B (E2–C4)', 'E2', 'C4');

  const VocalTessitura(
    this.displayName,
    this.rangeLabel,
    this.minPitch,
    this.maxPitch,
  );
  final String displayName;
  final String rangeLabel;

  /// Lowest pitch of the range as stored by the backend (`null` for none).
  final String? minPitch;

  /// Highest pitch of the range as stored by the backend (`null` for none).
  final String? maxPitch;

  /// The tessitura whose range is exactly [minPitch] to [maxPitch]; any other
  /// pair (including no pitches) is [none].
  static VocalTessitura fromPitches(String? minPitch, String? maxPitch) {
    for (final tessitura in values) {
      if (tessitura != none &&
          tessitura.minPitch == minPitch &&
          tessitura.maxPitch == maxPitch) {
        return tessitura;
      }
    }
    return none;
  }

  /// Localized display name.
  String localizedName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return displayName;
    return switch (this) {
      VocalTessitura.none => 'Instrumental',
      VocalTessitura.soprano => 'Soprano',
      VocalTessitura.alto => 'Contralto',
      VocalTessitura.tenor => 'Tenor',
      VocalTessitura.baritone => 'Barítono',
      VocalTessitura.bass => 'Bajo',
    };
  }
}

/// An immutable roster entry (one member of the active organization).
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.userId,
    this.username,
    this.avatarPath,
    this.instruments = const [],
    this.minPitch,
    this.maxPitch,
    this.notes,
    this.isAdmin = false,
    this.isMe = false,
    this.groupIds = const [],
  });

  /// The organization member id (not the account id).
  final String id;

  /// Display name, falling back to the username.
  final String name;

  /// Account id of the person.
  final String? userId;
  final String? username;

  /// Object path of the person's photo (see `UserProfile.avatarPath`).
  final String? avatarPath;

  /// Instrument strings exactly as stored by the backend (including ones this
  /// app does not know, which are kept when roles are edited).
  final List<String> instruments;
  final String? minPitch;
  final String? maxPitch;
  final String? notes;

  /// Whether this member is an organization admin.
  final bool isAdmin;

  /// Whether this member is the signed-in user.
  final bool isMe;

  /// Bands this member belongs to.
  final List<String> groupIds;

  /// The instrument roles this app knows, in stored order.
  List<TeamRole> get roles => [
    for (final instrument in instruments) ?TeamRole.fromInstrument(instrument),
  ];

  /// Primary or first role assigned to the member.
  TeamRole get role => roles.isNotEmpty ? roles.first : TeamRole.keys;

  VocalTessitura get vocalRange =>
      VocalTessitura.fromPitches(minPitch, maxPitch);

  /// Whether the member has at least one vocal assignment (Lead Vocal or Backing Vocal).
  bool get hasVocalRole => roles.any((r) => r.isVocal);

  /// Whether the member has at least one musical instrument assignment.
  bool get hasInstrumentRole => roles.any((r) => r.isInstrument);

  /// The stored instrument list for [newRoles]: the new known roles followed
  /// by the instruments this app does not know.
  List<String> instrumentsFor(List<TeamRole> newRoles) => [
    for (final role in newRoles) role.name,
    for (final instrument in instruments)
      if (TeamRole.fromInstrument(instrument) == null) instrument,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          userId == other.userId &&
          username == other.username &&
          avatarPath == other.avatarPath &&
          listEquals(instruments, other.instruments) &&
          listEquals(groupIds, other.groupIds) &&
          minPitch == other.minPitch &&
          maxPitch == other.maxPitch &&
          notes == other.notes &&
          isAdmin == other.isAdmin &&
          isMe == other.isMe;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    userId,
    username,
    avatarPath,
    Object.hashAll(instruments),
    Object.hashAll(groupIds),
    minPitch,
    maxPitch,
    notes,
    isAdmin,
    isMe,
  );
}
