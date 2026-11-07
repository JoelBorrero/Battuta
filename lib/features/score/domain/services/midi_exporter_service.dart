/// Battuta — MIDI Reference Exporter Service Interface.
///
/// Defines the contract and options for exporting a validated Score / Measure tree
/// into standard MIDI binary events (Note On / Note Off at 480 PPQ) and producing
/// standard .mid files compatible with DAWs, QuickTime, and OS players.
library;

import 'dart:typed_data';

import 'package:battuta/features/score/domain/entities/score.dart';

/// Supported Standard MIDI File (SMF) format types.
enum MidiFileFormat {
  /// Single multichannel track containing all meta and note events.
  /// Universally compatible with all players and DAWs without track dialogs.
  format0,

  /// Multi-track sequence: Track 0 holds tempo and meter; Track 1 holds melody notes.
  format1,
}

/// Configuration options for MIDI file generation.
class MidiExportOptions {
  /// Creates immutable [MidiExportOptions].
  const MidiExportOptions({
    this.ppq = 480,
    this.channel = 0,
    this.programNumber = 0,
    this.defaultVelocity = 80,
    this.respectSectionRepeats = true,
    this.format = MidiFileFormat.format0,
    this.includeTempo = true,
    this.includeTimeSignature = true,
    this.includeTrackName = true,
  }) : assert(
         ppq > 0,
         'PPQ (ticks per quarter note) must be greater than zero',
       ),
       assert(
         channel >= 0 && channel <= 15,
         'MIDI channel must be between 0 and 15',
       ),
       assert(
         programNumber >= 0 && programNumber <= 127,
         'MIDI program number must be between 0 and 127',
       ),
       assert(
         defaultVelocity >= 1 && defaultVelocity <= 127,
         'Default velocity must be between 1 and 127',
       );

  /// Pulses (Ticks) Per Quarter Note resolution. Default: 480 PPQ.
  final int ppq;

  /// Zero-based MIDI channel for note events (0 = Channel 1).
  final int channel;

  /// General MIDI program / instrument patch number (0 = Acoustic Grand Piano).
  final int programNumber;

  /// Default MIDI velocity for notes without an explicit velocity.
  final int defaultVelocity;

  /// Whether to duplicate section measures based on [Section.repeatCount].
  final bool respectSectionRepeats;

  /// Standard MIDI File format type.
  final MidiFileFormat format;

  /// Whether to embed the Set Tempo (0x51) meta event.
  final bool includeTempo;

  /// Whether to embed the Time Signature (0x58) meta event.
  final bool includeTimeSignature;

  /// Whether to embed the Track Name (0x03) meta event.
  final bool includeTrackName;
}

/// Abstract contract for exporting musical scores to Standard MIDI Files (.mid).
abstract class MidiExporterService {
  /// Encodes [score] into a Standard MIDI File byte array at 480 PPQ.
  Uint8List exportScoreToMidi(
    Score score, {
    MidiExportOptions options = const MidiExportOptions(),
  });

  /// Opens the system Share Sheet to share or save the exported .mid file.
  Future<bool> shareMidiFile(
    Score score, {
    MidiExportOptions options = const MidiExportOptions(),
    String? fileName,
  });
}
