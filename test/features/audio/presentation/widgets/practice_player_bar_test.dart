import 'package:battuta/features/audio/presentation/widgets/practice_player_bar.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleSong = Song(
    id: 'song-audio-1',
    title: 'Way Maker',
    artist: 'Sinach',
    key: 'E',
    tempo: 68,
    sections: const [
      SongSection(id: 's1', name: 'Verse 1', orderIndex: 0),
      SongSection(id: 's2', name: 'Chorus', orderIndex: 1),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: PracticePlayerBar(song: sampleSong),
        ),
      ),
    );
  }

  group('PracticePlayerBar', () {
    testWidgets('renders playback title, scrub slider, and tempo metronome', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Way Maker'), findsOneWidget);
      expect(find.textContaining('68 BPM'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byTooltip('Metronome Click (68 BPM)'), findsOneWidget);
    });

    testWidgets('toggles play and pause state on button tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final playBtn = find.byIcon(Icons.play_arrow);
      await tester.tap(playBtn);
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('opens attach audio dialog and attaches track name', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Attach Audio Track'));
      await tester.pumpAndSettle();

      expect(find.text('Attach Reference Audio'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Attach Track'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Acoustic_Guide_Track.mp3'), findsOneWidget);
    });
  });
}

