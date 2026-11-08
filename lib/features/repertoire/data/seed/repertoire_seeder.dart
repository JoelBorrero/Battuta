/// Battuta — Repertoire Sample Data Seeder.
///
/// Pre-populates sample songs and a ready-to-play setlist with complete
/// chord charts, lyrics, and rehearsal sections for new installs and onboarding.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/repositories/setlist_repository.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';

abstract final class RepertoireSeeder {
  static List<Song> getSampleSongs() {
    final now = DateTime.now();

    return [
      Song(
        id: 'seed-way-maker',
        title: 'Way Maker',
        artist: 'Sinach',
        key: 'E',
        tempo: 68,
        timeSignature: (4, 4),
        tags: const ['Worship', 'Contemporary', 'Faith'],
        sections: const [
          SongSection(
            id: 'wm-sec-1',
            name: 'Verso 1',
            orderIndex: 0,
            lyrics:
                '[E]Aquí estás, te [B]vemos mover\n[C#m]Te adoraré, [A]te adoraré\n[E]Aquí estás, o[B]brando en mí\n[C#m]Te adoraré, [A]te adoraré',
            chords: [
              ChordCell(root: 'E', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'B', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'C#', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'A', quality: ChordQuality.major, beats: 4),
            ],
          ),
          SongSection(
            id: 'wm-sec-2',
            name: 'Coro',
            orderIndex: 1,
            lyrics:
                '[E]Milagroso, abres [B]camino, cumples promesas\n[C#m]Luz en tinieblas, mi [A]Dios, así eres Tú',
            chords: [
              ChordCell(root: 'E', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'B', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'C#', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'A', quality: ChordQuality.major, beats: 4),
            ],
          ),
          SongSection(
            id: 'wm-sec-3',
            name: 'Puente',
            orderIndex: 2,
            lyrics:
                '[E]Aunque no pueda ver, [B]estás obrando\n[C#m]Aunque no pueda ver, [A]estás obrando\n[E]Siempre estás, [B]siempre estás o[C#m]brando [A]',
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
        id: 'seed-tu-fidelidad',
        title: 'Tu Fidelidad',
        artist: 'Marcos Witt',
        key: 'D',
        tempo: 72,
        timeSignature: (4, 4),
        tags: const ['Classic', 'Hymn', 'Adoration'],
        sections: const [
          SongSection(
            id: 'tf-sec-1',
            name: 'Verso 1',
            orderIndex: 0,
            lyrics:
                '[D]Tu fidelidad es [Bm]grande\n[Em]Tu fidelidad incomp[A7]arable [D]es\n[G]Nadie como [A]Tú, bendito [F#m]Dios [Bm]\n[Em]Grande es Tu fideli[A7]dad [D]',
            chords: [
              ChordCell(root: 'D', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'B', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'E', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'A', quality: ChordQuality.dominant7, beats: 4),
              ChordCell(root: 'D', quality: ChordQuality.major, beats: 4),
            ],
          ),
          SongSection(
            id: 'tf-sec-2',
            name: 'Coro',
            orderIndex: 1,
            lyrics:
                '[G]Nadie como [A]Tú, bendito [F#m]Dios [Bm]\n[Em]Grande es Tu fideli[A7]dad [D]',
            chords: [
              ChordCell(root: 'G', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'A', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'F#', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'B', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'E', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'A', quality: ChordQuality.dominant7, beats: 4),
              ChordCell(root: 'D', quality: ChordQuality.major, beats: 4),
            ],
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Song(
        id: 'seed-amazing-grace',
        title: 'Amazing Grace',
        artist: 'John Newton',
        key: 'G',
        tempo: 74,
        timeSignature: (3, 4),
        tags: const ['Traditional', 'Hymn'],
        sections: const [
          SongSection(
            id: 'ag-sec-1',
            name: 'Verse 1',
            orderIndex: 0,
            lyrics:
                '[G]Amazing grace how [C]sweet the [G]sound\nThat saved a [D]wretch like me\nI [G]once was lost, but [C]now am [G]found\nWas blind, but [D]now I [G]see',
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
    ];
  }

  static Setlist getSampleSetlist() {
    final now = DateTime.now();

    return Setlist(
      id: 'seed-setlist-sunday',
      title: 'Sunday Worship Service',
      description:
          'Main morning service setlist with Way Maker and Tu Fidelidad',
      eventDate: now.add(const Duration(days: 1)),
      tags: const ['Sunday', 'Main Service'],
      items: const [
        SetlistItem(
          id: 'item-1',
          songId: 'seed-way-maker',
          orderIndex: 0,
          notes: 'Full band intro with keys pad, build into Coro',
        ),
        SetlistItem(
          id: 'item-2',
          songId: 'seed-tu-fidelidad',
          orderIndex: 1,
          keyOverride: 'D',
          notes: 'Transition directly from Way Maker, acoustic guitar and strings lead',
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Seeds sample songs and setlist into the given repositories if they are empty.
  static Future<void> seedIfEmpty({
    required SongRepository songRepo,
    required SetlistRepository setlistRepo,
  }) async {
    final songsRes = await songRepo.getAllSongs();
    final songs = songsRes.getOrElse((_) => []);

    if (songs.isEmpty) {
      for (final song in getSampleSongs()) {
        await songRepo.saveSong(song);
      }
    }

    final setlistRes = await setlistRepo.getAllSetlists();
    final setlists = setlistRes.getOrElse((_) => []);

    if (setlists.isEmpty) {
      await setlistRepo.saveSetlist(getSampleSetlist());
    }
  }
}
