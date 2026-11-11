/// Battuta — Admin Schedule Alert Entity.
///
/// A gap in the lineup of an upcoming service that an administrator should
/// cover: an assigned member declined, or has an absence on the day.
library;

import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:equatable/equatable.dart';

/// Why a lineup slot needs cover.
enum ScheduleAlertKind { declined, absent }

class ScheduleAlert extends Equatable {
  const ScheduleAlert({
    required this.kind,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.assignmentId,
    required this.memberId,
    required this.memberName,
    required this.instrument,
    this.reason,
  });

  final ScheduleAlertKind kind;
  final String eventId;
  final String eventTitle;

  /// Local date and time of the service.
  final DateTime eventDate;

  /// The assignment that needs cover.
  final String assignmentId;

  /// The organization member who declined or is away.
  final String memberId;
  final String memberName;

  /// The stored instrument string of the slot.
  final String instrument;

  /// The reason the member gave when declining.
  final String? reason;

  /// Stable id (kind, assignment and member): a different member declining
  /// the same slot later is a new alert.
  String get id => '${kind.name}_${assignmentId}_$memberId';

  TeamRole? get role => TeamRole.fromInstrument(instrument);

  @override
  List<Object?> get props => [
    kind,
    eventId,
    eventTitle,
    eventDate,
    assignmentId,
    memberId,
    memberName,
    instrument,
    reason,
  ];
}
