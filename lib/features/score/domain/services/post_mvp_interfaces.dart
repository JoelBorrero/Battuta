/// Battuta — Post-MVP Abstract Module Interfaces.
///
/// Exports clean Dart interfaces for future integration modules without
/// modifying v1.0 domain models:
/// - [LiveSyncService]: v1.1 Live Stage Sync & ProPresenter integration
/// - [PitchShiftedAudioPlayer]: v1.2 Reference Audio Player & Practice Loops
/// - [QuantizationInputEngine]: v1.3 Virtual Piano & Real-Time Tap Quantization
library;

export 'package:battuta/features/audio/domain/services/pitch_shifted_audio_player.dart';
export 'package:battuta/features/score/domain/services/quantization_input_engine.dart';
export 'package:battuta/features/sync/domain/services/live_sync_service.dart';
