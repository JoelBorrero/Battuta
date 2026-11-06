/// Battuta — Team Member Entity & Enums.
///
/// Models worship team and band members, instrument assignments,
/// vocal tessitura (range), and availability for service scheduling.
library;

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
}

/// Scheduling availability state for upcoming services and rehearsals.
enum AvailabilityStatus {
  available('Available'),
  scheduled('Scheduled'),
  unavailable('Unavailable');

  const AvailabilityStatus(this.displayName);
  final String displayName;
}

/// An immutable team member entity.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.vocalRange = VocalTessitura.none,
    this.availability = AvailabilityStatus.available,
    this.notes,
    this.email,
  });

  final String id;
  final String name;
  final TeamRole role;
  final VocalTessitura vocalRange;
  final AvailabilityStatus availability;
  final String? notes;
  final String? email;

  TeamMember copyWith({
    String? id,
    String? name,
    TeamRole? role,
    VocalTessitura? vocalRange,
    AvailabilityStatus? availability,
    String? notes,
    String? email,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      vocalRange: vocalRange ?? this.vocalRange,
      availability: availability ?? this.availability,
      notes: notes ?? this.notes,
      email: email ?? this.email,
    );
  }
}
