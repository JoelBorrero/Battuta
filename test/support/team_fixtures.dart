import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:flutter_riverpod/misc.dart';

import 'fake_organization_repository.dart';
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

/// Signed in as [meUser] with [repository] and in-memory storage.
List<Override> signedInOverrides(
  FakeOrganizationRepository repository, {
  MemoryStorage? storage,
}) => [
  currentUserProvider.overrideWithValue(meUser),
  organizationRepositoryProvider.overrideWithValue(repository),
  activeOrganizationStorageProvider.overrideWithValue(
    storage ?? MemoryStorage(),
  ),
];
