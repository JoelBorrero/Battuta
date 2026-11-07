/// Battuta — Gemini OMR repository implementation.
///
/// Implements [OmrRepository] utilizing `google_generative_ai` with
/// strict structured JSON output and schema validation.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/features/scanner/data/services/omr_log_service.dart';
import 'package:battuta/features/scanner/domain/entities/full_sheet_mapper.dart';
import 'package:battuta/features/scanner/domain/entities/full_sheet_schema.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_mapper.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_schema.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
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
    ]).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException(
        'Gemini analysis timed out after 45 seconds. Please check your network connection or try again.',
      ),
    );

    return response.text;
  }
}

/// Concrete [OmrRepository] powered by Google Gemini multimodal models.
class GeminiOmrRepository implements OmrRepository {
  /// Creates a [GeminiOmrRepository].
  GeminiOmrRepository({
    required this.apiKeyService,
    GeminiOmrClient? client,
    OmrLogService? logService,
    this.onUsageRecorded,
  })  : _client = client ?? const DefaultGeminiOmrClient(),
        _logService = logService ?? OmrLogService();

  /// Service managing active API keys.
  final ApiKeyService apiKeyService;

  final GeminiOmrClient _client;

  final OmrLogService _logService;

  /// Optional telemetry hook called with total tokens consumed upon successful extraction.
  final void Function(int tokens)? onUsageRecorded;

  /// Default fast multimodal Gemini model for lead sheet recognition.
  static const String defaultModel = 'gemini-3.5-flash-lite';

  @override
  Future<Either<Failure, Score>> extractFullLeadSheet({
    required Uint8List imageBytes,
    required String mimeType,
    String? modelName,
  }) async {
    final stopwatch = Stopwatch()..start();
    await _logService.logSessionStart(
      mode: 'Full Lead Sheet (Schema A)',
      imageSizeBytes: imageBytes.length,
      mimeType: mimeType,
    );

    try {
      final keySource = await apiKeyService.getGeminiKeySource();
      final apiKey = await apiKeyService.getActiveGeminiKey();
      await _logService.logApiKeyResolved(key: apiKey, source: keySource.name);

      if (apiKey == null || apiKey.trim().isEmpty) {
        await _logService.logResult(
          success: false,
          summary: 'Aborted: Gemini API key is not configured.',
        );
        return const Left(
          PermissionFailure(
            message: 'Gemini API key is not configured. Please configure your key in Settings.',
          ),
        );
      }

      final targetModel = modelName ?? defaultModel;
      await _logService.logRequestDispatched(
        model: targetModel,
        prompt: 'Transcribe this sheet music image into structured JSON adhering to the schema.',
        systemInstructionLength: FullSheetSchema.systemInstruction.length,
      );

      final responseText = await _client.generateContent(
        modelName: targetModel,
        apiKey: apiKey.trim(),
        imageBytes: imageBytes,
        mimeType: mimeType,
        responseSchema: FullSheetSchema.schema,
        systemInstruction: FullSheetSchema.systemInstruction,
        prompt: 'Transcribe this sheet music image into structured JSON adhering to the schema.',
      );

      stopwatch.stop();
      await _logService.logResponseReceived(
        durationMs: stopwatch.elapsedMilliseconds,
        rawResponseText: responseText,
      );

      if (responseText == null || responseText.trim().isEmpty) {
        await _logService.logResult(
          success: false,
          summary: 'Gemini returned an empty or null response text.',
        );
        return const Left(
          UnexpectedFailure(message: 'Gemini returned an empty response.'),
        );
      }

      final dynamic decoded = jsonDecode(responseText);
      if (decoded is! Map<String, dynamic>) {
        await _logService.logResult(
          success: false,
          summary: 'Expected JSON object but received ${decoded.runtimeType}',
        );
        return const Left(
          UnexpectedFailure(
            message: 'Expected a JSON object from Gemini response.',
          ),
        );
      }

      final score = FullSheetMapper.mapToScore(decoded);
      await _logService.logResult(
        success: true,
        summary: 'Lead sheet extracted successfully',
        metrics: {
          'Title': score.title,
          'Sections': score.sections.length,
          'Measures': score.sections.fold<int>(0, (sum, s) => sum + s.measures.length),
        },
      );
      onUsageRecorded?.call(1500);
      return Right(score);
    } on FormatException catch (e, st) {
      stopwatch.stop();
      await _logService.logResult(
        success: false,
        summary: 'Failed to parse Gemini JSON output',
        error: e,
        stackTrace: st,
      );
      return Left(
        UnexpectedFailure(
          message: 'Failed to parse Gemini JSON output: ${e.message}',
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      stopwatch.stop();
      await _logService.logResult(
        success: false,
        summary: 'Gemini OMR extraction encountered an unhandled error',
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message: 'Gemini OMR extraction failed: $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PitchOnlyResult>> extractPitchOnlySection({
    required Uint8List imageBytes,
    required String mimeType,
    TimeSignature timeSignature = TimeSignature.fourFour,
    String? modelName,
  }) async {
    final stopwatch = Stopwatch()..start();
    await _logService.logSessionStart(
      mode: 'Staff Snippet (Schema B - Pitch Only)',
      imageSizeBytes: imageBytes.length,
      mimeType: mimeType,
    );

    try {
      final keySource = await apiKeyService.getGeminiKeySource();
      final apiKey = await apiKeyService.getActiveGeminiKey();
      await _logService.logApiKeyResolved(key: apiKey, source: keySource.name);

      if (apiKey == null || apiKey.trim().isEmpty) {
        await _logService.logResult(
          success: false,
          summary: 'Aborted: Gemini API key is not configured.',
        );
        return const Left(
          PermissionFailure(
            message: 'Gemini API key is not configured. Please configure your key in Settings.',
          ),
        );
      }

      final targetModel = modelName ?? defaultModel;
      await _logService.logRequestDispatched(
        model: targetModel,
        prompt: 'Extract melodic noteheads and chords ignoring rhythm. Assume Treble Clef (G4).',
        systemInstructionLength: PitchOnlySchema.systemInstruction.length,
      );

      final responseText = await _client.generateContent(
        modelName: targetModel,
        apiKey: apiKey.trim(),
        imageBytes: imageBytes,
        mimeType: mimeType,
        responseSchema: PitchOnlySchema.schema,
        systemInstruction: PitchOnlySchema.systemInstruction,
        prompt: 'Extract melodic noteheads and chords ignoring rhythm. Assume Treble Clef (G4).',
      );

      stopwatch.stop();
      await _logService.logResponseReceived(
        durationMs: stopwatch.elapsedMilliseconds,
        rawResponseText: responseText,
      );

      if (responseText == null || responseText.trim().isEmpty) {
        await _logService.logResult(
          success: false,
          summary: 'Gemini returned an empty or null response text.',
        );
        return const Left(
          UnexpectedFailure(message: 'Gemini returned an empty response.'),
        );
      }

      final dynamic decoded = jsonDecode(responseText);
      if (decoded is! Map<String, dynamic>) {
        await _logService.logResult(
          success: false,
          summary: 'Expected JSON object but received ${decoded.runtimeType}',
        );
        return const Left(
          UnexpectedFailure(
            message: 'Expected a JSON object from Gemini response.',
          ),
        );
      }

      final result = PitchOnlyMapper.mapToResult(
        decoded,
        timeSignature: timeSignature,
      );
      await _logService.logResult(
        success: true,
        summary: 'Pitch-only snippet extracted successfully',
        metrics: {
          'Section Name': result.sectionName,
          'Measures': result.totalMeasures,
        },
      );
      onUsageRecorded?.call(600);
      return Right(result);
    } on FormatException catch (e, st) {
      stopwatch.stop();
      await _logService.logResult(
        success: false,
        summary: 'Failed to parse Gemini JSON output',
        error: e,
        stackTrace: st,
      );
      return Left(
        UnexpectedFailure(
          message: 'Failed to parse Gemini JSON output: ${e.message}',
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      stopwatch.stop();
      await _logService.logResult(
        success: false,
        summary: 'Gemini pitch-only extraction encountered an unhandled error',
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message: 'Gemini OMR pitch-only extraction failed: $e',
          stackTrace: st,
        ),
      );
    }
  }
}
