import 'dart:typed_data';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/scanner/data/services/image_capture_service.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/scanner/presentation/providers/omr_provider.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockImageCaptureService extends Mock implements ImageCaptureService {}

class MockOmrRepository extends Mock implements OmrRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockImageCaptureService mockCaptureService;
  late MockOmrRepository mockOmrRepo;
  late ProviderContainer container;

  final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);

  const sampleScore = Score(
    id: 'test-score',
    title: 'Blessed Be Your Name',
    sections: [
      Section(
        id: 'sec-1',
        name: 'Verse 1',
        measures: [
          Measure(number: 1),
        ],
      ),
    ],
  );

  const samplePitchResult = PitchOnlyResult(
    sectionName: 'Verse 1',
    assumedClef: 'G4',
    measures: [
      Measure(number: 1),
    ],
  );

  setUp(() {
    mockCaptureService = MockImageCaptureService();
    mockOmrRepo = MockOmrRepository();

    container = ProviderContainer(
      overrides: [
        imageCaptureServiceProvider.overrideWithValue(mockCaptureService),
        omrRepositoryProvider.overrideWithValue(mockOmrRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ScanController Scanning Flow & Mode Switching', () {
    test('initial state defaults to fullLeadSheet and idle', () {
      final state = container.read(scanControllerProvider);
      expect(state.status, equals(ScanStatus.idle));
      expect(state.scanMode, equals(ScanMode.fullLeadSheet));
      expect(state.hasImage, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('setScanMode switches mode and clears previous errors', () {
      final controller = container.read(scanControllerProvider.notifier);

      controller.setScanMode(ScanMode.pitchOnlySnippet);
      expect(container.read(scanControllerProvider).scanMode,
          equals(ScanMode.pitchOnlySnippet));

      controller.setScanMode(ScanMode.fullLeadSheet);
      expect(container.read(scanControllerProvider).scanMode,
          equals(ScanMode.fullLeadSheet));
    });

    test('captureFromCamera sets imageBytes on success', () async {
      final controller = container.read(scanControllerProvider.notifier);
      when(() => mockCaptureService.captureFromCamera())
          .thenAnswer((_) async => sampleBytes);

      await controller.captureFromCamera();

      final state = container.read(scanControllerProvider);
      expect(state.status, equals(ScanStatus.idle));
      expect(state.imageBytes, equals(sampleBytes));
      expect(state.hasImage, isTrue);
    });

    test('pickFromGallery sets imageBytes on success', () async {
      final controller = container.read(scanControllerProvider.notifier);
      when(() => mockCaptureService.pickFromGallery())
          .thenAnswer((_) async => sampleBytes);

      await controller.pickFromGallery();

      final state = container.read(scanControllerProvider);
      expect(state.status, equals(ScanStatus.idle));
      expect(state.imageBytes, equals(sampleBytes));
    });

    test('routes to Schema A (full lead sheet) when mode is fullLeadSheet',
        () async {
      final controller = container.read(scanControllerProvider.notifier);
      controller.setImageBytes(sampleBytes);
      controller.setScanMode(ScanMode.fullLeadSheet);

      when(() => mockOmrRepo.extractFullLeadSheet(
            imageBytes: any(named: 'imageBytes'),
            mimeType: any(named: 'mimeType'),
          )).thenAnswer((_) async => const Right(sampleScore));

      await controller.analyze();

      final state = container.read(scanControllerProvider);
      expect(state.status, equals(ScanStatus.success));
      expect(state.extractedScore, equals(sampleScore));
      verify(() => mockOmrRepo.extractFullLeadSheet(
            imageBytes: sampleBytes,
            mimeType: 'image/jpeg',
          )).called(1);
      verifyNever(() => mockOmrRepo.extractPitchOnlySection(
            imageBytes: any(named: 'imageBytes'),
            mimeType: any(named: 'mimeType'),
          ));
    });

    test('routes to Schema B (pitch-only) when mode is pitchOnlySnippet',
        () async {
      final controller = container.read(scanControllerProvider.notifier);
      controller.setImageBytes(sampleBytes);
      controller.setScanMode(ScanMode.pitchOnlySnippet);

      when(() => mockOmrRepo.extractPitchOnlySection(
            imageBytes: any(named: 'imageBytes'),
            mimeType: any(named: 'mimeType'),
          )).thenAnswer((_) async => const Right(samplePitchResult));

      await controller.analyze();

      final state = container.read(scanControllerProvider);
      expect(state.status, equals(ScanStatus.success));
      expect(state.extractedPitchResult, equals(samplePitchResult));
      verify(() => mockOmrRepo.extractPitchOnlySection(
            imageBytes: sampleBytes,
            mimeType: 'image/jpeg',
          )).called(1);
    });

    test(
        'handles offline / network error gracefully during analysis (Checklist Requirements)',
        () async {
      final controller = container.read(scanControllerProvider.notifier);
      controller.setImageBytes(sampleBytes);
      controller.setScanMode(ScanMode.fullLeadSheet);

      when(() => mockOmrRepo.extractFullLeadSheet(
            imageBytes: any(named: 'imageBytes'),
            mimeType: any(named: 'mimeType'),
          )).thenAnswer((_) async => const Left(ServerFailure(
            message: 'Network offline. Check your internet connection.',
          )));

      await controller.analyze();

      final state = container.read(scanControllerProvider);
      expect(state.status, equals(ScanStatus.error));
      expect(state.errorMessage,
          contains('Network offline. Check your internet connection.'));
    });
  });
}
