import 'dart:typed_data';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/scanner/data/services/image_capture_service.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/scanner/presentation/pages/scanner_page.dart';
import 'package:battuta/features/scanner/presentation/providers/omr_provider.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/scanner/presentation/widgets/scan_flow_modal.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockImageCaptureService extends Mock implements ImageCaptureService {}

class MockOmrRepository extends Mock implements OmrRepository {}

final kTransparent1x1Png = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockImageCaptureService mockCaptureService;
  late MockOmrRepository mockOmrRepo;

  setUp(() {
    mockCaptureService = MockImageCaptureService();
    mockOmrRepo = MockOmrRepository();
    when(() => mockCaptureService.captureFromCamera())
        .thenAnswer((_) async => kTransparent1x1Png);
    when(() => mockCaptureService.pickFromGallery())
        .thenAnswer((_) async => kTransparent1x1Png);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        imageCaptureServiceProvider.overrideWithValue(mockCaptureService),
        omrRepositoryProvider.overrideWithValue(mockOmrRepo),
      ],
      child: const MaterialApp(home: ScannerPage()),
    );
  }

  group('ScannerPage', () {
    testWidgets('renders camera and gallery action buttons enabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Turn paper into charts'), findsOneWidget);
      expect(find.byKey(const Key('open_camera_button')), findsOneWidget);
      expect(find.byKey(const Key('choose_gallery_button')), findsOneWidget);

      final cameraBtn = tester.widget<StageCard>(
        find.descendant(
          of: find.byKey(const Key('open_camera_button')),
          matching: find.byType(StageCard),
        ),
      );
      final galleryBtn = tester.widget<StageCard>(
        find.descendant(
          of: find.byKey(const Key('choose_gallery_button')),
          matching: find.byType(StageCard),
        ),
      );

      expect(cameraBtn.onTap, isNotNull);
      expect(galleryBtn.onTap, isNotNull);
    });

    for (final width in [320.0, 1180.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} wide', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final key in ['open_camera_button', 'choose_gallery_button']) {
          final size = tester.getSize(find.byKey(Key(key)));
          expect(size.height, greaterThanOrEqualTo(44));
        }
      });
    }

    testWidgets('tapping Capture from camera launches scan flow modal', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_camera_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanFlowModal), findsOneWidget);
      verify(() => mockCaptureService.captureFromCamera()).called(1);
    });

    testWidgets(
      'tapping Choose from photos launches scan flow modal with gallery picker',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('choose_gallery_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ScanFlowModal), findsOneWidget);
        verify(() => mockCaptureService.pickFromGallery()).called(1);
      },
    );

    testWidgets(
      'extracting score navigates to song detail and shows SnackBar',
      (tester) async {
        final inMemoryRepo = InMemorySongRepository(initialSongs: []);
        const score = Score(id: 'score-123', title: 'Way Maker');
        when(
          () => mockOmrRepo.extractFullLeadSheet(
            imageBytes: any(named: 'imageBytes'),
            mimeType: any(named: 'mimeType'),
          ),
        ).thenAnswer((_) async => const Right(score));

        final router = GoRouter(
          initialLocation: '/scanner',
          routes: [
            GoRoute(
              path: '/scanner',
              builder: (context, state) => const ScannerPage(),
            ),
            GoRoute(
              path: '/repertoire/:songId',
              builder: (context, state) => Scaffold(
                body: Text(
                  'Navigated to Song ${state.pathParameters['songId']}',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageCaptureServiceProvider.overrideWithValue(mockCaptureService),
              omrRepositoryProvider.overrideWithValue(mockOmrRepo),
              songRepositoryProvider.overrideWithValue(inMemoryRepo),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_camera_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ScanFlowModal), findsOneWidget);

        await tester.tap(find.byKey(const Key('scan_analyze_btn')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('open_in_repertoire_btn')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('open_in_repertoire_btn')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_in_repertoire_btn')));
        await tester.pumpAndSettle();

        // Verifies navigation occurred to the song detail page
        expect(find.text('Navigated to Song score-123'), findsOneWidget);
        expect(find.text('Added "Way Maker" to Repertoire!'), findsOneWidget);
      },
    );
  });
}
