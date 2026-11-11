/// Versions opened on purpose that the sync must not remove while their
/// viewer is open.
///
/// A public version opened from Discover is not in reach of the account (not
/// its own, not in a repertoire or setlist), so the next pull would drop it
/// from the device under the viewer. Pinning keeps it until the viewer closes;
/// after that the usual rules apply again.
library;

class PinnedVersions {
  final Map<String, int> _counts = {};

  /// The ids pinned right now.
  Set<String> get ids => _counts.keys.toSet();

  /// Pins [versionId]; every [pin] needs a matching [release].
  void pin(String versionId) =>
      _counts[versionId] = (_counts[versionId] ?? 0) + 1;

  /// Releases one pin of [versionId].
  void release(String versionId) {
    final count = _counts[versionId];
    if (count == null) return;
    if (count <= 1) {
      _counts.remove(versionId);
    } else {
      _counts[versionId] = count - 1;
    }
  }

  bool isPinned(String versionId) => _counts.containsKey(versionId);
}
