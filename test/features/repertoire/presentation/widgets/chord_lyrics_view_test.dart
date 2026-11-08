import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/features/repertoire/presentation/widgets/karaoke_chord_alignment_modal.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testSong = Song(
    id: 'test-song-1',
    title: 'Grace Song',
    artist: 'Test Artist',
    key: 'G',
    tempo: 80,
    timeSignature: (4, 4),
    sections: const [
      SongSection(
        id: 'sec-1',
        name: 'Verse 1',
        orderIndex: 0,
        lyrics: '[G]Amazing [C]grace how [G]sweet the sound',
        chords: [
          ChordCell(root: 'G', quality: ChordQuality.major, beats: 4),
          ChordCell(root: 'C', quality: ChordQuality.major, beats: 4),
        ],
      ),
      SongSection(
        id: 'sec-2',
        name: 'Chorus',
        orderIndex: 1,
        lyrics: '',
        chords: [],
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildSubject({
    required Song song,
    int transpositionSemitones = 0,
    ValueChanged<Song>? onSongUpdated,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChordLyricsView(
            song: song,
            transpositionSemitones: transpositionSemitones,
            onSongUpdated: onSongUpdated ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ChordLyricsView', () {
    testWidgets('renders sections, chord badges, and lyrics tokens', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(song: testSong));
      await tester.pumpAndSettle();

      expect(find.text('Verse 1'), findsOneWidget);
      expect(find.text('G'), findsNWidgets(2)); // In lyrics [G] twice
      expect(find.text('C'), findsOneWidget); // In lyrics [C] once
      expect(find.text('Amazing'), findsOneWidget);
      expect(find.text('grace'), findsOneWidget);
    });

    testWidgets('renders empty placeholder for section with no lyrics', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(song: testSong));
      await tester.pumpAndSettle();

      expect(find.text('Chorus'), findsOneWidget);
      expect(
        find.textContaining('No lyrics or chord alignment for this section yet'),
        findsOneWidget,
      );
    });

    testWidgets('transposes chords when transpositionSemitones is applied', (
      tester,
    ) async {
      // Transpose up 2 semitones: G -> A, C -> D
      await tester.pumpWidget(
        buildSubject(song: testSong, transpositionSemitones: 2),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNWidgets(2));
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('tapping Align Chords opens KaraokeChordAlignmentModal', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(song: testSong));
      await tester.pumpAndSettle();

      // Tap first "Align Chords" button
      final alignButtons = find.widgetWithText(OutlinedButton, 'Align Chords');
      expect(alignButtons, findsWidgets);

      await tester.tap(alignButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(KaraokeChordAlignmentModal), findsOneWidget);
      expect(find.text('Karaoke Chord Alignment'), findsOneWidget);
    });
  });
}
