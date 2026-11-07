/// Battuta — Admin Schedule Alert Entity.
///
/// Models notifications delivered to the Administrator when a musician
/// cannot attend a scheduled service, allowing the director to assign
/// a substitute musician to cover the missing role.
library;

import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:equatable/equatable.dart';

class ScheduleAlert extends Equatable {
  const ScheduleAlert({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.memberId,
    required this.memberName,
    required this.role,
    this.reason = "Can't attend — role needs cover",
    required this.timestamp,
    this.isDismissed = false,
  });

  /// Unique alert ID.
  final String id;

  /// ID of the service event with the scheduling gap.
  final String eventId;

  /// Title of the event (e.g. "Sunday Morning Worship").
  final String eventTitle;

  /// Date and time of the event.
  final DateTime eventDate;

  /// ID of the member who is unavailable.
  final String memberId;

  /// Name of the unavailable member.
  final String memberName;

  /// The musical or vocal role needing coverage.
  final TeamRole role;

  /// Explanation (e.g. "Can't attend", "General availability is unavailable").
  final String reason;

  /// Timestamp when the alert occurred.
  final DateTime timestamp;

  /// Whether the admin has dismissed this notification without replacing.
  final bool isDismissed;

  ScheduleAlert copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? memberId,
    String? memberName,
    TeamRole? role,
    String? reason,
    DateTime? timestamp,
    bool? isDismissed,
  }) {
    return ScheduleAlert(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      role: role ?? this.role,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    eventTitle,
    eventDate,
    memberId,
    memberName,
    role,
    reason,
    timestamp,
    isDismissed,
  ];
}
