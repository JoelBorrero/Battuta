import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:battuta/features/profile/presentation/widgets/organization_logo.dart';
import 'package:battuta/features/profile/presentation/widgets/person_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {PhotoUrlBuilder? urls}) => ProviderScope(
  overrides: [
    photoUrlBuilderProvider.overrideWithValue(urls ?? (_, _) => null),
  ],
  child: MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

/// A URL builder that points at a host nothing listens on: the image fails.
String? deadUrl(PhotoBucket bucket, String? path) =>
    path == null ? null : 'http://127.0.0.1:9/${bucket.id}/$path';

void main() {
  group('PersonAvatar', () {
    testWidgets('no photo: shows the initials', (tester) async {
      await tester.pumpWidget(host(const PersonAvatar(name: 'Maria Lopez')));
      expect(find.text('ML'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('no name: shows a person icon', (tester) async {
      await tester.pumpWidget(host(const PersonAvatar()));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('with a photo path: loads the image from its URL', (
      tester,
    ) async {
      final asked = <String>[];
      await tester.pumpWidget(
        host(
          const PersonAvatar(name: 'Maria Lopez', avatarPath: 'u1/a.jpg'),
          urls: (bucket, path) {
            asked.add('${bucket.id}:$path');
            return deadUrl(bucket, path);
          },
        ),
      );
      expect(asked, contains('avatars:u1/a.jpg'));
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, contains('u1/a.jpg'));
    });

    testWidgets('an image that fails to load leaves the initials', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const PersonAvatar(name: 'Maria Lopez', avatarPath: 'u1/a.jpg'),
          urls: deadUrl,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ML'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deactivated: greyed initials and never a photo', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const PersonAvatar(
            name: 'Pablo Garcia',
            avatarPath: 'u1/a.jpg',
            deactivated: true,
          ),
          urls: deadUrl,
        ),
      );
      expect(find.text('PG'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('ring: draws the amber border', (tester) async {
      await tester.pumpWidget(
        host(const PersonAvatar(name: 'Maria Lopez', ring: true)),
      );
      final box =
          tester.widget<Container>(find.byType(Container).first).decoration
              as BoxDecoration;
      expect(box.border, isNotNull);
    });
  });

  group('OrganizationLogo', () {
    testWidgets('no logo: the music-note tile', (tester) async {
      await tester.pumpWidget(host(const OrganizationLogo()));
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('with a logo path: loads the image from the logos bucket', (
      tester,
    ) async {
      final asked = <String>[];
      await tester.pumpWidget(
        host(
          const OrganizationLogo(logoPath: 'o1/l.jpg'),
          urls: (bucket, path) {
            asked.add('${bucket.id}:$path');
            return deadUrl(bucket, path);
          },
        ),
      );
      expect(asked, contains('organization-logos:o1/l.jpg'));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a failing image leaves the tile', (tester) async {
      await tester.pumpWidget(
        host(const OrganizationLogo(logoPath: 'o1/l.jpg'), urls: deadUrl),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('corner radius scales with the size', () {
      expect(OrganizationLogo.radiusFor(96), closeTo(26.9, 0.1));
      expect(OrganizationLogo.radiusFor(48), closeTo(13.4, 0.1));
    });
  });
}
