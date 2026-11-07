import 'dart:typed_data';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/scanner/data/repositories/gemini_omr_repository.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mocktail/mocktail.dart';

class MockApiKeyStorage extends Mock implements ApiKeyStorage {}

class MockGeminiOmrClient extends Mock implements GeminiOmrClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Schema.string());
  });

  late MockApiKeyStorage mockStorage;
  late ApiKeyService apiKeyService;
  late MockGeminiOmrClient mockClient;
  late GeminiOmrRepository repository;

  final sampleImageBytes = Uint8List.fromList([1, 2, 3, 4]);

  setUp(() {
    mockStorage = MockApiKeyStorage();
    apiKeyService = ApiKeyService(storage: mockStorage);
    mockClient = MockGeminiOmrClient();

    repository = GeminiOmrRepository(
      apiKeyService: apiKeyService,
      client: mockClient,
    );
  });

  group('GeminiOmrRepository.extractFullLeadSheet', () {
    test('returns PermissionFailure when API key is not configured', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => null);

      final result = await repository.extractFullLeadSheet(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<PermissionFailure>());
        expect(failure.message, contains('API key is not configured'));
      }, (_) => fail('Expected failure'));
    });

    test(
      'extracts full lead sheet and maps into valid Score on success',
      () async {
        when(() => mockStorage.read(geminiStorageKey))
            .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');

        const jsonString = '''
      {
        "metadatos": {
          "titulo": "10,000 Reasons (Bless the Lord)",
          "artista": "Matt Redman",
          "tonalidad_indicada": "G",
          "tempo_bpm": 73,
          "compas": "4/4"
        },
        "secciones": [
          {
            "nombre": "Chorus",
            "caja_navegacion": "[Chorus]",
            "compases": [
              {
                "numero": 1,
                "acordes": [
                  {"cifrado": "C", "posicion_pulso": 1.0},
                  {"cifrado": "G", "posicion_pulso": 3.0}
                ],
                "notas": [
                  {"tono": "G4", "duracion": "quarter", "duracion_ticks": 480, "letra": "Bless"}
                ]
              }
            ]
          }
        ]
      }
      ''';

        when(
          () => mockClient.generateContent(
            modelName: any(named: 'modelName'),
            apiKey: any(named: 'apiKey'),
            imageBytes: any(named: 'imageBytes'),
            mimeType: any(named: 'mimeType'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
            prompt: any(named: 'prompt'),
          ),
        ).thenAnswer((_) async => jsonString);

        final result = await repository.extractFullLeadSheet(
          imageBytes: sampleImageBytes,
          mimeType: 'image/png',
        );

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected success: $failure'), (score) {
          expect(score, isA<Score>());
          expect(score.title, equals('10,000 Reasons (Bless the Lord)'));
          expect(score.artist, equals('Matt Redman'));
          expect(score.keySignature, equals('G'));
          expect(score.tempo, equals(73));
          expect(score.sections.length, equals(1));
          expect(score.sections.first.name, equals('Chorus'));
          expect(score.allMeasures.first.chords.length, equals(2));
          expect(
            score.allMeasures.first.events.first.pitch?.scientificNotation,
            equals('G4'),
          );
          expect(score.allMeasures.first.events.first.lyric, equals('Bless'));
        });
      },
    );

    test('returns UnexpectedFailure when response text is empty', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');
      when(
        () => mockClient.generateContent(
          modelName: any(named: 'modelName'),
          apiKey: any(named: 'apiKey'),
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
        ),
      ).thenAnswer((_) async => '');

      final result = await repository.extractFullLeadSheet(
        imageBytes: sampleImageBytes,
        mimeType: 'image/jpeg',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('returns UnexpectedFailure on malformed JSON response', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');
      when(
        () => mockClient.generateContent(
          modelName: any(named: 'modelName'),
          apiKey: any(named: 'apiKey'),
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
        ),
      ).thenAnswer((_) async => '{ not valid json');

      final result = await repository.extractFullLeadSheet(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('returns ServerFailure when model generation throws', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');
      when(
        () => mockClient.generateContent(
          modelName: any(named: 'modelName'),
          apiKey: any(named: 'apiKey'),
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
        ),
      ).thenThrow(Exception('Rate limit exceeded (429)'));

      final result = await repository.extractFullLeadSheet(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('Rate limit exceeded'));
      }, (_) => fail('Expected failure'));
    });
  });

  group('GeminiOmrRepository.extractPitchOnlySection', () {
    test('returns PermissionFailure when API key is missing', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => null);

      final result = await repository.extractPitchOnlySection(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PermissionFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('successfully extracts Schema B pitch only section and populates measures', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');

      const jsonString = '''
      {
        "seccion": "Bridge",
        "clave_asumida": "G4",
        "advertencia": "Dense ledger lines detected above staff",
        "compases": [
          {
            "numero": 1,
            "acordes": ["Em", "C"],
            "secuencia_notas": ["E4", "G4", "B4", "E5"]
          }
        ]
      }
      ''';

      when(
        () => mockClient.generateContent(
          modelName: any(named: 'modelName'),
          apiKey: any(named: 'apiKey'),
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
        ),
      ).thenAnswer((_) async => jsonString);

      final result = await repository.extractPitchOnlySection(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
        timeSignature: TimeSignature.fourFour,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected success: $failure'), (
        pitchResult,
      ) {
        expect(pitchResult, isA<PitchOnlyResult>());
        expect(pitchResult.sectionName, equals('Bridge'));
        expect(pitchResult.assumedClef, equals('G4'));
        expect(
          pitchResult.warning,
          equals('Dense ledger lines detected above staff'),
        );
        expect(pitchResult.measures.length, equals(1));
        final m1 = pitchResult.measures.first;
        expect(m1.number, equals(1));
        expect(m1.chords.length, equals(2));
        expect(m1.chords.first.text, equals('Em'));
        expect(m1.events.length, equals(4));
        expect(m1.events.first.pitch?.scientificNotation, equals('E4'));
        expect(m1.events.last.pitch?.scientificNotation, equals('E5'));
        expect(m1.hasUnassignedEvents, isTrue);
      });
    });

    test('returns UnexpectedFailure when response is empty', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');
      when(
        () => mockClient.generateContent(
          modelName: any(named: 'modelName'),
          apiKey: any(named: 'apiKey'),
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
        ),
      ).thenAnswer((_) async => '   ');

      final result = await repository.extractPitchOnlySection(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('returns ServerFailure when model generation throws', () async {
      when(() => mockStorage.read(geminiStorageKey))
          .thenAnswer((_) async => 'AIzaSyValidGeminiKey1234567890');
      when(
        () => mockClient.generateContent(
          modelName: any(named: 'modelName'),
          apiKey: any(named: 'apiKey'),
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
        ),
      ).thenThrow(Exception('API error 503'));

      final result = await repository.extractPitchOnlySection(
        imageBytes: sampleImageBytes,
        mimeType: 'image/png',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
    });
  });
}
