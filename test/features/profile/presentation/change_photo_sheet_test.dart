import 'dart:typed_data';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/core/services/profile_image_picker.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:battuta/features/profile/presentation/widgets/change_photo_sheet.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../support/fake_profile_image_picker.dart';

void main() {
  late FakePicker picker;
  late List<Uint8List> saved;
  var removed = 0;
  Either<Failure, Unit> saveResult = right(unit);
  Either<Failure, Unit> removeResult = right(unit);
  PhotoSheetResult? closedWith;

  setUp(() {
    picker = FakePicker();
    saved = [];
    removed = 0;
    saveResult = right(unit);
    removeResult = right(unit);
    closedWith = null;
  });

  Future<void> open(
    WidgetTester tester, {
    String? currentPath,
    PhotoShape shape = PhotoShape.circle,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileImagePickerProvider.overrideWithValue(picker),
          photoUrlBuilderProvider.overrideWithValue((_, _) => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('open'),
                  onPressed: () async {
                    closedWith = await showChangePhotoSheet(
                      context,
                      shape: shape,
                      bucket: PhotoBucket.avatars,
                      title: 'Profile photo',
                      subtitle: 'Shown to your bandmates and on your songs',
                      currentPath: currentPath,
                      onSave: (jpeg) async {
                        saved.add(jpeg);
                        return saveResult;
                      },
                      onRemove: () async {
                        removed++;
                        return removeResult;
                      },
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));
  bool enabled(WidgetTester tester, String key) =>
      tester.widget<FilledButton>(byKey(key)).onPressed != null;

  testWidgets('shows the title, the actions and a disabled save', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Profile photo'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('Save photo'), findsOneWidget);
    expect(enabled(tester, 'photo_save_btn'), isFalse);
    // No photo yet: nothing to remove.
    expect(byKey('photo_remove_btn'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remove only shows when there is a photo', (tester) async {
    await open(tester, currentPath: 'u1/a.jpg');
    expect(byKey('photo_remove_btn'), findsOneWidget);
  });

  testWidgets('take photo then save uploads the picked image', (tester) async {
    picker.result = pixel;
    await open(tester);

    await tester.tap(byKey('photo_take_btn'));
    await tester.pumpAndSettle();
    expect(picker.picks.single, (PhotoSource.camera, PhotoShape.circle));
    expect(enabled(tester, 'photo_save_btn'), isTrue);

    await tester.tap(byKey('photo_save_btn'));
    await tester.pumpAndSettle();

    expect(saved.single, pixel);
    expect(closedWith, PhotoSheetResult.saved);
    expect(byKey('photo_save_btn'), findsNothing);
  });

  testWidgets('choose photo uses the library and the logo shape', (
    tester,
  ) async {
    picker.result = pixel;
    await open(tester, shape: PhotoShape.square);

    await tester.tap(byKey('photo_choose_btn'));
    await tester.pumpAndSettle();

    expect(picker.picks.single, (PhotoSource.gallery, PhotoShape.square));
  });

  testWidgets('a cancelled pick or crop changes nothing', (tester) async {
    picker.result = null;
    await open(tester);

    await tester.tap(byKey('photo_choose_btn'));
    await tester.pumpAndSettle();

    expect(enabled(tester, 'photo_save_btn'), isFalse);
    expect(byKey('photo_sheet_error'), findsNothing);
  });

  testWidgets('a picker error shows a localized message', (tester) async {
    picker.error = Exception('camera denied');
    await open(tester);

    await tester.tap(byKey('photo_take_btn'));
    await tester.pumpAndSettle();

    expect(byKey('photo_sheet_error'), findsOneWidget);
    expect(
      find.textContaining('Check the app’s permissions in Settings'),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps the sheet open with the message', (
    tester,
  ) async {
    picker.result = pixel;
    saveResult = left(BackendErrorCode.offline.failure());
    await open(tester);
    await tester.tap(byKey('photo_choose_btn'));
    await tester.pumpAndSettle();

    await tester.tap(byKey('photo_save_btn'));
    await tester.pumpAndSettle();

    expect(byKey('photo_sheet_error'), findsOneWidget);
    expect(byKey('photo_save_btn'), findsOneWidget);
    expect(closedWith, isNull);
    // Still savable once the connection is back.
    expect(enabled(tester, 'photo_save_btn'), isTrue);
  });

  testWidgets('an oversized photo says so', (tester) async {
    picker.result = pixel;
    saveResult = left(BackendErrorCode.imageTooLarge.failure());
    await open(tester);
    await tester.tap(byKey('photo_choose_btn'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('photo_save_btn'));
    await tester.pumpAndSettle();

    expect(
      find.text('That photo is too large. Pick a smaller one.'),
      findsOneWidget,
    );
  });

  testWidgets('remove clears the photo and closes with removed', (
    tester,
  ) async {
    await open(tester, currentPath: 'u1/a.jpg');

    await tester.tap(byKey('photo_remove_btn'));
    await tester.pumpAndSettle();

    expect(removed, 1);
    expect(closedWith, PhotoSheetResult.removed);
  });

  testWidgets('a failed remove keeps the sheet open', (tester) async {
    removeResult = left(BackendErrorCode.offline.failure());
    await open(tester, currentPath: 'u1/a.jpg');

    await tester.tap(byKey('photo_remove_btn'));
    await tester.pumpAndSettle();

    expect(byKey('photo_sheet_error'), findsOneWidget);
    expect(byKey('photo_remove_btn'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('no overflow at $width px', (tester) async {
      picker.result = pixel;
      await open(tester, currentPath: 'u1/a.jpg', width: width);
      await tester.tap(byKey('photo_choose_btn'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
