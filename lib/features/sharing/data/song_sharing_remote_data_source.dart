/// Thin Supabase calls for song sharing: other versions, public search, song
/// search and fork. Every method throws a typed `Failure`; the repository
/// turns that into an `Either`.
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// The backend made the fork ([row] is what the RPC returned) but reading the
/// full version back failed ([cause]). The fork exists: nothing may be forked
/// again.
class ForkReadFailed implements Exception {
  const ForkReadFailed({required this.row, required this.cause});

  final Map<String, dynamic> row;
  final Object cause;

  @override
  String toString() => 'The fork was made but could not be read: $cause';
}

abstract interface class SongSharingRemoteDataSource {
  Future<List<SongVersionListing>> fetchVersionsOfSong(String songWorkId);

  Future<List<SongVersionListing>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  });

  Future<SongWork> fetchSong(String songId);

  Future<List<SongSuggestion>> searchSongs(String query, {int limit = 8});

  /// A `song_versions` row with its song (`songs`) and `version_shares`.
  Future<Map<String, dynamic>> fetchVersionRow(String versionId);

  /// Forks through the backend and returns the new version's row (as
  /// [fetchVersionRow] does). Throws [ForkReadFailed] when the fork was made
  /// but the row could not be read back.
  Future<Map<String, dynamic>> forkVersion(String versionId, {String? label});
}

class SupabaseSongSharingRemoteDataSource extends SupabaseGateway
    implements SongSharingRemoteDataSource {
  SupabaseSongSharingRemoteDataSource(super.clientProvider);

  static const _listingColumns =
      'id, song_id, label, key, visibility, owner_id, '
      'forked_from_version_id, updated_at, songs!inner(title, artist), '
      'owner:profiles!owner_id(username, display_name, deactivated_at)';

  static const _versionRow =
      '*, songs(id, title, artist, created_by), version_shares(organization_id)';

  /// Characters that would break the `or(...)` filter grammar.
  static String _clean(String query) =>
      query.replaceAll(RegExp(r'[,()*%\\]'), ' ').trim();

  @override
  Future<List<SongVersionListing>> fetchVersionsOfSong(String songWorkId) =>
      run((c, _) async {
        final data = await c
            .from('song_versions')
            .select(_listingColumns)
            .eq('song_id', songWorkId)
            .order('updated_at', ascending: false)
            .order('id');
        return [
          for (final row in (data as List).cast<Map<String, dynamic>>())
            SongVersionListing.fromJson(row),
        ];
      });

  @override
  Future<List<SongVersionListing>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  }) => run((c, _) async {
    final text = _clean(query);
    var request = c
        .from('song_versions')
        .select(_listingColumns)
        .eq('visibility', 'public');
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
        SongVersionListing.fromJson(row),
    ];
  });

  @override
  Future<SongWork> fetchSong(String songId) => run((c, _) async {
    final row = await c
        .from('songs')
        .select('id, title, artist, created_by')
        .eq('id', songId)
        .maybeSingle();
    if (row == null) {
      throw BackendErrorCode.songNotFound.failure(
        message: 'Song "$songId" not found.',
      );
    }
    return SongWork.fromJson(row);
  });

  @override
  Future<List<SongSuggestion>> searchSongs(String query, {int limit = 8}) =>
      run((c, _) async {
        final data = await c.rpc(
          'search_songs',
          params: {'p_query': query, 'p_limit': limit},
        );
        return [
          for (final row in (data as List).cast<Map<String, dynamic>>())
            SongSuggestion.fromJson(row),
        ];
      });

  @override
  Future<Map<String, dynamic>> fetchVersionRow(String versionId) =>
      run((c, _) => _versionRowOf(c, versionId));

  Future<Map<String, dynamic>> _versionRowOf(
    supa.SupabaseClient c,
    String versionId,
  ) async {
    final row = await c
        .from('song_versions')
        .select(_versionRow)
        .eq('id', versionId)
        .maybeSingle();
    if (row == null) {
      throw BackendErrorCode.versionNotFound.failure(
        message: 'Version "$versionId" not found.',
      );
    }
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<Map<String, dynamic>> forkVersion(
    String versionId, {
    String? label,
  }) async {
    final row = await run((c, _) async {
      final created = await c.rpc(
        'fork_song_version',
        params: {'p_version_id': versionId, 'p_label': label},
      );
      return Map<String, dynamic>.from(created as Map);
    });
    // From here on the fork exists on the backend.
    try {
      return await fetchVersionRow(row['id'] as String);
    } on Failure catch (e) {
      throw ForkReadFailed(row: row, cause: e);
    }
  }
}
