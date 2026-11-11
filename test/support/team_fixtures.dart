import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/misc.dart';

import 'fake_organization_repository.dart';
import 'fake_schedule_repository.dart';
import 'memory_storage.dart';

const meUser = AuthUser(id: 'u-me', email: 'me@example.com');

Organization org(
  String id,
  String name, {
  OrganizationRole role = OrganizationRole.admin,
  DateTime? archivedAt,
}) => Organization(id: id, name: name, myRole: role, archivedAt: archivedAt);

OrganizationMember member(
  String id,
  String userId,
  String name, {
  String orgId = 'org-1',
  OrganizationRole role = OrganizationRole.member,
  List<String> instruments = const [],
  String? minPitch,
  String? maxPitch,
  String? notes,
  DateTime? deactivatedAt,
}) => OrganizationMember(
  id: id,
  organizationId: orgId,
  userId: userId,
  role: role,
  instruments: instruments,
  minPitch: minPitch,
  maxPitch: maxPitch,
  notes: notes,
  username: name.toLowerCase().replaceAll(' ', '_'),
  displayName: name,
  deactivatedAt: deactivatedAt,
);

class _FixedSetlists extends SetlistsNotifier {
  _FixedSetlists(this._setlists);

  final List<Setlist> _setlists;

  @override
  List<Setlist> build() => _setlists;
}

/// Signed in as [meUser] with [repository], [schedules] (an empty calendar
/// by default), [setlists] and in-memory storage. [now] pins the clock of
/// the calendar.
List<Override> signedInOverrides(
  FakeOrganizationRepository repository, {
  MemoryStorage? storage,
  FakeScheduleRepository? schedules,
  List<Setlist> setlists = const [],
  DateTime? now,
}) => [
  currentUserProvider.overrideWithValue(meUser),
  organizationRepositoryProvider.overrideWithValue(repository),
  scheduleRepositoryProvider.overrideWithValue(
    schedules ?? FakeScheduleRepository(),
  ),
  setlistsProvider.overrideWith(() => _FixedSetlists(setlists)),
  if (now != null) calendarClockProvider.overrideWithValue(() => now),
  activeOrganizationStorageProvider.overrideWithValue(
    storage ?? MemoryStorage(),
  ),
];
