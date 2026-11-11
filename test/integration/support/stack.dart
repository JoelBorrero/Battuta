/// Finds the local Supabase stack for the integration tests.
///
/// URL and anon key come from `SUPABASE_TEST_URL` / `SUPABASE_TEST_ANON_KEY`,
/// or from `supabase status -o json`. Nothing is hardcoded or read from `.env`.
library;

import 'dart:convert';
import 'dart:io';

class StackConfig {
  const StackConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;
}

/// Resolves the stack, or returns `null` (with a printed reason) when it is
/// not configured or not reachable.
Future<StackConfig?> resolveStack() async {
  var url = Platform.environment['SUPABASE_TEST_URL'];
  var key = Platform.environment['SUPABASE_TEST_ANON_KEY'];

  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    try {
      final result = await Process.run('supabase', ['status', '-o', 'json']);
      if (result.exitCode == 0) {
        final text = result.stdout as String;
        final start = text.indexOf('{');
        final json = jsonDecode(text.substring(start)) as Map<String, dynamic>;
        url = json['API_URL'] as String?;
        key = (json['ANON_KEY'] ?? json['PUBLISHABLE_KEY']) as String?;
      }
    } catch (_) {
      // Fall through to the skip message below.
    }
  }

  if (url == null || key == null || url.isEmpty || key.isEmpty) {
    // ignore: avoid_print
    print(
      'Skipping Supabase integration tests: set SUPABASE_TEST_URL and '
      'SUPABASE_TEST_ANON_KEY, or start the stack with `supabase start`.',
    );
    return null;
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client.getUrl(Uri.parse('$url/auth/v1/health'));
    request.headers.set('apikey', key);
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode >= 500) throw const SocketException('unhealthy');
  } catch (_) {
    // ignore: avoid_print
    print('Skipping Supabase integration tests: $url is not reachable.');
    return null;
  } finally {
    client.close(force: true);
  }
  return StackConfig(url: url, anonKey: key);
}
