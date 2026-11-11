/// Thin Supabase calls for song sharing: other versions, public search, fork
/// and merge requests. Every method throws a typed `Failure`; the repository
/// turns that into an `Either`.
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

abstract interface class SongSharingRemoteDataSource {
  Future<List<SongVersionListing>> fetchVersionsOfSong(String songWorkId);

  Future<List<SongVersionListing>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  });

  Future<SongWork> fetchSong(String songId);

  Future<List<SongWork>> searchSongs(
    String query, {
    bool onlyMine = false,
    int limit = 20,
  });

  /// A `song_versions` row with its song (`songs`) and `version_shares`.
  Future<Map<String, dynamic>> fetchVersionRow(String versionId);

  /// Forks through the backend and returns the new version's row (as
  /// [fetchVersionRow] does).
  Future<Map<String, dynamic>> forkVersion(String versionId, {String? label});

  Future<SongMergeRequest> requestMerge(
    String sourceSongId,
    String targetSongId,
  );

  Future<SongMergeRequest> respondToMerge(
    String requestId, {
    required bool accept,
  });

  Future<SongMergeRequest> fetchMergeRequest(String requestId);

  Future<List<SongMergeRequest>> pendingMergeRequests();
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

  static const _mergeColumns =
      '*, requester:profiles!requested_by(username, display_name)';

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
    final resolved = await c.rpc('resolve_song', params: {'p_song': songId});
    final id = resolved is String ? resolved : songId;
    final row = await c
        .from('songs')
        .select('id, title, artist, created_by, merged_into_id')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      throw BackendErrorCode.songNotFound.failure(
        message: 'Song "$songId" not found.',
      );
    }
    return SongWork.fromJson(row);
  });

  @override
  Future<List<SongWork>> searchSongs(
    String query, {
    bool onlyMine = false,
    int limit = 20,
  }) => run((c, uid) async {
    final text = _clean(query);
    var request = c
        .from('songs')
        .select('id, title, artist, created_by, merged_into_id')
        .isFilter('merged_into_id', null);
    if (onlyMine) request = request.eq('created_by', uid);
    if (text.isNotEmpty) {
      request = request.or('title.ilike.*$text*,artist.ilike.*$text*');
    }
    final data = await request.order('title').order('id').limit(limit);
    return [
      for (final row in (data as List).cast<Map<String, dynamic>>())
        SongWork.fromJson(row),
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
  Future<Map<String, dynamic>> forkVersion(String versionId, {String? label}) =>
      run((c, _) async {
        final created = await c.rpc(
          'fork_song_version',
          params: {'p_version_id': versionId, 'p_label': label},
        );
        final id = (created as Map)['id'] as String;
        return _versionRowOf(c, id);
      });

  @override
  Future<SongMergeRequest> requestMerge(
    String sourceSongId,
    String targetSongId,
  ) => run((c, _) async {
    final created = await c.rpc(
      'request_song_merge',
      params: {'p_source_song': sourceSongId, 'p_target_song': targetSongId},
    );
    return SongMergeRequest.fromJson(Map<String, dynamic>.from(created as Map));
  });

  @override
  Future<SongMergeRequest> respondToMerge(
    String requestId, {
    required bool accept,
  }) => run((c, _) async {
    final updated = await c.rpc(
      'respond_to_song_merge',
      params: {'p_request_id': requestId, 'p_accept': accept},
    );
    return SongMergeRequest.fromJson(Map<String, dynamic>.from(updated as Map));
  });

  @override
  Future<SongMergeRequest> fetchMergeRequest(String requestId) =>
      run((c, _) async {
        final row = await c
            .from('song_merge_requests')
            .select(_mergeColumns)
            .eq('id', requestId)
            .maybeSingle();
        if (row == null) {
          throw BackendErrorCode.mergeRequestNotFound.failure(
            message: 'Merge request "$requestId" not found.',
          );
        }
        return SongMergeRequest.fromJson(row);
      });

  @override
  Future<List<SongMergeRequest>> pendingMergeRequests() => run((c, _) async {
    final data = await c
        .from('song_merge_requests')
        .select(_mergeColumns)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return [
      for (final row in (data as List).cast<Map<String, dynamic>>())
        SongMergeRequest.fromJson(row),
    ];
  });
}
