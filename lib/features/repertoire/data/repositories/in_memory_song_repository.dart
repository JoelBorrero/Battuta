/// In-memory implementation of [SongRepository] for development and scaffolding.
///
/// Pre-populates a small sample repertoire so the app is immediately
/// usable and testable before ticket #86e3yy41r introduces the Drift local DB.
library;

import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory implementation of [SongRepository].
class InMemorySongRepository implements SongRepository {
  InMemorySongRepository({List<Song>? initialSongs}) {
    if (initialSongs != null) {
      for (final song in initialSongs) {
        _songs[song.id] = song;
      }
    } else {
      _seedDefaultSongs();
    }
  }

  final Map<String, Song> _songs = {};
  final _controller = StreamController<List<Song>>.broadcast();

  void _notify() {
    _controller.add(_songs.values.toList());
  }

  void _seedDefaultSongs() {
    final now = DateTime.now();
    final sampleSongs = [
      Song(
        id: 'song-1',
        title: 'Amazing Grace',
        artist: 'John Newton',
        key: 'G',
        tempo: 72,
        timeSignature: (3, 4),
        tags: ['Hymn', 'Classic'],
        sections: [
          const SongSection(
            id: 'sec-1',
            name: 'Verse 1',
            orderIndex: 0,
            repeatCount: 1,
            lyrics: 'Amazing grace how sweet the sound...',
            chords: [
              ChordCell(root: 'G', quality: ChordQuality.major, beats: 3),
              ChordCell(root: 'C', quality: ChordQuality.major, beats: 3),
              ChordCell(root: 'G', quality: ChordQuality.major, beats: 3),
              ChordCell(root: 'D', quality: ChordQuality.major, beats: 3),
            ],
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Song(
        id: 'song-2',
        title: 'Way Maker',
        artist: 'Sinach',
        key: 'E',
        tempo: 68,
        timeSignature: (4, 4),
        tags: ['Contemporary', 'Worship'],
        sections: [
          const SongSection(
            id: 'sec-2',
            name: 'Chorus',
            orderIndex: 0,
            repeatCount: 1,
            lyrics: 'Way maker, miracle worker, promise keeper...',
            chords: [
              ChordCell(root: 'E', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'B', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'C#', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'A', quality: ChordQuality.major, beats: 4),
            ],
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Song(
        id: 'song-3',
        title: 'Great Are You Lord',
        artist: 'All Sons & Daughters',
        key: 'A',
        tempo: 72,
        timeSignature: (6, 8),
        tags: ['Worship', 'Slow'],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final song in sampleSongs) {
      _songs[song.id] = song;
    }
  }

  @override
  Future<Either<Failure, List<Song>>> getAllSongs() async {
    return Right(_songs.values.toList());
  }

  @override
  Future<Either<Failure, Song>> getSongById(String id) async {
    final song = _songs[id];
    if (song != null) {
      return Right(song);
    }
    return Left(
      CacheFailure(
        message: 'Song with ID "$id" not found.',
        errorCode: BackendErrorCode.versionNotFound,
      ),
    );
  }

  @override
  Future<Either<Failure, Song>> saveSong(Song song) async {
    _songs[song.id] = song;
    _notify();
    return Right(song);
  }

  @override
  Future<Either<Failure, Song>> updateSharing(
    String id, {
    String? label,
    SongVisibility? visibility,
    List<String>? sharedOrganizationIds,
  }) async {
    final song = _songs[id];
    if (song == null) {
      return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
    }
    final newVisibility = visibility ?? song.visibility;
    final updated = song.copyWith(
      label: label?.trim().isNotEmpty ?? false ? label!.trim() : song.label,
      visibility: newVisibility,
      sharedOrganizationIds: newVisibility == SongVisibility.organizations
          ? (sharedOrganizationIds ?? song.sharedOrganizationIds)
          : const [],
    );
    _songs[id] = updated;
    _notify();
    return Right(updated);
  }

  @override
  Future<Either<Failure, Song>> moveToSong(
    String id, {
    required String songWorkId,
    required String title,
    required String artist,
    String? songCreatorId,
  }) async {
    final song = _songs[id];
    if (song == null) {
      return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
    }
    final moved = song.copyWith(
      songWorkId: songWorkId,
      title: title,
      artist: artist,
      songCreatorId: songCreatorId,
    );
    _songs[id] = moved;
    _notify();
    return Right(moved);
  }

  @override
  Future<Either<Failure, void>> deleteSong(String id) async {
    _songs.remove(id);
    _notify();
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Song>>> searchSongs(String query) async {
    final q = query.toLowerCase();
    final results = _songs.values.where((song) {
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q) ||
          song.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
    return Right(results);
  }

  @override
  Stream<List<Song>> watchAllSongs() async* {
    yield _songs.values.toList();
    yield* _controller.stream;
  }
}
