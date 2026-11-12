/// Data behind the organization profile page, for any organization I belong
/// to (not only the active one).
library;

import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/services/service_calendar_builder.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One of my (non-archived) organizations, `null` when it is not one of mine
/// (or not loaded yet).
final organizationByIdProvider = Provider.family<Organization?, String>((
  ref,
  organizationId,
) {
  final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
  for (final organization in organizations) {
    if (organization.id == organizationId) return organization;
  }
  return null;
});

final organizationMembersProvider = StreamProvider.autoDispose
    .family<List<OrganizationMember>, String>(
      (ref, organizationId) => ref
          .watch(organizationRepositoryProvider)
          .watchMembers(organizationId),
    );

final organizationBandsProvider = StreamProvider.autoDispose
    .family<List<Band>, String>(
      (ref, organizationId) =>
          ref.watch(organizationRepositoryProvider).watchBands(organizationId),
    );

final _eventsProvider = StreamProvider.autoDispose
    .family<List<CalendarEvent>, String>(
      (ref, id) => ref.watch(scheduleRepositoryProvider).watchEvents(id),
    );
final _schedulesProvider = StreamProvider.autoDispose
    .family<List<RecurringSchedule>, String>(
      (ref, id) => ref.watch(scheduleRepositoryProvider).watchSchedules(id),
    );
final _assignmentsProvider = StreamProvider.autoDispose
    .family<List<EventAssignment>, String>(
      (ref, id) => ref.watch(scheduleRepositoryProvider).watchAssignments(id),
    );
final _absencesProvider = StreamProvider.autoDispose
    .family<List<MemberAbsence>, String>(
      (ref, id) => ref.watch(scheduleRepositoryProvider).watchAbsences(id),
    );

/// The next service (today or later) of the organization, or `null`.
final organizationNextServiceProvider = Provider.autoDispose
    .family<ServiceEvent?, String>((ref, organizationId) {
      final services = buildServiceEvents(
        now: ref.watch(calendarClockProvider)(),
        events: ref.watch(_eventsProvider(organizationId)).value ?? const [],
        schedules:
            ref.watch(_schedulesProvider(organizationId)).value ?? const [],
        assignments:
            ref.watch(_assignmentsProvider(organizationId)).value ?? const [],
        absences:
            ref.watch(_absencesProvider(organizationId)).value ?? const [],
      );
      return services.isEmpty ? null : services.first;
    });
