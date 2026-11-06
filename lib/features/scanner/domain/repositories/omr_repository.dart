/// Battuta — Optical Music Recognition (OMR) repository contract.
///
/// Defines methods for extracting structured lead sheets and pitch sequences
/// from sheet music images using Gemini multimodal AI.
library;

import 'dart:typed_data';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract contract for OMR transcription services.
abstract class OmrRepository {
  /// Extracts a complete [Score] domain tree from a sheet music image (Schema A).
  Future<Either<Failure, Score>> extractFullLeadSheet({
    required Uint8List imageBytes,
    required String mimeType,
    String? modelName,
  });

  /// Extracts melodic pitch sequences and chord symbols without rhythmic durations (Schema B).
  ///
  /// Populates [Measure] objects using [Measure.fromGeminiPitchList] with unassigned rhythms,
  /// assuming Treble Clef (G4).
  Future<Either<Failure, PitchOnlyResult>> extractPitchOnlySection({
    required Uint8List imageBytes,
    required String mimeType,
    TimeSignature timeSignature = TimeSignature.fourFour,
    String? modelName,
  });
}
