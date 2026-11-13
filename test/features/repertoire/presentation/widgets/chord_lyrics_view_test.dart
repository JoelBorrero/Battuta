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
    SongViewMode viewMode = SongViewMode.both,
    ValueChanged<Song>? onSongUpdated,
    double chartTextScale = 1.0,
    bool preferSharps = true,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChordLyricsView(
            song: song,
            transpositionSemitones: transpositionSemitones,
            viewMode: viewMode,
            chartTextScale: chartTextScale,
            preferSharps: preferSharps,
            onSongUpdated: onSongUpdated ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ChordLyricsView', () {
    testWidgets(
      'renders sections, chord badges, and lyrics tokens in Both mode',
      (tester) async {
        await tester.pumpWidget(buildSubject(song: testSong));
        await tester.pumpAndSettle();

        expect(find.text('Verse 1'), findsOneWidget);
        expect(find.text('G'), findsNWidgets(2)); // In lyrics [G] twice
        expect(find.text('C'), findsOneWidget); // In lyrics [C] once
        expect(find.text('Amazing'), findsOneWidget);
        expect(find.text('grace'), findsOneWidget);
      },
    );

    testWidgets('hides Align Chords when edits cannot be saved', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChordLyricsView(
                song: testSong,
                transpositionSemitones: 0,
                viewMode: SongViewMode.both,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amazing'), findsOneWidget);
      expect(find.text('Align Chords'), findsNothing);
    });

    testWidgets('shows Align Chords when edits can be saved', (tester) async {
      await tester.pumpWidget(buildSubject(song: testSong));
      await tester.pumpAndSettle();

      expect(find.text('Align Chords'), findsWidgets);
    });

    testWidgets(
      'renders empty placeholder for section with no lyrics in Both mode',
      (tester) async {
        await tester.pumpWidget(buildSubject(song: testSong));
        await tester.pumpAndSettle();

        expect(find.text('Chorus'), findsOneWidget);
        expect(
          find.textContaining(
            'No lyrics or chord alignment for this section yet',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders Lyrics Only mode with stripped lyrics and no chord badges',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(song: testSong, viewMode: SongViewMode.lyricsOnly),
        );
        await tester.pumpAndSettle();

        expect(find.text('Verse 1'), findsOneWidget);
        // Clean lyrics without brackets or isolated chords
        expect(find.text('Amazing grace how sweet the sound'), findsOneWidget);
        // Align Chords button should NOT be rendered in Lyrics Only mode
        expect(find.text('Align Chords'), findsNothing);
        // Section without lyrics displays instrumental badge
        expect(find.text('Chorus'), findsOneWidget);
        expect(find.text('Instrumental (No lyrics)'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Chords Only mode with progression blocks and no lyrics',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(song: testSong, viewMode: SongViewMode.chordsOnly),
        );
        await tester.pumpAndSettle();

        expect(find.text('Verse 1'), findsOneWidget);
        expect(find.text('G'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
        expect(find.text('4 beats'), findsNWidgets(2));
        // Lyrics text must NOT be rendered in Chords Only mode
        expect(find.textContaining('Amazing grace'), findsNothing);
        // Section without chords displays clean notice
        expect(find.text('Chorus'), findsOneWidget);
        expect(
          find.text('No chords entered for this section.'),
          findsOneWidget,
        );
      },
    );

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

    testWidgets('renders high-contrast off-white lyrics text in Dark Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChordLyricsView(
                song: testSong,
                transpositionSemitones: 0,
                viewMode: SongViewMode.both,
                onSongUpdated: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final amazingText = tester.widget<Text>(find.text('Amazing'));
      expect(amazingText.style?.color, equals(const Color(0xFFF2F2F2)));
    });

    testWidgets(
      'tapping Align Chords opens KaraokeChordAlignmentModal with readable words in Dark Mode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChordLyricsView(
                  song: testSong,
                  transpositionSemitones: 0,
                  viewMode: SongViewMode.both,
                  onSongUpdated: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap first "Align Chords" button
        final alignButtons = find.widgetWithText(
          OutlinedButton,
          'Align Chords',
        );
        expect(alignButtons, findsWidgets);

        await tester.tap(alignButtons.first);
        await tester.pumpAndSettle();

        expect(find.byType(KaraokeChordAlignmentModal), findsOneWidget);
        expect(find.text('Karaoke Chord Alignment'), findsOneWidget);

        // Verify that words inside the alignment modal are high-contrast off-white
        final modalWordFinder = find.descendant(
          of: find.byType(KaraokeChordAlignmentModal),
          matching: find.text('Amazing'),
        );
        final modalWordText = tester.widget<Text>(modalWordFinder);
        expect(modalWordText.style?.color, equals(const Color(0xFFF2F2F2)));
      },
    );

    testWidgets('chartTextScale scales chord and lyric text', (tester) async {
      await tester.pumpWidget(buildSubject(song: testSong));
      await tester.pumpAndSettle();
      final lyric = find.text('Amazing');
      final chord = find.text('G').first;
      final lyricBase = tester.getSize(lyric).width;
      final chordBase = tester.getSize(chord).width;

      await tester.pumpWidget(
        buildSubject(song: testSong, chartTextScale: 1.5),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(lyric).width, closeTo(lyricBase * 1.5, 1.0));
      expect(tester.getSize(chord).width, closeTo(chordBase * 1.5, 1.0));
    });

    testWidgets('1.6 scale does not overflow at 320 wide', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      for (final mode in SongViewMode.values) {
        await tester.pumpWidget(
          buildSubject(song: testSong, chartTextScale: 1.6, viewMode: mode),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$mode');
      }
    });

    testWidgets('preferSharps false spells a transposed chart with flats', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          song: testSong,
          transpositionSemitones: 1,
          preferSharps: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ab'), findsWidgets);
      expect(find.text('G#'), findsNothing);

      await tester.pumpWidget(
        buildSubject(song: testSong, transpositionSemitones: 1),
      );
      await tester.pumpAndSettle();
      expect(find.text('G#'), findsWidgets);
    });
  });
}
