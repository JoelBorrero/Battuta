/// The versions each organization plays (`organization_repertoire`).
///
/// Reads come from the offline cache; writes and the candidate search need a
/// connection (offline they return `Left` with `BackendErrorCode.offline`).
/// Nothing here throws.
library;

import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class OrganizationRepertoireRepository {
  /// The repertoire of one organization; refreshes in the background.
  Stream<List<RepertoireEntry>> watchRepertoire(String organizationId);

  /// The cached repertoire of every organization of the account.
  Stream<List<RepertoireEntry>> watchAllRepertoire();

  Future<Result<Unit>> refreshRepertoire(String organizationId);

  /// Admins only: adds [candidate] to the repertoire.
  Future<Result<RepertoireEntry>> addToRepertoire(
    String organizationId,
    RepertoireCandidate candidate,
  );

  /// Admins only: removes the version from the repertoire (setlist entries
  /// that use it keep their snapshot).
  Future<Result<Unit>> removeFromRepertoire(
    String organizationId,
    String versionId,
  );

  /// Versions visible to the organization (shared with it, or public) that
  /// match [query] (title or artist), the caller's own first. Online only.
  Future<Result<List<RepertoireCandidate>>> searchCandidates(
    String organizationId,
    String query,
  );
}
