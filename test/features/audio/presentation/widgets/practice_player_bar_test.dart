import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:battuta/features/audio/presentation/widgets/practice_player_bar.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDemoModeNotifier extends DemoModeNotifier {
  _FakeDemoModeNotifier(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

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

  Widget buildSubject({bool demoMode = false}) {
    return ProviderScope(
      overrides: [
        demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(demoMode)),
      ],
      child: MaterialApp(
        home: Scaffold(body: PracticePlayerBar(song: sampleSong)),
      ),
    );
  }

  group('PracticePlayerBar - Empty / Non-Demo State', () {
    testWidgets(
      'renders No Reference Audio Attached when demo mode is off and no audio attached',
      (tester) async {
        await tester.pumpWidget(buildSubject(demoMode: false));
        await tester.pumpAndSettle();

        expect(find.text('No Reference Audio Attached'), findsOneWidget);
        expect(
          find.textContaining('Attach an MP3 or guide track'),
          findsOneWidget,
        );
        expect(find.text('Attach Audio'), findsOneWidget);
        expect(find.byTooltip('Metronome Click (68 BPM)'), findsOneWidget);
      },
    );

    testWidgets(
      'attaches track via dialog and unlocks active rehearsal player',
      (tester) async {
        await tester.pumpWidget(buildSubject(demoMode: false));
        await tester.pumpAndSettle();

        expect(find.text('Attach Audio'), findsOneWidget);
        await tester.tap(find.text('Attach Audio'));
        await tester.pumpAndSettle();

        expect(find.text('Attach Reference Audio'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Attach Track'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Acoustic_Guide_Track.mp3'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      },
    );

    testWidgets('renders empty state without overflow on narrow 320px screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(demoMode: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('No Reference Audio Attached'), findsOneWidget);
    });
  });

  group('PracticePlayerBar - Active / Demo Mode State', () {
    testWidgets(
      'renders playback title, scrub slider, and tempo metronome when demo mode is on',
      (tester) async {
        await tester.pumpWidget(buildSubject(demoMode: true));
        await tester.pumpAndSettle();

        expect(find.textContaining('Way Maker'), findsOneWidget);
        expect(find.textContaining('68 BPM'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byTooltip('Metronome Click (68 BPM)'), findsOneWidget);
      },
    );

    testWidgets('toggles play and pause state on button tap', (tester) async {
      await tester.pumpWidget(buildSubject(demoMode: true));
      await tester.pumpAndSettle();

      final playBtn = find.byIcon(Icons.play_arrow);
      await tester.tap(playBtn);
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets(
      'renders without overflow on narrow 320px screen and loop selected',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject(demoMode: true));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Select a section loop to ensure activeLoopSection chip doesn't overflow
        await tester.tap(find.byTooltip('Loop Section'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Loop: Chorus').last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Chorus'), findsWidgets);
      },
    );
  });
}
