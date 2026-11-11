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
