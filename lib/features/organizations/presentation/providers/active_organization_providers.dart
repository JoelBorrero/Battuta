/// The organization and band the signed-in user is currently working in.
///
/// * [myOrganizationsProvider]: my non-archived organizations (cache first).
/// * [activeOrganizationProvider]: the persisted choice of this account, or
///   the first organization when there is none (or it disappeared).
/// * [activeBandIdProvider]: optional band filter; `null` means "All bands".
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the per-account choice of organization is persisted.
final activeOrganizationStorageProvider = Provider<ApiKeyStorage>(
  (ref) => SecureApiKeyStorage(),
);

String activeOrganizationStorageKey(String accountId) =>
    'battuta_active_org_$accountId';

/// The id of the signed-in account, `null` in local mode.
final currentAccountIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider.select((user) => user?.id)),
);

/// Organizations I belong to, archived ones hidden.
final myOrganizationsProvider = StreamProvider<List<Organization>>((ref) {
  if (ref.watch(currentAccountIdProvider) == null) {
    return Stream.value(const <Organization>[]);
  }
  return ref.watch(organizationRepositoryProvider).watchOrganizations();
});

/// The organization id picked by this account (persisted), if any.
class ActiveOrganizationSelection extends Notifier<String?> {
  @override
  String? build() {
    final accountId = ref.watch(currentAccountIdProvider);
    if (accountId == null) return null;
    _load(accountId);
    return null;
  }

  Future<void> _load(String accountId) async {
    try {
      final saved = await ref
          .read(activeOrganizationStorageProvider)
          .read(activeOrganizationStorageKey(accountId));
      // Ignore a late answer for an account that is no longer current.
      if (saved != null &&
          state == null &&
          ref.read(currentAccountIdProvider) == accountId) {
        state = saved;
      }
    } catch (_) {
      // Falls back to the first organization.
    }
  }

  Future<void> select(String organizationId) async {
    state = organizationId;
    final accountId = ref.read(currentAccountIdProvider);
    if (accountId == null) return;
    try {
      await ref
          .read(activeOrganizationStorageProvider)
          .write(activeOrganizationStorageKey(accountId), organizationId);
    } catch (_) {
      // Kept in memory for this run.
    }
  }
}

final activeOrganizationSelectionProvider =
    NotifierProvider<ActiveOrganizationSelection, String?>(
      ActiveOrganizationSelection.new,
    );

/// The active organization; `null` in local mode or with no organization.
final activeOrganizationProvider = Provider<Organization?>((ref) {
  final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
  if (organizations.isEmpty) return null;
  final selected = ref.watch(activeOrganizationSelectionProvider);
  return organizations.firstWhere(
    (o) => o.id == selected,
    orElse: () => organizations.first,
  );
});

final activeOrganizationIdProvider = Provider<String?>(
  (ref) => ref.watch(activeOrganizationProvider.select((o) => o?.id)),
);

/// Members of the active organization (deactivated ones included).
final activeMembersProvider = StreamProvider<List<OrganizationMember>>((ref) {
  final id = ref.watch(activeOrganizationIdProvider);
  if (id == null) return Stream.value(const <OrganizationMember>[]);
  return ref.watch(organizationRepositoryProvider).watchMembers(id);
});

final activeBandsProvider = StreamProvider<List<Band>>((ref) {
  final id = ref.watch(activeOrganizationIdProvider);
  if (id == null) return Stream.value(const <Band>[]);
  return ref.watch(organizationRepositoryProvider).watchBands(id);
});

final activeBandMembersProvider = StreamProvider<List<BandMember>>((ref) {
  final id = ref.watch(activeOrganizationIdProvider);
  if (id == null) return Stream.value(const <BandMember>[]);
  return ref.watch(organizationRepositoryProvider).watchBandMembers(id);
});

/// Band filter of the active organization (`null` = all bands).
class ActiveBandId extends Notifier<String?> {
  @override
  String? build() {
    // A different organization starts with "All bands".
    ref.watch(activeOrganizationIdProvider);
    return null;
  }

  void select(String? bandId) => state = bandId;
}

final activeBandIdProvider = NotifierProvider<ActiveBandId, String?>(
  ActiveBandId.new,
);

/// The band filter, `null` for "All bands" (or when the band is gone).
final activeBandProvider = Provider<Band?>((ref) {
  final id = ref.watch(activeBandIdProvider);
  if (id == null) return null;
  final bands = ref.watch(activeBandsProvider).value ?? const [];
  for (final band in bands) {
    if (band.id == id) return band;
  }
  return null;
});

/// My membership in the active organization.
final currentMemberProvider = Provider<OrganizationMember?>((ref) {
  final me = ref.watch(currentAccountIdProvider);
  if (me == null) return null;
  final members = ref.watch(activeMembersProvider).value ?? const [];
  for (final member in members) {
    if (member.userId == me && member.isActive) return member;
  }
  return null;
});

/// Local mode and "no organization yet" are a personal library (admin);
/// inside an organization only its admins are.
final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final organization = ref.watch(activeOrganizationProvider);
  if (organization == null) return true;
  return organization.isAdmin;
});

/// Whether I administer [organizationId] (active, non-archived memberships).
/// Used by the data layer for organization content such as setlists; it is
/// `false` for any organization I am not an admin of, including unknown ones.
final organizationAdminCheckProvider = Provider<bool Function(String)>((ref) {
  final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
  final admin = {
    for (final organization in organizations)
      if (organization.isAdmin) organization.id,
  };
  return admin.contains;
});
