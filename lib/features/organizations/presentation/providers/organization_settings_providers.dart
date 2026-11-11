/// Data of the organization settings page.
library;

import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One of my organizations by id, archived ones included (the settings page
/// stays readable after the organization is archived); `null` when it is not
/// one of mine.
final organizationByIdProvider = StreamProvider.family<Organization?, String>((
  ref,
  organizationId,
) {
  if (ref.watch(currentAccountIdProvider) == null) {
    return Stream.value(null);
  }
  return ref
      .watch(organizationRepositoryProvider)
      .watchOrganizations(includeArchived: true)
      .map((all) => all.where((o) => o.id == organizationId).firstOrNull);
});

/// The open archive request of an organization, if any.
final organizationArchiveRequestProvider =
    StreamProvider.family<ArchiveRequest?, String>(
      (ref, organizationId) => ref
          .watch(organizationRepositoryProvider)
          .watchArchiveRequest(organizationId),
    );

/// Members (deactivated ones included) of any of my organizations.
final organizationMembersProvider =
    StreamProvider.family<List<OrganizationMember>, String>(
      (ref, organizationId) => ref
          .watch(organizationRepositoryProvider)
          .watchMembers(organizationId),
    );

/// The quota of an organization. Needs a connection: the error is the
/// `Failure` of the repository.
final organizationQuotaProvider = FutureProvider.autoDispose
    .family<OrganizationQuota, String>((ref, organizationId) async {
      final result = await ref
          .watch(organizationRepositoryProvider)
          .getQuota(organizationId);
      return result.fold((failure) => throw failure, (quota) => quota);
    });
