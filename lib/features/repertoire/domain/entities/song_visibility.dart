/// Battuta — Song version visibility.
///
/// Mirrors `song_versions.visibility` on the backend.
library;

/// Who can see a song version.
enum SongVisibility {
  /// Only the owner.
  private,

  /// The members of the organizations the version is shared with.
  organizations,

  /// Anyone.
  public;

  /// Parses the backend value; unknown text is treated as [private] (the
  /// safest reading).
  static SongVisibility parse(String? value) => switch (value) {
    'organizations' => organizations,
    'public' => public,
    _ => private,
  };
}
