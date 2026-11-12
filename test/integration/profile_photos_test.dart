/// Profile photos and organization logos against the local Supabase stack:
/// uploading, replacing and removing a photo, who may write which folder, the
/// size limit, and the public URLs the app builds.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration/profile_photos_test.dart
@Tags(['supabase'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stack.dart';
import 'support/test_user.dart';

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser member;
  late TestUser outsider;
  final created = <TestUser>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'photoadmin');
    created.add(admin);
    member = await TestUser.signUp(stack!, 'photomember');
    created.add(member);
    outsider = await TestUser.signUp(stack!, 'photoother');
    created.add(outsider);
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

  /// A deleted public object answers 400 or 404 depending on the Storage version.
  final gone = isIn([400, 404]);

  Matcher failsWith(BackendErrorCode code) =>
      throwsA(isA<Failure>().having((f) => f.errorCode, 'errorCode', code));

  /// Not a decodable image: Storage checks the declared type and the size.
  Uint8List fakeJpeg(int length, [int seed = 7]) =>
      Uint8List.fromList(List.generate(length, (i) => (i * seed) % 251));

  /// The status and body of an anonymous GET of [url] (no session).
  Future<(int, List<int>)> fetch(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.fold<List<int>>([], (a, b) => a..addAll(b));
      return (response.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }

  String urlOf(TestUser user, PhotoBucket bucket, String? path) =>
      photoPublicUrl(user.client, bucket, path)!;

  Future<Organization> orgWithMember() async {
    final org = ok(
      await admin.orgs.createOrganization(
        'Photos ${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final link = ok(await admin.orgs.createInviteLink(org.id));
    ok(await member.orgs.joinWithInviteLink(link.token));
    return org;
  }

  group('profile photo', () {
    itest('uploads, serves publicly, replaces and removes', () async {
      final first = fakeJpeg(3000);
      await member.auth.setMyAvatar(first);

      final profile = (await member.auth.fetchMyProfile())!;
      final path1 = profile.avatarPath!;
      expect(path1, startsWith('${member.id}/'));
      expect(path1, endsWith('.jpg'));
      final (status1, body1) = await fetch(
        urlOf(member, PhotoBucket.avatars, path1),
      );
      expect(status1, 200);
      expect(body1, first);

      // Replacing uses a new path and deletes the previous object.
      final second = fakeJpeg(4000, 11);
      await member.auth.setMyAvatar(second);
      final path2 = (await member.auth.fetchMyProfile())!.avatarPath!;
      expect(path2, isNot(path1));
      expect((await fetch(urlOf(member, PhotoBucket.avatars, path2))).$1, 200);
      expect((await fetch(urlOf(member, PhotoBucket.avatars, path1))).$1, gone);

      // Removing clears the row and the object.
      await member.auth.removeMyAvatar();
      expect((await member.auth.fetchMyProfile())!.avatarPath, isNull);
      expect((await fetch(urlOf(member, PhotoBucket.avatars, path2))).$1, gone);
    });

    itest('a photo over 2 MB is refused and the old one stays', () async {
      await member.auth.setMyAvatar(fakeJpeg(2000));
      final before = (await member.auth.fetchMyProfile())!.avatarPath;

      await expectLater(
        member.auth.setMyAvatar(fakeJpeg(2 * 1024 * 1024 + 1024)),
        failsWith(BackendErrorCode.imageTooLarge),
      );

      expect((await member.auth.fetchMyProfile())!.avatarPath, before);
    });

    itest('nobody writes into someone else\'s folder', () async {
      await expectLater(
        outsider.client.storage
            .from(PhotoBucket.avatars.id)
            .uploadBinary('${member.id}/intruder.jpg', fakeJpeg(100)),
        throwsA(isA<Object>()),
      );
      // Nor can a row point at another user's object.
      await expectLater(
        outsider.client
            .from('profiles')
            .update({'avatar_path': '${member.id}/x.jpg'})
            .eq('id', outsider.id),
        throwsA(isA<Object>()),
      );
    });

    itest('other members of an organization see the new path', () async {
      final org = await orgWithMember();
      await member.auth.setMyAvatar(fakeJpeg(1500));
      final path = (await member.auth.fetchMyProfile())!.avatarPath;

      ok(await admin.orgs.refreshMembers(org.id));
      final members = await admin.orgs.watchMembers(org.id).first;
      final seen = members.firstWhere((m) => m.userId == member.id);
      expect(seen.avatarPath, path);
    });
  });

  group('organization logo', () {
    itest('an admin sets, replaces and removes the logo', () async {
      final org = await orgWithMember();
      final jpeg = fakeJpeg(2500);

      final withLogo = ok(await admin.orgs.setOrganizationLogo(org.id, jpeg));
      expect(withLogo.logoPath, startsWith('${org.id}/'));
      expect(withLogo.isAdmin, isTrue);
      final (status, body) = await fetch(
        urlOf(admin, PhotoBucket.organizationLogos, withLogo.logoPath),
      );
      expect(status, 200);
      expect(body, jpeg);

      final replaced = ok(
        await admin.orgs.setOrganizationLogo(org.id, fakeJpeg(2600, 13)),
      );
      expect(replaced.logoPath, isNot(withLogo.logoPath));
      expect(
        (await fetch(
          urlOf(admin, PhotoBucket.organizationLogos, withLogo.logoPath),
        )).$1,
        gone,
      );

      // The member sees it after a refresh.
      ok(await member.orgs.refreshOrganizations());
      final memberView = (await member.orgs.watchOrganizations().first)
          .firstWhere((o) => o.id == org.id);
      expect(memberView.logoPath, replaced.logoPath);

      final cleared = ok(await admin.orgs.removeOrganizationLogo(org.id));
      expect(cleared.logoPath, isNull);
      expect(
        (await fetch(
          urlOf(admin, PhotoBucket.organizationLogos, replaced.logoPath),
        )).$1,
        gone,
      );
    });

    itest('a member cannot change the logo', () async {
      final org = await orgWithMember();

      final result = await member.orgs.setOrganizationLogo(
        org.id,
        fakeJpeg(500),
      );

      expect(failed(result), BackendErrorCode.permissionDenied);
      final removal = await member.orgs.removeOrganizationLogo(org.id);
      expect(removal.isLeft(), isTrue);
    });

    itest('an outsider cannot change the logo either', () async {
      final org = await orgWithMember();
      final result = await outsider.orgs.setOrganizationLogo(
        org.id,
        fakeJpeg(500),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('organization description', () {
    itest('an admin edits name and description; blank clears it', () async {
      final org = await orgWithMember();

      final edited = ok(
        await admin.orgs.updateOrganizationProfile(
          org.id,
          name: 'Renamed ${org.id.substring(0, 4)}',
          description: '  Thursdays at 7 pm  ',
        ),
      );
      expect(edited.description, 'Thursdays at 7 pm');
      expect(edited.name, startsWith('Renamed'));

      final cleared = ok(
        await admin.orgs.updateOrganizationProfile(
          org.id,
          name: edited.name,
          description: '   ',
        ),
      );
      expect(cleared.description, isNull);
    });

    itest('over 280 characters is refused', () async {
      final org = await orgWithMember();
      final result = await admin.orgs.updateOrganizationProfile(
        org.id,
        name: 'Long description',
        description: 'x' * 281,
      );
      expect(result.isLeft(), isTrue);
    });

    itest('a member cannot edit the profile', () async {
      final org = await orgWithMember();
      final result = await member.orgs.updateOrganizationProfile(
        org.id,
        name: 'Hijacked',
        description: 'nope',
      );
      expect(result.isLeft(), isTrue);
    });
  });
}
