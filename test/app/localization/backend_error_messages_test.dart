import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    group('backendErrorMessage (${locale.languageCode})', () {
      late AppLocalizations l10n;
      setUp(() async {
        l10n = await AppLocalizations.delegate.load(locale);
      });

      test('every backend code has a non-empty message', () {
        for (final code in BackendErrorCode.values) {
          expect(
            backendErrorMessage(l10n, code.failure(message: code.code)),
            isNotEmpty,
            reason: code.code,
          );
        }
      });

      test('the roster errors are specific', () {
        String message(BackendErrorCode c) =>
            backendErrorMessage(l10n, c.failure());
        expect(message(BackendErrorCode.offline), l10n.backendErrorOffline);
        expect(message(BackendErrorCode.notAdmin), l10n.backendErrorNotAdmin);
        expect(message(BackendErrorCode.lastAdmin), l10n.backendErrorLastAdmin);
        expect(
          message(BackendErrorCode.usernameTaken),
          l10n.usernameTakenError,
        );
        expect(message(BackendErrorCode.unknown), l10n.backendErrorGeneric);
      });

      test('the repertoire and archive errors are specific', () {
        String message(BackendErrorCode c) =>
            backendErrorMessage(l10n, c.failure());
        expect(message(BackendErrorCode.notOwner), l10n.backendErrorNotOwner);
        expect(
          message(BackendErrorCode.permissionDenied),
          l10n.backendErrorPermissionDenied,
        );
        expect(
          message(BackendErrorCode.archiveAlreadyRequested),
          l10n.backendErrorArchiveAlreadyRequested,
        );
        expect(
          message(BackendErrorCode.archiveNotRequested),
          l10n.backendErrorArchiveNotRequested,
        );
        expect(l10n.backendErrorNotOwner, isNot(l10n.backendErrorGeneric));
      });

      test('an untyped server message (e.g. wrong password) is kept', () {
        expect(
          backendErrorMessage(
            l10n,
            const ServerFailure(message: 'Invalid login credentials'),
          ),
          'Invalid login credentials',
        );
      });

      test('anything that is not a Failure is generic', () {
        expect(
          backendErrorMessage(l10n, StateError('x')),
          l10n.backendErrorGeneric,
        );
      });
    });
  }
}
