/// The signed-in account as seen by the organization data layer.
library;

abstract interface class AccountSession {
  /// The id of the signed-in account, or `null` when signed out / offline-only.
  String? get userId;

  /// Emits the account id every time it changes (`null` on sign-out).
  Stream<String?> get userIdChanges;

  /// Ends the current session (used when the account is deactivated).
  Future<void> signOut();
}
