/// The Profile writes against the local Supabase stack: renaming my username
/// (free / taken, case-insensitive) and my own instruments in an organization.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration/profile_test.dart
@Tags(['supabase'])
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stack.dart';
import 'support/test_user.dart';

void main() {
  StackConfig? stack;
  late TestUser me;
  late TestUser other;
  final created = <TestUser>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    me = await TestUser.signUp(stack!, 'profme');
    created.add(me);
    other = await TestUser.signUp(stack!, 'profother');
    created.add(other);
  });

  tearDownAll(() async {
    for (final user in created) {
      await user.dispose();
    }
  });

  void itest(String name, Future<void> Function() body) {
    test(name, () async {
      if (stack == null) {
        markTestSkipped(
          'Supabase stack not available: set SUPABASE_TEST_URL / '
          'SUPABASE_TEST_ANON_KEY or run `supabase start`.',
        );
        return;
      }
      await body();
    });
  }

  Matcher failsWith(BackendErrorCode code) =>
      throwsA(isA<Failure>().having((f) => f.errorCode, 'errorCode', code));

  group('profile', () {
    itest(
      'renames the display name and a free username (normalised)',
      () async {
        final free = '${me.username}_x';
        await me.auth.updateMyProfile(
          displayName: '  New Name  ',
          username: free.toUpperCase(),
        );

        final profile = (await me.auth.fetchMyProfile())!;
        expect(profile.displayName, 'New Name');
        expect(profile.username, free);
        expect(await other.auth.isUsernameAvailable(me.username), isTrue);
        expect(await other.auth.isUsernameAvailable(free), isFalse);
      },
    );

    itest('keeping my own username (any case) is not a conflict', () async {
      final current = (await me.auth.fetchMyProfile())!.username;
      await me.auth.updateMyProfile(
        displayName: 'Same Username',
        username: current.toUpperCase(),
      );
      expect((await me.auth.fetchMyProfile())!.displayName, 'Same Username');
    });

    itest('a username in use (any case) fails with username_taken', () async {
      await expectLater(
        me.auth.updateMyProfile(
          displayName: 'Whatever',
          username: other.username.toUpperCase(),
        ),
        failsWith(BackendErrorCode.usernameTaken),
      );
      final profile = (await me.auth.fetchMyProfile())!;
      expect(profile.displayName, isNot('Whatever'));
    });

    itest('malformed values are rejected before any request', () async {
      await expectLater(
        me.auth.updateMyProfile(displayName: 'Ok', username: 'no'),
        failsWith(BackendErrorCode.invalidUsername),
      );
      await expectLater(
        me.auth.updateMyProfile(displayName: ' ', username: me.username),
        failsWith(BackendErrorCode.invalidName),
      );
    });

    itest('a member updates their own instruments, not others', () async {
      final org = ok(await me.orgs.createOrganization('Profile Org'));
      final link = ok(await me.orgs.createInviteLink(org.id));
      ok(await other.orgs.joinWithInviteLink(link.token));
      ok(await other.orgs.refreshMembers(org.id));
      final mine = (await other.orgs.watchMembers(org.id).first).firstWhere(
        (m) => m.userId == other.id,
      );

      final updated = ok(
        await other.orgs.updateMusicianProfile(
          org.id,
          mine.id,
          instruments: ['keys', 'drums'],
        ),
      );
      expect(updated.instruments, ['keys', 'drums']);

      ok(await me.orgs.refreshMembers(org.id));
      final seenByAdmin = (await me.orgs.watchMembers(org.id).first).firstWhere(
        (m) => m.userId == other.id,
      );
      expect(seenByAdmin.instruments, ['keys', 'drums']);
    });
  });
}
