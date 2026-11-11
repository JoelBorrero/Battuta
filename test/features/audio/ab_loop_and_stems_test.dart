import 'dart:io';

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/audio/data/local_stem_storage_service.dart';
import 'package:battuta/features/audio/domain/models/ab_loop_region.dart';
import 'package:battuta/features/audio/presentation/providers/audio_practice_controller.dart';
import 'package:battuta/features/audio/presentation/widgets/practice_player_bar.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbLoopRegion Domain Tests', () {
    test('enforces sub-millisecond boundaries and minimum duration guard', () {
      // Valid: 1.5s to 4.25s (2,750,000 µs > 100,000 µs)
      final loop = AbLoopRegion(
        startMicros: 1500000,
        endMicros: 4250000,
        label: 'Guitar Solo',
      );

      expect(loop.durationMicros, 2750000);
      expect(loop.duration.inMilliseconds, 2750);
      expect(loop.startDuration.inMilliseconds, 1500);
      expect(loop.endDuration.inMilliseconds, 4250);

      // Rejects negative start
      expect(
        () => AbLoopRegion(startMicros: -1, endMicros: 1000000),
        throwsArgumentError,
      );

      // Rejects end <= start
      expect(
        () => AbLoopRegion(startMicros: 2000000, endMicros: 2000000),
        throwsArgumentError,
      );
      expect(
        () => AbLoopRegion(startMicros: 3000000, endMicros: 2000000),
        throwsArgumentError,
      );

      // Rejects duration < 100ms (100,000 µs)
      expect(
        () => AbLoopRegion(startMicros: 1000000, endMicros: 1050000),
        throwsArgumentError,
      );
    });

    test(
      'computes anti-click crossfade multipliers and zero-crossing windows',
      () {
        final loop = AbLoopRegion(
          startMicros: 1000000,
          endMicros: 3000000,
          fadeWindowMicros: 5000, // 5ms
        );

        // Fade-in multipliers
        expect(loop.calculateFadeInMultiplier(0), closeTo(0.0, 0.001));
        expect(loop.calculateFadeInMultiplier(5000), closeTo(1.0, 0.001));
        expect(loop.calculateFadeInMultiplier(6000), 1.0);

        // Fade-out multipliers
        expect(loop.calculateFadeOutMultiplier(0), closeTo(0.0, 0.001));
        expect(loop.calculateFadeOutMultiplier(5000), closeTo(1.0, 0.001));

        // Hardware zero-crossing samples: 44.1 kHz -> 221 samples, 48 kHz -> 240 samples
        expect(loop.calculateZeroCrossingSampleWindow(44100), 221);
        expect(loop.calculateZeroCrossingSampleWindow(48000), 240);
      },
    );

    test('serializes to and from JSON', () {
      final loop = AbLoopRegion(
        startMicros: 500000,
        endMicros: 1500000,
        fadeWindowMicros: 4000,
        label: 'Chorus Loop',
      );

      final json = loop.toJson();
      final restored = AbLoopRegion.fromJson(json);

      expect(restored, equals(loop));
      expect(restored.label, 'Chorus Loop');
    });
  });

  group('LocalStemStorageService Tests', () {
    late Directory tempDir;
    late LocalStemStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('battuta_stems_test_');
      service = LocalStemStorageService(baseDirResolver: () => tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves, registers, and loads multi-track backing stems', () async {
      final stems = [
        const StemTrack(
          id: 's_click',
          name: 'Click',
          filePath: '/stems/click.wav',
          volume: 0.9,
        ),
        const StemTrack(
          id: 's_guide',
          name: 'Guide',
          filePath: '/stems/guide.wav',
          volume: 0.8,
        ),
        const StemTrack(
          id: 's_keys',
          name: 'Keys',
          filePath: '/stems/keys.wav',
          volume: 1.0,
        ),
        const StemTrack(
          id: 's_bass',
          name: 'Bass',
          filePath: '/stems/bass.wav',
          volume: 1.0,
        ),
        const StemTrack(
          id: 's_drums',
          name: 'Drums',
          filePath: '/stems/drums.wav',
          volume: 1.0,
        ),
      ];

      await service.saveStemsForSong('song-101', stems);
      final loaded = await service.getStemsForSong('song-101');

      expect(loaded.length, 5);
      expect(loaded.map((s) => s.name).toList(), [
        'Click',
        'Guide',
        'Keys',
        'Bass',
        'Drums',
      ]);

      // Update one stem
      final updatedKeys = loaded[2].copyWith(volume: 0.6, isMuted: true);
      await service.registerStemTrack('song-101', updatedKeys);

      final reloaded = await service.getStemsForSong('song-101');
      expect(reloaded[2].volume, 0.6);
      expect(reloaded[2].isMuted, isTrue);

      // Delete a stem
      await service.deleteStemTrack('song-101', 's_bass');
      final afterDelete = await service.getStemsForSong('song-101');
      expect(afterDelete.length, 4);
      expect(afterDelete.any((s) => s.id == 's_bass'), isFalse);

      // Clear all
      await service.clearAllStems('song-101');
      final cleared = await service.getStemsForSong('song-101');
      expect(cleared, isEmpty);
    });
  });

  group('PracticePlayerBar A/B Loop Widget Tests', () {
    final sampleSong = Song(
      id: 'song-ab-1',
      title: 'Tu Fidelidad',
      artist: 'Marcos Witt',
      key: 'D',
      tempo: 72,
      sections: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Widget buildSubject() {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: PracticePlayerBar(song: sampleSong)),
        ),
      );
    }

    Future<void> pumpWithAudio(WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      ProviderScope.containerOf(tester.element(find.byType(PracticePlayerBar)))
          .read(audioPracticeControllerProvider.notifier)
          .attachAudioSource('guide.mp3', songId: sampleSong.id);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'toggles Loop A, Loop B, and Clear Loop with amber active styling',
      (tester) async {
        await pumpWithAudio(tester);

        final btnA = find.byKey(const ValueKey('ab_loop_point_a_button'));
        final btnB = find.byKey(const ValueKey('ab_loop_point_b_button'));

        expect(btnA, findsOneWidget);
        expect(btnB, findsOneWidget);
        expect(find.text('Set A'), findsOneWidget);
        expect(find.text('Set B'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ab_loop_clear_button')),
          findsNothing,
        );

        // Tap Set A -> sets loopPointA
        await tester.tap(btnA);
        await tester.pumpAndSettle();

        expect(find.textContaining('A: 0:00'), findsOneWidget);
        // Clear Loop button is now visible
        final clearBtn = find.byKey(const ValueKey('ab_loop_clear_button'));
        expect(clearBtn, findsOneWidget);

        // Tap Set B -> sets loopPointB
        await tester.tap(btnB);
        await tester.pumpAndSettle();

        expect(find.textContaining('B: 0:01'), findsOneWidget);

        // Check button style of active Set A has amber background
        final buttonWidget = tester.widget<OutlinedButton>(btnA);
        final background = buttonWidget.style?.backgroundColor?.resolve({});
        expect(background, AppTheme.amberAccent);

        // Tap Clear Loop -> resets loop points
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        expect(find.text('Set A'), findsOneWidget);
        expect(find.text('Set B'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ab_loop_clear_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders A/B controls without overflow at 320x600 constraints',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await pumpWithAudio(tester);

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('ab_loop_point_a_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('ab_loop_point_b_button')),
          findsOneWidget,
        );
      },
    );
  });
}
