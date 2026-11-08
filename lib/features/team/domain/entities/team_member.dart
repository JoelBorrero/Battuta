/// Battuta — Team Member Entity & Enums.
///
/// Models worship team and band members, instrument assignments,
/// vocal tessitura (range), and availability for service scheduling.
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
  drums('Drums / Percussion', 'Drums'),
  sound('Audio Engineer', 'Audio');

  const TeamRole(this.displayName, this.shortName);
  final String displayName;
  final String shortName;

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
      this == TeamRole.drums;
}

/// Standard vocal range / tessitura classification.
enum VocalTessitura {
  none('Instrumental', '-'),
  soprano('Soprano', 'S (C4–A5)'),
  alto('Alto', 'A (F3–D5)'),
  tenor('Tenor', 'T (B2–G4)'),
  baritone('Baritone', 'Bar (G2–E4)'),
  bass('Bass', 'B (E2–C4)');

  const VocalTessitura(this.displayName, this.rangeLabel);
  final String displayName;
  final String rangeLabel;

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

/// Scheduling availability state for upcoming services and rehearsals.
enum AvailabilityStatus {
  available('Available'),
  scheduled('Scheduled'),
  unavailable('Unavailable');

  const AvailabilityStatus(this.displayName);
  final String displayName;

  /// Localized display name.
  String localizedName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return displayName;
    return switch (this) {
      AvailabilityStatus.available => 'Disponible',
      AvailabilityStatus.scheduled => 'Programado',
      AvailabilityStatus.unavailable => 'No disponible',
    };
  }
}

/// An immutable team member entity.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.roles = const [TeamRole.keys],
    this.vocalRange = VocalTessitura.none,
    this.availability = AvailabilityStatus.available,
    this.notes,
    this.email,
    this.isAdmin = false,
    this.groupIds = const [],
  });

  final String id;
  final String name;
  final List<TeamRole> roles;

  /// Sub-teams and arrangement groups this member is part of.
  final List<String> groupIds;

  /// Primary or first role assigned to the member.
  TeamRole get role => roles.isNotEmpty ? roles.first : TeamRole.keys;

  final VocalTessitura vocalRange;
  final AvailabilityStatus availability;
  final String? notes;
  final String? email;

  /// Whether this member holds administrative permissions (creating songs,
  /// managing master schedules, and assigning replacements).
  final bool isAdmin;

  /// Whether the member has at least one vocal assignment (Lead Vocal or Backing Vocal).
  bool get hasVocalRole => roles.any((r) => r.isVocal);

  /// Whether the member has at least one musical instrument assignment.
  bool get hasInstrumentRole => roles.any((r) => r.isInstrument);

  TeamMember copyWith({
    String? id,
    String? name,
    List<TeamRole>? roles,
    TeamRole? role,
    VocalTessitura? vocalRange,
    AvailabilityStatus? availability,
    String? notes,
    String? email,
    bool? isAdmin,
    List<String>? groupIds,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      roles: roles ?? (role != null ? [role] : this.roles),
      vocalRange: vocalRange ?? this.vocalRange,
      availability: availability ?? this.availability,
      notes: notes ?? this.notes,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      groupIds: groupIds ?? this.groupIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(roles, other.roles) &&
          listEquals(groupIds, other.groupIds) &&
          vocalRange == other.vocalRange &&
          availability == other.availability &&
          notes == other.notes &&
          email == other.email &&
          isAdmin == other.isAdmin;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      Object.hashAll(roles) ^
      Object.hashAll(groupIds) ^
      vocalRange.hashCode ^
      availability.hashCode ^
      notes.hashCode ^
      email.hashCode ^
      isAdmin.hashCode;
}
