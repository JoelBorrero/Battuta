/// Route path constants for the Battuta app.
///
/// All named routes are centralized here so navigation never relies on
/// hard-coded strings scattered across the codebase.
///
/// Parameterized segments use a colon prefix (e.g. `:songId`) matching
/// GoRouter's path-parameter syntax.
library;

/// Static route-path definitions.
///
/// This class cannot be instantiated — use the static members directly:
///
/// ```dart
/// context.go(AppRoutes.repertoire);
/// context.go(AppRoutes.songDetail('abc-123'));
/// ```
final class AppRoutes {
  const AppRoutes._();

  // ── Root / shell ──────────────────────────────────────────────────────

  /// The initial route the app navigates to on cold start.
  static const String initial = repertoire;

  // ── Account entry (outside the shell) ─────────────────────────────────

  /// First-launch screen: sign in, create an account or continue offline.
  static const String welcome = '/welcome';

  /// Email + password / magic link sign-in.
  static const String signIn = '/sign-in';

  /// Account creation (email, password, username).
  static const String createAccount = '/create-account';

  /// Joining an organization from an invite link (`battuta://join/<token>`).
  ///
  /// Path parameter: `token`.
  static const String joinPath = '/join/:token';

  /// Returns the concrete path that joins with [token].
  static String join(String token) => '/join/${Uri.encodeComponent(token)}';

  /// The token of a join [location], or `null` for any other location.
  static String? joinTokenOf(String location) {
    const prefix = '/join/';
    if (!location.startsWith(prefix) || location.length == prefix.length) {
      return null;
    }
    return Uri.decodeComponent(location.substring(prefix.length));
  }

  /// Notifications inbox and invitations addressed to me.
  static const String inbox = '/inbox';

  /// Settings of one organization (name, role, quota, leave, archive).
  ///
  /// Path parameter: `organizationId`.
  static const String organizationSettingsPath =
      '/organizations/:organizationId/settings';

  /// Returns the concrete path of the settings of [organizationId].
  static String organizationSettings(String organizationId) =>
      '/organizations/${Uri.encodeComponent(organizationId)}/settings';

  /// A song (the work) with all the versions of it I can see.
  ///
  /// Path parameter: `songWorkId`.
  static const String songPagePath = '/songs/:songWorkId';

  /// Returns the concrete path of the song [songWorkId].
  static String songPage(String songWorkId) =>
      '/songs/${Uri.encodeComponent(songWorkId)}';

  /// Public songs shared by other musicians (online only).
  static const String discover = '/discover';

  /// Whether [location] belongs to the account entry flow.
  static bool isAccountEntry(String location) =>
      location == welcome || location == signIn || location == createAccount;

  // ── Bottom-nav tabs (top-level destinations) ──────────────────────────

  /// Repertoire / song library — the default landing tab.
  static const String repertoire = '/repertoire';

  /// Live session screen — real-time playback & collaboration.
  static const String live = '/live';

  /// Worship team and band roster management.
  static const String team = '/team';

  /// Settings & preferences.
  static const String settings = '/settings';

  // ── Song sub-routes ───────────────────────────────────────────────────

  /// Song detail view (read-only lead sheet).
  ///
  /// Path parameter: `songId`.
  static const String songDetailPath = '/repertoire/:songId';

  /// Returns the concrete path for a specific song detail.
  static String songDetail(String songId) => '/repertoire/$songId';

  /// Song editor (create / edit lead sheet).
  ///
  /// Path parameter: `songId` — pass `new` for a blank song.
  static const String songEditorPath = '/repertoire/:songId/edit';

  /// Returns the concrete path for editing a specific song.
  static String songEditor(String songId) => '/repertoire/$songId/edit';

  // ── Setlist sub-routes ────────────────────────────────────────────────
  /// Setlist detail & song sequencing view.
  ///
  /// Path parameter: `setlistId`.
  static const String setlistDetailPath = '/repertoire/setlists/:setlistId';

  /// Returns the concrete path for a specific setlist detail.
  static String setlistDetail(String setlistId) =>
      '/repertoire/setlists/$setlistId';

  // ── Scanner (OMR camera capture) ──────────────────────────────────────

  /// Camera-based Optical Music Recognition screen.
  static const String scanner = '/scanner';

  // ── Live session sub-routes ───────────────────────────────────────────

  /// Live session detail / lobby.
  ///
  /// Path parameter: `sessionId`.
  static const String liveSessionPath = '/live/:sessionId';

  /// Returns the concrete path for a specific live session.
  static String liveSession(String sessionId) => '/live/$sessionId';
}
