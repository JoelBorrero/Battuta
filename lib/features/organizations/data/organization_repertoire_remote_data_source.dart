/// Thin Supabase calls for `organization_repertoire`.
///
/// Every method throws a typed `Failure` (see `BackendErrorCode`); the
/// repository turns that into an `Either`.
library;

import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';

abstract interface class OrganizationRepertoireRemoteDataSource {
  Future<List<RepertoireEntry>> fetchRepertoire(String organizationId);
  Future<void> addToRepertoire(String organizationId, String versionId);
  Future<void> removeFromRepertoire(String organizationId, String versionId);

  /// One page of the versions in the organization's reach (public or shared
  /// with it, filtered by the server) whose title or artist match [query].
  /// A page shorter than [limit] is the last one.
  Future<List<RepertoireCandidate>> searchCandidates(
    String organizationId,
    String query, {
    int limit = 100,
    int offset = 0,
  });
}

class SupabaseOrganizationRepertoireRemoteDataSource extends SupabaseGateway
    implements OrganizationRepertoireRemoteDataSource {
  SupabaseOrganizationRepertoireRemoteDataSource(super.clientProvider);

  static const _versionColumns =
      'id, label, key, owner_id, songs(title, artist), '
      'owner:profiles!owner_id(username, display_name, deactivated_at)';

  @override
  Future<List<RepertoireEntry>> fetchRepertoire(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('organization_repertoire')
            .select(
              'organization_id, version_id, added_by, created_at, '
              'song_versions($_versionColumns)',
            )
            .eq('organization_id', organizationId);
        return [
          for (final row in (data as List).cast<Map<String, dynamic>>())
            // A version the account cannot read has no snapshot: skip it.
            if (row['song_versions'] is Map) RepertoireEntry.fromJson(row),
        ];
      });

  @override
  Future<void> addToRepertoire(String organizationId, String versionId) =>
      run((c, uid) async {
        await c.from('organization_repertoire').insert({
          'organization_id': organizationId,
          'version_id': versionId,
          'added_by': uid,
        });
      });

  @override
  Future<void> removeFromRepertoire(String organizationId, String versionId) =>
      run((c, _) async {
        await c
            .from('organization_repertoire')
            .delete()
            .eq('organization_id', organizationId)
            .eq('version_id', versionId);
      });

  @override
  Future<List<RepertoireCandidate>> searchCandidates(
    String organizationId,
    String query, {
    int limit = 100,
    int offset = 0,
  }) => run((c, _) async {
    // Characters that would break the `or(...)` filter grammar.
    final text = query.replaceAll(RegExp(r'[,()*%\\]'), ' ').trim();
    final shares = await c
        .from('version_shares')
        .select('version_id')
        .eq('organization_id', organizationId);
    final sharedIds = [
      for (final row in (shares as List).cast<Map<String, dynamic>>())
        row['version_id'] as String,
    ];
    // Visibility is decided by the server: public, or shared with this
    // organization. Nothing is cut off on the client.
    final reach = sharedIds.isEmpty
        ? 'visibility.eq.public'
        : 'visibility.eq.public,'
              'and(visibility.eq.organizations,id.in.(${sharedIds.join(',')}))';
    var request = c
        .from('song_versions')
        .select(
          'visibility, version_shares(organization_id), '
                  '$_versionColumns'
              .replaceFirst('songs(', 'songs!inner('),
        )
        .or(reach);
    if (text.isNotEmpty) {
      request = request.or(
        'title.ilike.*$text*,artist.ilike.*$text*',
        referencedTable: 'songs',
      );
    }
    final data = await request
        .order('updated_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return [
      for (final row in (data as List).cast<Map<String, dynamic>>())
        RepertoireCandidate.fromJson(row),
    ];
  });
}
