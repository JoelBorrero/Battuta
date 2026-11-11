/// Which repertoire the Repertoire page shows: my library, or the repertoire
/// of one of my organizations.
///
/// * My library holds the versions I can edit (mine, and local-mode songs).
/// * An organization's repertoire holds versions of any owner; admins curate
///   it, members read it.
library;

import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The organization id picked in the scope switcher; `null` is my library.
class RepertoireScope extends Notifier<String?> {
  @override
  String? build() {
    // Another account starts on its own library.
    ref.watch(currentAccountIdProvider);
    return null;
  }

  void select(String? organizationId) => state = organizationId;
}

final repertoireScopeProvider = NotifierProvider<RepertoireScope, String?>(
  RepertoireScope.new,
);

/// The organization being shown, or `null` for my library. Falls back to my
/// library when the picked organization is no longer mine (left, removed or
/// archived).
final scopeOrganizationProvider = Provider<Organization?>((ref) {
  final id = ref.watch(repertoireScopeProvider);
  if (id == null) return null;
  final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
  for (final organization in organizations) {
    if (organization.id == id) return organization;
  }
  return null;
});

/// Whether the shown scope may be curated: my library always (I own what is
/// in it), an organization's repertoire and setlists only by its admins.
final canManageScopeProvider = Provider<bool>((ref) {
  final organization = ref.watch(scopeOrganizationProvider);
  return organization == null || organization.isAdmin;
});

/// The versions I can edit: mine and local-mode songs. Versions of other
/// owners cached from an organization's repertoire stay out of it.
final myLibraryProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final me = ref.watch(currentAccountIdProvider);
  return ref
      .watch(repertoireProvider)
      .whenData(
        (songs) => [
          for (final song in songs)
            if (song.isEditableBy(me)) song,
        ],
      );
});

/// The cached repertoire of one organization (refreshes when watched).
final organizationRepertoireProvider =
    StreamProvider.family<List<RepertoireEntry>, String>(
      (ref, organizationId) => ref
          .watch(organizationRepertoireRepositoryProvider)
          .watchRepertoire(organizationId),
    );

/// The cached repertoire entries of all my organizations (owner lookup).
final allRepertoireEntriesProvider = StreamProvider<List<RepertoireEntry>>((
  ref,
) {
  if (ref.watch(currentAccountIdProvider) == null) {
    return Stream.value(const <RepertoireEntry>[]);
  }
  return ref.watch(organizationRepertoireRepositoryProvider).watchAllRepertoire();
});

/// The cached entry for [versionId] in any of my organizations, if any.
/// It names the owner of a version I cannot edit.
final repertoireEntryOfVersionProvider =
    Provider.family<RepertoireEntry?, String>((ref, versionId) {
      final entries =
          ref.watch(allRepertoireEntriesProvider).value ?? const [];
      for (final entry in entries) {
        if (entry.versionId == versionId) return entry;
      }
      return null;
    });

/// Setlists of the shown scope: my personal ones, or the organization's.
final scopedSetlistsProvider = Provider<AsyncValue<List<Setlist>>>((ref) {
  final organization = ref.watch(scopeOrganizationProvider);
  return ref
      .watch(setlistsProvider)
      .whenData(
        (setlists) => [
          for (final setlist in setlists)
            if (setlist.organizationId == organization?.id) setlist,
        ],
      );
});
