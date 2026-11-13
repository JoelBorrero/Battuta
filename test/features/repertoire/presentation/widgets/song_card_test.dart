import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final song = Song(
    id: 'song-1',
    title: 'Amazing Grace',
    artist: 'John Newton',
    key: 'G',
    tempo: 72,
    timeSignature: (3, 4),
    tags: const ['Hymn', 'Classic'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Widget buildSubject({double width = 400}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: SongCard(song: song),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/repertoire/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
        ),
      ],
    );
    return MaterialApp.router(theme: AppTheme.dark, routerConfig: router);
  }

  testWidgets('shows title, artist · tempo · meter line, key pill and tags', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(StageKeyPill, 'G'), findsOneWidget);
    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('John Newton · 72 BPM · 3/4'), findsOneWidget);
    expect(find.text('Hymn'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
  });

  testWidgets('omits the 4/4 meter and skips missing parts', (tester) async {
    expect(
      SongCard.metaLine(song.copyWith(timeSignature: (4, 4))),
      'John Newton · 72 BPM',
    );
    expect(
      SongCard.metaLine(song.copyWith(artist: '', timeSignature: (6, 8))),
      '72 BPM · 6/8',
    );
  });

  testWidgets('navigates to song detail on tap', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();

    expect(find.text('detail song-1'), findsOneWidget);
  });

  testWidgets('does not overflow on narrow widths', (tester) async {
    await tester.pumpWidget(buildSubject(width: 220));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
