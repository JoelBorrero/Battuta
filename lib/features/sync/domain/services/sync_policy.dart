/// Battuta — Pure rules of the song/setlist cloud sync.
///
/// Everything here is free of I/O so it can be tested exhaustively: which
/// local rows an account claims, how conflicts between two devices resolve
/// (last write wins), which cached rows a reconcile removes and how the
/// backend's setlist entries map to local ones.
library;

/// A row's identity as the sync sees it.
class SyncRow {
  const SyncRow({
    required this.id,
    required this.isDirty,
    required this.remoteUpdatedAt,
    this.deletedAt,
  });

  final String id;

  /// Local changes not yet pushed.
  final bool isDirty;

  /// `updated_at` the row was last synced with; null if it never reached the
  /// backend.
  final String? remoteUpdatedAt;

  /// Local tombstone time, if the row was deleted locally.
  final DateTime? deletedAt;

  bool get isSynced => remoteUpdatedAt != null;
}

/// Outcome of comparing a dirty local row with the backend copy at push time.
enum PushDecision {
  /// Send the local version.
  push,

  /// The backend copy changed on another device after this edit: keep it and
  /// drop the local change.
  remoteWins,
}

/// Outcome for a local deletion.
enum DeleteDecision {
  /// Delete the backend row.
  deleteRemote,

  /// The backend row was edited after the deletion: keep it.
  keepRemote,
}

abstract final class SyncPolicy {
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Id prefix of the bundled sample data. Sample rows live on the device only.
  static const localOnlyPrefix = 'seed-';

  /// Whether [id] is a UUID (what the backend needs for versions, scores and
  /// setlist entries).
  static bool isUuid(String id) => _uuidPattern.hasMatch(id);

  /// Whether the row never leaves the device (bundled sample data).
  static bool isLocalOnly(String id) => id.startsWith(localOnlyPrefix);

  /// Whether a local-mode row may be claimed by the account that signs in.
  /// Sample data is never claimed; a row another account already claimed has
  /// an `accountId` and never reaches this check.
  static bool isClaimable(String id) => !isLocalOnly(id);

  /// Normalizes a backend timestamp so equal instants compare equal as text.
  static String normalizeTimestamp(Object? value) {
    final parsed = DateTime.tryParse('$value');
    return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        .toUtc()
        .toIso8601String();
  }

  /// The next local edit time for a row, in milliseconds since the epoch: the
  /// current time, but always greater than [previous], so two edits of one row
  /// never share a value (a push can then tell that the row changed again).
  static int nextEditMs(int? previous, {DateTime? now}) {
    final ms = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return previous != null && ms <= previous ? previous + 1 : ms;
  }

  /// Milliseconds since the epoch of a backend timestamp.
  static int timestampMs(Object? value) =>
      (DateTime.tryParse('$value') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
          .millisecondsSinceEpoch;

  /// A local edit time as the ISO-8601 text the backend stores in `edited_at`.
  static String editedAtText(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

  /// Last-write-wins for a dirty row about to be pushed.
  ///
  /// `updated_at` only says that the backend row changed ([remoteUpdatedAt]
  /// differs from [knownRemoteUpdatedAt]; a song merge changes it without
  /// anyone editing). The edit times decide: the backend copy wins only if its
  /// `edited_at` ([remoteEditedMs]) is later than the local edit
  /// ([localEditedMs]), whenever each of them was synced.
  static PushDecision decidePush({
    required int localEditedMs,
    required String? knownRemoteUpdatedAt,
    required String remoteUpdatedAt,
    required int remoteEditedMs,
  }) {
    if (knownRemoteUpdatedAt == remoteUpdatedAt) return PushDecision.push;
    return remoteEditedMs > localEditedMs
        ? PushDecision.remoteWins
        : PushDecision.push;
  }

  /// A local delete wins only if no other device edited the row after it.
  static DeleteDecision decideDelete({
    required int deletedAtMs,
    required String? knownRemoteUpdatedAt,
    required String remoteUpdatedAt,
    required int remoteEditedMs,
  }) {
    if (knownRemoteUpdatedAt == remoteUpdatedAt) {
      return DeleteDecision.deleteRemote;
    }
    return remoteEditedMs > deletedAtMs
        ? DeleteDecision.keepRemote
        : DeleteDecision.deleteRemote;
  }

  /// Whether a pulled backend row replaces the local copy: it is new, or the
  /// local copy is clean and out of date. Dirty rows are never overwritten by
  /// a pull (the push already decided between them).
  static bool shouldApplyRemote({
    required SyncRow? local,
    required String remoteUpdatedAt,
  }) {
    if (local == null) return true;
    if (local.isDirty || local.deletedAt != null) return false;
    return local.remoteUpdatedAt != remoteUpdatedAt;
  }

  /// Cached rows to remove after a pull: synced, clean rows the backend no
  /// longer shows to this account (hard deletes, unshares, privacy changes,
  /// repertoire removals). Dirty rows and rows that never reached the backend
  /// stay.
  static List<String> staleIds({
    required Iterable<SyncRow> local,
    required Set<String> visibleIds,
  }) => [
    for (final row in local)
      if (row.isSynced &&
          !row.isDirty &&
          row.deletedAt == null &&
          !visibleIds.contains(row.id))
        row.id,
  ];

  /// Splits [items] into lists of at most [size] elements.
  static List<List<T>> chunk<T>(List<T> items, int size) => [
    for (var i = 0; i < items.length; i += size)
      items.sublist(i, i + size > items.length ? items.length : i + size),
  ];
}
