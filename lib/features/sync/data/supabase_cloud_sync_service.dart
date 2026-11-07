/// Battuta — Supabase Cloud Sync Service Implementation.
///
/// Implements two-way synchronization between local Drift SQLite tables
/// and Supabase PostgreSQL with Last-Write-Wins (LWW) conflict resolution
/// and offline-first fault tolerance.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:battuta/features/sync/domain/services/cloud_sync_service.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseCloudSyncService implements CloudSyncService {
  SupabaseCloudSyncService({
    required this.db,
    required this.clientManager,
  });

  final AppDatabase db;
  final SupabaseClientManager clientManager;

  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  @override
  bool get isSyncing => _isSyncing;

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  supa.SupabaseClient? get _client => clientManager.client;

  @override
  Future<CloudSyncResult> syncAll({String? teamId}) async {
    if (_isSyncing) {
      return CloudSyncResult.failure(error: 'A sync cycle is already active.');
    }

    _isSyncing = true;
    try {
      final client = _client;
      if (client == null) {
        return CloudSyncResult.offline(
          reason: 'Supabase client is not configured. Local changes cached.',
        );
      }

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return CloudSyncResult.failure(
          error: 'Please sign in to sync with the cloud.',
        );
      }

      // Step 1: Push pending local changes to Supabase
      final pushResult = await pushLocalChanges();
      if (!pushResult.isSuccess && pushResult.isOffline) {
        return pushResult;
      }

      // Step 2: Pull newer remote changes from Supabase into Drift
      final pullResult = await pullRemoteChanges(teamId: teamId);
      if (!pullResult.isSuccess && pullResult.isOffline) {
        return pullResult;
      }

      _lastSyncedAt = DateTime.now();
      return CloudSyncResult.success(
        pushedCount: pushResult.pushedCount,
        pulledCount: pullResult.pulledCount,
        timestamp: _lastSyncedAt,
      );
    } on SocketException catch (e) {
      AppLogger.info('Cloud sync offline (SocketException): $e');
      return CloudSyncResult.offline();
    } on TimeoutException catch (e) {
      AppLogger.info('Cloud sync timeout: $e');
      return CloudSyncResult.offline(reason: 'Connection timed out.');
    } catch (e, st) {
      AppLogger.error('Cloud sync error: $e', error: e, stackTrace: st);
      return CloudSyncResult.failure(error: 'Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<CloudSyncResult> pushLocalChanges() async {
    final client = _client;
    if (client == null) return CloudSyncResult.offline();
    final user = client.auth.currentUser;
    if (user == null) {
      return CloudSyncResult.failure(error: 'User not signed in.');
    }

    int pushedCount = 0;

    try {
      // 1. Push Songs
      final localSongs = await db.select(db.songs).get();
      for (final song in localSongs) {
        final payload = {
          'id': song.id,
          'owner_id': user.id,
          'title': song.title,
          'artist': song.artist,
          'key': song.key,
          'tempo': song.tempo,
          'time_signature_beats': song.timeSignatureBeats,
          'time_signature_beat_value': song.timeSignatureBeatValue,
          'sections_json': song.sectionsJson,
          'tags_json': song.tagsJson,
          'cover_image_path': song.coverImagePath,
          'notes': song.notes,
          'updated_at': song.updatedAt.toUtc().toIso8601String(),
        };
        await client.from('songs').upsert(payload);
        pushedCount++;
      }

      // 2. Push Scores
      final localScores = await db.select(db.scores).get();
      for (final score in localScores) {
        dynamic timeSig = {'numerator': 4, 'denominator': 4};
        try {
          timeSig = jsonDecode(score.timeSignatureJson);
        } catch (_) {}

        dynamic sections = [];
        try {
          sections = jsonDecode(score.sectionsJson);
        } catch (_) {}

        dynamic metadata = {};
        try {
          metadata = jsonDecode(score.metadataJson);
        } catch (_) {}

        final payload = {
          'id': score.id,
          'owner_id': user.id,
          'song_id': score.songId,
          'title': score.title,
          'composer': score.composer,
          'artist': score.artist,
          'time_signature': timeSig,
          'key_signature': score.keySignature,
          'tempo': score.tempo,
          'sections': sections,
          'metadata': metadata,
          'updated_at': score.updatedAt.toUtc().toIso8601String(),
        };
        await client.from('scores').upsert(payload);
        pushedCount++;
      }

      // 3. Push Setlists
      final localSetlists = await db.select(db.setlists).get();
      for (final setlist in localSetlists) {
        final payload = {
          'id': setlist.id,
          'owner_id': user.id,
          'title': setlist.title,
          'description': setlist.description,
          'event_date': setlist.eventDate?.toUtc().toIso8601String(),
          'items_json': setlist.itemsJson,
          'tags_json': setlist.tagsJson,
          'updated_at': setlist.updatedAt.toUtc().toIso8601String(),
        };
        await client.from('setlists').upsert(payload);
        pushedCount++;
      }

      return CloudSyncResult.success(pushedCount: pushedCount);
    } on SocketException {
      return CloudSyncResult.offline();
    } catch (e) {
      return CloudSyncResult.failure(error: 'Push failed: $e');
    }
  }

  @override
  Future<CloudSyncResult> pullRemoteChanges({String? teamId}) async {
    final client = _client;
    if (client == null) return CloudSyncResult.offline();
    final user = client.auth.currentUser;
    if (user == null) {
      return CloudSyncResult.failure(error: 'User not signed in.');
    }

    int pulledCount = 0;

    try {
      // 1. Pull Songs
      var songQuery = client.from('songs').select();
      if (_lastSyncedAt != null) {
        songQuery = songQuery.gte(
          'updated_at',
          _lastSyncedAt!.toUtc().toIso8601String(),
        );
      }
      final remoteSongs = await songQuery;
      for (final data in (remoteSongs as List<dynamic>)) {
        final map = data as Map<String, dynamic>;
        final id = map['id'] as String;
        final remoteUpdatedAt = DateTime.tryParse(
          map['updated_at']?.toString() ?? '',
        ) ?? DateTime.now();

        // Check local Last-Write-Wins conflict resolution
        final local = await (db.select(db.songs)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
          await db.into(db.songs).insertOnConflictUpdate(
            SongsCompanion(
              id: Value(id),
              title: Value(map['title'] as String? ?? 'Untitled'),
              artist: Value(map['artist'] as String? ?? 'Unknown'),
              key: Value(map['key'] as String? ?? 'C'),
              tempo: Value(map['tempo'] as int? ?? 120),
              timeSignatureBeats: Value(map['time_signature_beats'] as int? ?? 4),
              timeSignatureBeatValue: Value(map['time_signature_beat_value'] as int? ?? 4),
              sectionsJson: Value(map['sections_json'] as String? ?? '[]'),
              tagsJson: Value(map['tags_json'] as String? ?? '[]'),
              coverImagePath: Value(map['cover_image_path'] as String?),
              notes: Value(map['notes'] as String?),
              createdAt: Value(
                DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                    remoteUpdatedAt,
              ),
              updatedAt: Value(remoteUpdatedAt),
            ),
          );
          pulledCount++;
        }
      }

      // 2. Pull Scores
      var scoreQuery = client.from('scores').select();
      if (_lastSyncedAt != null) {
        scoreQuery = scoreQuery.gte(
          'updated_at',
          _lastSyncedAt!.toUtc().toIso8601String(),
        );
      }
      final remoteScores = await scoreQuery;
      for (final data in (remoteScores as List<dynamic>)) {
        final map = data as Map<String, dynamic>;
        final id = map['id'] as String;
        final remoteUpdatedAt = DateTime.tryParse(
          map['updated_at']?.toString() ?? '',
        ) ?? DateTime.now();

        final local = await (db.select(db.scores)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
          final timeSig = map['time_signature'] is Map
              ? jsonEncode(map['time_signature'])
              : '{"numerator": 4, "denominator": 4}';
          final sections = map['sections'] is List
              ? jsonEncode(map['sections'])
              : '[]';
          final metadata = map['metadata'] is Map
              ? jsonEncode(map['metadata'])
              : '{}';

          await db.into(db.scores).insertOnConflictUpdate(
            ScoresCompanion(
              id: Value(id),
              songId: Value(map['song_id'] as String?),
              title: Value(map['title'] as String? ?? 'Untitled Score'),
              composer: Value(map['composer'] as String?),
              artist: Value(map['artist'] as String?),
              timeSignatureJson: Value(timeSig),
              keySignature: Value(map['key_signature'] as String? ?? 'C'),
              tempo: Value(map['tempo'] as int? ?? 120),
              sectionsJson: Value(sections),
              metadataJson: Value(metadata),
              updatedAt: Value(remoteUpdatedAt),
            ),
          );
          pulledCount++;
        }
      }

      // 3. Pull Setlists
      var setlistQuery = client.from('setlists').select();
      if (_lastSyncedAt != null) {
        setlistQuery = setlistQuery.gte(
          'updated_at',
          _lastSyncedAt!.toUtc().toIso8601String(),
        );
      }
      final remoteSetlists = await setlistQuery;
      for (final data in (remoteSetlists as List<dynamic>)) {
        final map = data as Map<String, dynamic>;
        final id = map['id'] as String;
        final remoteUpdatedAt = DateTime.tryParse(
          map['updated_at']?.toString() ?? '',
        ) ?? DateTime.now();

        final local = await (db.select(db.setlists)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
          await db.into(db.setlists).insertOnConflictUpdate(
            SetlistsCompanion(
              id: Value(id),
              title: Value(map['title'] as String? ?? 'Untitled Setlist'),
              description: Value(map['description'] as String?),
              eventDate: Value(DateTime.tryParse(map['event_date']?.toString() ?? '')),
              itemsJson: Value(map['items_json'] as String? ?? '[]'),
              tagsJson: Value(map['tags_json'] as String? ?? '[]'),
              createdAt: Value(
                DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                    remoteUpdatedAt,
              ),
              updatedAt: Value(remoteUpdatedAt),
            ),
          );
          pulledCount++;
        }
      }

      return CloudSyncResult.success(pulledCount: pulledCount);
    } on SocketException {
      return CloudSyncResult.offline();
    } catch (e) {
      return CloudSyncResult.failure(error: 'Pull failed: $e');
    }
  }
}
