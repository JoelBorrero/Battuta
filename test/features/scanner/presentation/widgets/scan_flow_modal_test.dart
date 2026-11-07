import 'dart:typed_data';

import 'package:battuta/features/scanner/data/services/image_capture_service.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/scanner/presentation/providers/omr_provider.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/scanner/presentation/widgets/scan_flow_modal.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImageCaptureService extends Mock implements ImageCaptureService {}

class MockOmrRepository extends Mock implements OmrRepository {}

class FakeScanController extends ScanController {
  FakeScanController({
    required this.initialState,
    super.captureService,
    super.omrRepository,
  });

  final ScanState initialState;

  @override
  ScanState build() => initialState;
}

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImageCaptureService mockCaptureService;
  late MockOmrRepository mockOmrRepo;

  setUp(() {
    mockCaptureService = MockImageCaptureService();
    mockOmrRepo = MockOmrRepository();
  });

  Widget buildTestWidget({required Widget child, ScanState? initialState}) {
    return ProviderScope(
      overrides: [
        imageCaptureServiceProvider.overrideWithValue(mockCaptureService),
        omrRepositoryProvider.overrideWithValue(mockOmrRepo),
        if (initialState != null)
          scanControllerProvider.overrideWith(
            () => FakeScanController(
              initialState: initialState,
              captureService: mockCaptureService,
              omrRepository: mockOmrRepo,
            ),
          ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('ScanFlowModal (iPadOS & macOS checklist requirements)', () {
    testWidgets('renders mode segments and image selection buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(child: const ScanFlowModal()));

      expect(find.text('Scan Sheet Music'), findsOneWidget);
      expect(find.text('Full Sheet (Schema A)'), findsOneWidget);
      expect(find.text('Staff Snippet (Schema B)'), findsOneWidget);
      expect(find.byKey(const Key('scan_camera_btn')), findsOneWidget);
      expect(find.byKey(const Key('scan_gallery_btn')), findsOneWidget);
    });

    testWidgets('renders loading overlay when analyzing with Gemini', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: ScanState(
            status: ScanStatus.analyzing,
            imageBytes: kTransparent1x1Png,
          ),
          child: const ScanFlowModal(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analyzing sheet with Gemini AI...'), findsOneWidget);
    });

    testWidgets('displays error card and offline alert cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: const ScanState(
            status: ScanStatus.error,
            errorMessage: 'Network offline. Check your internet connection.',
          ),
          child: const ScanFlowModal(),
        ),
      );

      expect(find.text('Recognition Error'), findsOneWidget);
      expect(
        find.text('Network offline. Check your internet connection.'),
        findsOneWidget,
      );
    });

    testWidgets('displays success banner and triggers callback', (
      tester,
    ) async {
      const score = Score(id: '1', title: 'Amazing Grace');

      Score? receivedScore;

      await tester.pumpWidget(
        buildTestWidget(
          initialState: const ScanState(
            status: ScanStatus.success,
            extractedScore: score,
          ),
          child: ScanFlowModal(onScoreExtracted: (s) => receivedScore = s),
        ),
      );

      expect(find.text('Recognition Complete!'), findsOneWidget);
      expect(find.text('Title: Amazing Grace'), findsOneWidget);

      await tester.tap(find.text('Open in Repertoire'));
      await tester.pumpAndSettle();

      expect(receivedScore?.title, equals('Amazing Grace'));
    });
  });
}
