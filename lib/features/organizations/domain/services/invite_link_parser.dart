/// Reads and writes `battuta://join/<token>` invite links.
library;

/// The URL scheme registered by the app.
const String inviteLinkScheme = 'battuta';

/// The host (first segment after the scheme) of a join link.
const String inviteLinkHost = 'join';

/// A join token as the backend issues it (64 hex characters); a little wider
/// here so a different length never locks someone out.
final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

/// The shareable link for [token].
String inviteLinkFor(String token) => '$inviteLinkScheme://$inviteLinkHost/$token';

/// The token inside a `battuta://join/<token>` [uri], or `null` when [uri] is
/// anything else (other scheme, other host, no token).
String? inviteTokenFromUri(Uri uri) {
  if (uri.scheme.toLowerCase() != inviteLinkScheme) return null;
  final segments = [
    for (final s in uri.pathSegments)
      if (s.isNotEmpty) s,
  ];
  // `battuta://join/<token>` (host form) or `battuta:///join/<token>`.
  final String? token;
  if (uri.host.toLowerCase() == inviteLinkHost) {
    token = segments.isEmpty ? null : segments.first;
  } else if (uri.host.isEmpty &&
      segments.length >= 2 &&
      segments.first.toLowerCase() == inviteLinkHost) {
    token = segments[1];
  } else {
    token = null;
  }
  return token != null && _tokenPattern.hasMatch(token) ? token : null;
}

/// Parses what a person pastes: a `battuta://join/<token>` link or a bare
/// token. Surrounding whitespace is ignored. Anything else (another scheme,
/// a web link, free text) returns `null`.
String? parseInviteInput(String? input) {
  final text = (input ?? '').trim();
  if (text.isEmpty) return null;
  if (text.contains('://') || text.contains('/')) {
    final uri = Uri.tryParse(text);
    return uri == null ? null : inviteTokenFromUri(uri);
  }
  return _tokenPattern.hasMatch(text) ? text : null;
}
