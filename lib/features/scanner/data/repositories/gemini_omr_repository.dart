/// Battuta — Gemini OMR repository implementation.
///
/// Implements [OmrRepository] utilizing `google_generative_ai` with
/// strict structured JSON output and schema validation.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/features/scanner/domain/entities/full_sheet_mapper.dart';
import 'package:battuta/features/scanner/domain/entities/full_sheet_schema.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Client abstraction wrapping Gemini API calls for hermetic testing and loose coupling.
abstract class GeminiOmrClient {
  /// Calls Gemini to generate structured content from an image input.
  Future<String?> generateContent({
    required String modelName,
    required String apiKey,
    required Uint8List imageBytes,
    required String mimeType,
    required Schema responseSchema,
    required String systemInstruction,
    required String prompt,
  });
}

/// Default implementation of [GeminiOmrClient] invoking [GenerativeModel].
class DefaultGeminiOmrClient implements GeminiOmrClient {
  const DefaultGeminiOmrClient();

  @override
  Future<String?> generateContent({
    required String modelName,
    required String apiKey,
    required Uint8List imageBytes,
    required String mimeType,
    required Schema responseSchema,
    required String systemInstruction,
    required String prompt,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
      systemInstruction: Content.system(systemInstruction),
    );

    final response = await model.generateContent([
      Content.data(mimeType, imageBytes),
      Content.text(prompt),
    ]);

    return response.text;
  }
}

/// Concrete [OmrRepository] powered by Google Gemini multimodal models.
class GeminiOmrRepository implements OmrRepository {
  /// Creates a [GeminiOmrRepository].
  GeminiOmrRepository({
    required this.apiKeyService,
    GeminiOmrClient? client,
  }) : _client = client ?? const DefaultGeminiOmrClient();

  /// Service managing active API keys.
  final ApiKeyService apiKeyService;

  final GeminiOmrClient _client;

  /// Default multimodal Gemini model for lead sheet recognition.
  static const String defaultModel = 'gemini-2.5-flash';

  @override
  Future<Either<Failure, Score>> extractFullLeadSheet({
    required Uint8List imageBytes,
    required String mimeType,
    String? modelName,
  }) async {
    try {
      final apiKey = await apiKeyService.getActiveGeminiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        return const Left(PermissionFailure(
          message:
              'Gemini API key is not configured. Please configure your key in Settings.',
        ));
      }

      final responseText = await _client.generateContent(
        modelName: modelName ?? defaultModel,
        apiKey: apiKey.trim(),
        imageBytes: imageBytes,
        mimeType: mimeType,
        responseSchema: FullSheetSchema.schema,
        systemInstruction: FullSheetSchema.systemInstruction,
        prompt:
            'Transcribe this sheet music image into structured JSON adhering to the schema.',
      );

      if (responseText == null || responseText.trim().isEmpty) {
        return const Left(UnexpectedFailure(
          message: 'Gemini returned an empty response.',
        ));
      }

      final dynamic decoded = jsonDecode(responseText);
      if (decoded is! Map<String, dynamic>) {
        return const Left(UnexpectedFailure(
          message: 'Expected a JSON object from Gemini response.',
        ));
      }

      final score = FullSheetMapper.mapToScore(decoded);
      return Right(score);
    } on FormatException catch (e, st) {
      return Left(UnexpectedFailure(
        message: 'Failed to parse Gemini JSON output: ${e.message}',
        stackTrace: st,
      ));
    } catch (e, st) {
      return Left(ServerFailure(
        message: 'Gemini OMR extraction failed: $e',
        stackTrace: st,
      ));
    }
  }
}
