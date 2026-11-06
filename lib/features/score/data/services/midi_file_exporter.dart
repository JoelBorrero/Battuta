/// Battuta — Basic MIDI Reference File Exporter.
///
/// Translates the validated Score / Measure tree into standard MIDI binary events
/// (Note On / Note Off at 480 PPQ) and exports standard .mid files compatible
/// with any DAW, QuickTime, or system player on macOS and iPadOS.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/services/midi_exporter_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Implementation of [MidiExporterService] producing standard Type 0 and Type 1
/// SMF (.mid) files at 480 PPQ.
class MidiFileExporter implements MidiExporterService {
  /// Creates a [MidiFileExporter].
  const MidiFileExporter();

  @override
  Uint8List exportScoreToMidi(
    Score score, {
    MidiExportOptions options = const MidiExportOptions(),
  }) {
    if (options.format == MidiFileFormat.format1) {
      return _buildFormat1(score, options);
    }
    return _buildFormat0(score, options);
  }

  @override
  Future<bool> shareMidiFile(
    Score score, {
    MidiExportOptions options = const MidiExportOptions(),
    String? fileName,
  }) async {
    final bytes = exportScoreToMidi(score, options: options);
    final sanitizedTitle =
        score.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final actualFileName = fileName ?? '$sanitizedTitle.mid';

    return Printing.sharePdf(
      bytes: bytes,
      filename: actualFileName,
    );
  }

  /// Writes the exported MIDI bytes directly to disk at [filePath],
  /// or in the system Application Documents directory if omitted.
  Future<File> saveMidiToDisk(
    Score score, {
    String? filePath,
    MidiExportOptions options = const MidiExportOptions(),
  }) async {
    final bytes = exportScoreToMidi(score, options: options);
    if (filePath != null) {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      return file.writeAsBytes(bytes);
    }

    final dir = await getApplicationDocumentsDirectory();
    final sanitizedTitle =
        score.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final target = File('${dir.path}/$sanitizedTitle.mid');
    return target.writeAsBytes(bytes);
  }

  // ===========================================================================
  // Format 0 (Single Track: Meta + Melody Events)
  // ===========================================================================

  Uint8List _buildFormat0(Score score, MidiExportOptions options) {
    final events = <_MidiEvent>[];

    // 1. Meta Events at tick 0
    if (options.includeTrackName) {
      events.add(_createTrackNameEvent(0, score.title));
    }
    if (options.includeTimeSignature) {
      events.add(_createTimeSignatureEvent(
        0,
        score.timeSignature.numerator,
        score.timeSignature.denominator,
      ));
    }
    if (options.includeTempo) {
      events.add(_createTempoEvent(0, score.tempo));
    }
    final keyMeta = _createKeySignatureEvent(0, score.keySignature);
    if (keyMeta != null) {
      events.add(keyMeta);
    }

    // Program Change (General MIDI Sound)
    events.add(_createProgramChangeEvent(
      0,
      options.channel,
      options.programNumber,
    ));

    // 2. Note Events
    _collectScoreNoteEvents(score, options, events);

    // 3. Encode Track
    final trackBytes = _encodeTrackChunk(events);

    // 4. Header Chunk
    final headerBytes = _encodeHeaderChunk(
      format: 0,
      numTracks: 1,
      ppq: options.ppq,
    );

    final result = BytesBuilder(copy: false)
      ..add(headerBytes)
      ..add(trackBytes);

    return result.toBytes();
  }

  // ===========================================================================
  // Format 1 (Multi-Track: Track 0 Tempo/Meter, Track 1 Notes)
  // ===========================================================================

  Uint8List _buildFormat1(Score score, MidiExportOptions options) {
    // Track 0: Tempo and Meter Map
    final tempoEvents = <_MidiEvent>[];
    if (options.includeTrackName) {
      tempoEvents.add(_createTrackNameEvent(0, '${score.title} (Tempo Map)'));
    }
    if (options.includeTimeSignature) {
      tempoEvents.add(_createTimeSignatureEvent(
        0,
        score.timeSignature.numerator,
        score.timeSignature.denominator,
      ));
    }
    if (options.includeTempo) {
      tempoEvents.add(_createTempoEvent(0, score.tempo));
    }
    final keyMeta = _createKeySignatureEvent(0, score.keySignature);
    if (keyMeta != null) {
      tempoEvents.add(keyMeta);
    }
    final tempoTrackBytes = _encodeTrackChunk(tempoEvents);

    // Track 1: Melody Notes & Program Change
    final noteTrackEvents = <_MidiEvent>[];
    if (options.includeTrackName) {
      noteTrackEvents.add(_createTrackNameEvent(0, 'Lead Melody'));
    }
    noteTrackEvents.add(_createProgramChangeEvent(
      0,
      options.channel,
      options.programNumber,
    ));
    _collectScoreNoteEvents(score, options, noteTrackEvents);
    final noteTrackBytes = _encodeTrackChunk(noteTrackEvents);

    // Header Chunk (Format 1, 2 tracks)
    final headerBytes = _encodeHeaderChunk(
      format: 1,
      numTracks: 2,
      ppq: options.ppq,
    );

    final result = BytesBuilder(copy: false)
      ..add(headerBytes)
      ..add(tempoTrackBytes)
      ..add(noteTrackBytes);

    return result.toBytes();
  }

  // ===========================================================================
  // Note Event Traversal & Tie Resolution
  // ===========================================================================

  void _collectScoreNoteEvents(
    Score score,
    MidiExportOptions options,
    List<_MidiEvent> outEvents,
  ) {
    // 1. Flatten all note events into performance sequence with absolute start ticks
    final performanceEvents = <({NoteEvent event, int absoluteStartTick})>[];
    var measureStartTick = 0;

    for (final section in score.sections) {
      final repeatTimes = options.respectSectionRepeats
          ? math.max(1, section.repeatCount)
          : 1;

      for (var r = 0; r < repeatTimes; r++) {
        for (final measure in section.measures) {
          for (final event in measure.events) {
            performanceEvents.add((
              event: event,
              absoluteStartTick: measureStartTick + event.tickOffset,
            ));
          }
          measureStartTick += measure.timeSignature.maxTicks;
        }
      }
    }

    // 2. Process notes and merge ties across intra-measure and inter-measure boundaries
    var i = 0;
    while (i < performanceEvents.length) {
      final current = performanceEvents[i];
      final event = current.event;

      if (event.pitch != null) {
        final pitch = event.pitch!;
        final midiNote = pitch.midiNumber.clamp(0, 127);
        final startTick = current.absoluteStartTick;
        var totalTicks = event.rhythmicValue.ticks;
        final velocity =
            event.velocity > 0 ? event.velocity : options.defaultVelocity;

        // Merge consecutive tied notes of the same pitch
        var cursor = i;
        while (performanceEvents[cursor].event.isTied &&
            cursor + 1 < performanceEvents.length) {
          final next = performanceEvents[cursor + 1];
          if (next.event.pitch != null &&
              next.event.pitch!.midiNumber == pitch.midiNumber &&
              next.absoluteStartTick == startTick + totalTicks) {
            totalTicks += next.event.rhythmicValue.ticks;
            cursor++;
          } else {
            break;
          }
        }
        i = cursor;

        final endTick = startTick + totalTicks;

        // Note On event
        outEvents.add(_MidiEvent(
          absoluteTick: startTick,
          priority: 3, // Note On after Note Off
          data: [
            0x90 | options.channel,
            midiNote,
            velocity.clamp(1, 127),
          ],
        ));

        // Note Off event
        outEvents.add(_MidiEvent(
          absoluteTick: endTick,
          priority: 2, // Note Off before Note On at same tick
          data: [
            0x80 | options.channel,
            midiNote,
            0x00,
          ],
        ));
      }

      i++;
    }
  }

  // ===========================================================================
  // Header and Track Chunk Encoding
  // ===========================================================================

  List<int> _encodeHeaderChunk({
    required int format,
    required int numTracks,
    required int ppq,
  }) {
    final builder = BytesBuilder(copy: false);
    // 'MThd'
    builder.add([0x4D, 0x54, 0x68, 0x64]);
    // Chunk length: 6 bytes (32-bit big-endian)
    builder.add([0x00, 0x00, 0x00, 0x06]);
    // Format: 16-bit big-endian
    builder.add([(format >> 8) & 0xFF, format & 0xFF]);
    // Num tracks: 16-bit big-endian
    builder.add([(numTracks >> 8) & 0xFF, numTracks & 0xFF]);
    // Time division (PPQ): 16-bit big-endian
    builder.add([(ppq >> 8) & 0xFF, ppq & 0xFF]);
    return builder.toBytes();
  }

  List<int> _encodeTrackChunk(List<_MidiEvent> events) {
    // Sort events chronologically, with priority resolving same-tick ties
    events.sort();

    final trackData = BytesBuilder(copy: false);
    var lastTick = 0;

    for (final event in events) {
      final delta = math.max(0, event.absoluteTick - lastTick);
      lastTick = event.absoluteTick;

      // Delta time in Variable-Length Quantity (VLQ)
      trackData.add(encodeVlq(delta));
      trackData.add(event.data);
    }

    // End of Track meta event: delta 0, 0xFF, 0x2F, 0x00
    trackData.add([0x00, 0xFF, 0x2F, 0x00]);

    final rawTrackBytes = trackData.toBytes();
    final trackLength = rawTrackBytes.length;

    final chunk = BytesBuilder(copy: false);
    // 'MTrk'
    chunk.add([0x4D, 0x54, 0x72, 0x6B]);
    // Track length (32-bit big-endian)
    chunk.add([
      (trackLength >> 24) & 0xFF,
      (trackLength >> 16) & 0xFF,
      (trackLength >> 8) & 0xFF,
      trackLength & 0xFF,
    ]);
    chunk.add(rawTrackBytes);

    return chunk.toBytes();
  }

  // ===========================================================================
  // Meta Events & Helpers
  // ===========================================================================

  _MidiEvent _createTrackNameEvent(int tick, String name) {
    final bytes = utf8.encode(name);
    final data = <int>[
      0xFF,
      0x03,
      ...encodeVlq(bytes.length),
      ...bytes,
    ];
    return _MidiEvent(absoluteTick: tick, priority: 0, data: data);
  }

  _MidiEvent _createTimeSignatureEvent(
    int tick,
    int numerator,
    int denominator,
  ) {
    // Denominator power of 2: e.g. 4 -> 2, 8 -> 3, 2 -> 1
    final denPower = (math.log(denominator) / math.ln2).round();
    final data = <int>[
      0xFF,
      0x58,
      0x04,
      numerator.clamp(1, 32),
      denPower.clamp(0, 5),
      0x18, // 24 MIDI clocks per metronome click
      0x08, // 8 32nd notes per MIDI quarter note
    ];
    return _MidiEvent(absoluteTick: tick, priority: 0, data: data);
  }

  _MidiEvent _createTempoEvent(int tick, int bpm) {
    final clampedBpm = bpm.clamp(1, 400);
    // Microseconds per quarter note = 60,000,000 / BPM
    final mpqn = (60000000 ~/ clampedBpm).clamp(1, 0xFFFFFF);
    final data = <int>[
      0xFF,
      0x51,
      0x03,
      (mpqn >> 16) & 0xFF,
      (mpqn >> 8) & 0xFF,
      mpqn & 0xFF,
    ];
    return _MidiEvent(absoluteTick: tick, priority: 0, data: data);
  }

  _MidiEvent? _createKeySignatureEvent(int tick, String keyName) {
    // Map common key names to [sharps/flats (-7 to 7), isMinor (0 or 1)]
    final (sf, mi) = switch (keyName.trim()) {
      'C' => (0, 0),
      'G' => (1, 0),
      'D' => (2, 0),
      'A' => (3, 0),
      'E' => (4, 0),
      'B' => (5, 0),
      'F#' || 'Gb' => (6, 0),
      'C#' => (7, 0),
      'F' => (-1, 0),
      'Bb' => (-2, 0),
      'Eb' => (-3, 0),
      'Ab' => (-4, 0),
      'Db' => (-5, 0),
      'Am' => (0, 1),
      'Em' => (1, 1),
      'Bm' => (2, 1),
      'F#m' => (3, 1),
      'C#m' => (4, 1),
      'G#m' => (5, 1),
      'Dm' => (-1, 1),
      'Gm' => (-2, 1),
      'Cm' => (-3, 1),
      'Fm' => (-4, 1),
      _ => (0, 0),
    };

    final sfByte = sf < 0 ? (256 + sf) : sf;
    final data = <int>[
      0xFF,
      0x59,
      0x02,
      sfByte & 0xFF,
      mi,
    ];
    return _MidiEvent(absoluteTick: tick, priority: 0, data: data);
  }

  _MidiEvent _createProgramChangeEvent(int tick, int channel, int program) {
    return _MidiEvent(
      absoluteTick: tick,
      priority: 1,
      data: [0xC0 | (channel & 0x0F), program.clamp(0, 127)],
    );
  }

  // ===========================================================================
  // VLQ (Variable-Length Quantity) Serialization
  // ===========================================================================

  /// Encodes a non-negative integer into a standard MIDI Variable-Length Quantity.
  static List<int> encodeVlq(int value) {
    assert(value >= 0, 'VLQ value cannot be negative');
    if (value <= 0) return [0x00];

    var v = value;
    final bytes = <int>[];
    bytes.add(v & 0x7F);
    v >>= 7;

    while (v > 0) {
      bytes.add((v & 0x7F) | 0x80);
      v >>= 7;
    }

    return bytes.reversed.toList();
  }

  /// Decodes a VLQ from [bytes] at [offset], returning the decoded value and byte length.
  static (int value, int bytesRead) decodeVlq(Uint8List bytes, int offset) {
    var value = 0;
    var count = 0;
    while (offset + count < bytes.length) {
      final b = bytes[offset + count];
      count++;
      value = (value << 7) | (b & 0x7F);
      if ((b & 0x80) == 0) break;
    }
    return (value, count);
  }
}

/// Internal timed event holder for sorting and delta-tick calculation.
class _MidiEvent implements Comparable<_MidiEvent> {
  const _MidiEvent({
    required this.absoluteTick,
    required this.priority,
    required this.data,
  });

  /// Time in MIDI ticks from beginning of performance.
  final int absoluteTick;

  /// Ordering priority when multiple events share the exact same tick:
  /// - 0: Meta events (Time Signature, Tempo, Key, Name)
  /// - 1: Program Change
  /// - 2: Note Off (0x80)
  /// - 3: Note On (0x90)
  final int priority;

  /// Raw MIDI event data bytes.
  final List<int> data;

  @override
  int compareTo(_MidiEvent other) {
    final tickDiff = absoluteTick.compareTo(other.absoluteTick);
    if (tickDiff != 0) return tickDiff;
    return priority.compareTo(other.priority);
  }
}
