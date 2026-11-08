/// Battuta — Song Presentation & Stage View Modes.
///
/// Defines the display modes for viewing song lead sheets and charts
/// across stage, rehearsal, and vocal performance contexts.
library;

/// Display mode for rendering a song in Battuta.
enum SongViewMode {
  /// Both lyrics and chords positioned above corresponding words.
  both,

  /// Clean, pure lyrics without any chords or chord spacing (ideal for vocalists).
  lyricsOnly,

  /// Pure chord charts and progression blocks without any lyrics text (ideal for instrumentalists).
  chordsOnly,

  /// Interactive musical staff sheet music notation.
  staff,
}
