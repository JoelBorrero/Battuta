/// State behind the Profile page: my membership in each organization and the
/// writes about me (instruments, leaving).
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Band;

/// My active membership in [organizationId] (`null` while unknown, signed out
/// or when I am no longer a member).
final myMembershipProvider = StreamProvider.autoDispose
    .family<OrganizationMember?, String>((ref, organizationId) {
      final me = ref.watch(currentAccountIdProvider);
      if (me == null) return Stream.value(null);
      return ref
          .watch(organizationRepositoryProvider)
          .watchMembers(organizationId)
          .map((members) {
            for (final member in members) {
              if (member.userId == me && member.isActive) return member;
            }
            return null;
          });
    });

/// My instruments across all my organizations, without duplicates, in the
/// order of my organizations.
final myInstrumentsProvider = Provider<List<String>>((ref) {
  final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
  final instruments = <String>{};
  for (final organization in organizations) {
    final member = ref.watch(myMembershipProvider(organization.id)).value;
    if (member != null) instruments.addAll(member.instruments);
  }
  return instruments.toList(growable: false);
});

/// How many song versions are in my library.
final myVersionCountProvider = Provider<int>(
  (ref) => ref.watch(myLibraryProvider).value?.length ?? 0,
);

/// How many upcoming services I am assigned to (active organization).
final myUpcomingCountProvider = Provider<int>(
  (ref) => ref.watch(myServicesProvider).length,
);

/// The writes the Profile page makes about me.
class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  /// Saves [instruments] as my instruments in [member]'s organization. Members
  /// may update their own row; pitch range and notes stay untouched.
  Future<Either<Failure, Unit>> saveInstruments(
    OrganizationMember member,
    List<String> instruments,
  ) async {
    final result = await _ref
        .read(organizationRepositoryProvider)
        .updateMusicianProfile(
          member.organizationId,
          member.id,
          instruments: instruments,
        );
    return result.map((_) => unit);
  }

  /// Leaves [organizationId] (the server refuses it for the last admin).
  Future<Either<Failure, Unit>> leave(String organizationId) => _ref
      .read(organizationRepositoryProvider)
      .leaveOrganization(organizationId);
}

final profileActionsProvider = Provider<ProfileActions>(ProfileActions.new);
