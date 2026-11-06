/// Battuta — Gemini OMR Riverpod providers.
///
/// Exposes [OmrRepository] and state management for sheet music scanning.
library;

import 'package:battuta/features/scanner/data/repositories/gemini_omr_repository.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the active [OmrRepository] instance.
final omrRepositoryProvider = Provider<OmrRepository>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  return GeminiOmrRepository(apiKeyService: apiKeyService);
});
