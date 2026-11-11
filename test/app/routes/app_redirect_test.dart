import 'package:battuta/app/routes/app_redirect.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? redirect(AppEntry? entry, String location, {bool notice = false}) =>
      resolveAppRedirect(entry: entry, hasNotice: notice, location: location);

  group('first launch', () {
    test('sends the app to the welcome screen', () {
      expect(
        redirect(AppEntry.firstLaunch, AppRoutes.repertoire),
        AppRoutes.welcome,
      );
      expect(redirect(AppEntry.firstLaunch, AppRoutes.team), AppRoutes.welcome);
      expect(
        redirect(AppEntry.firstLaunch, AppRoutes.settings),
        AppRoutes.welcome,
      );
    });

    test('lets the account pages open', () {
      expect(redirect(AppEntry.firstLaunch, AppRoutes.welcome), isNull);
      expect(redirect(AppEntry.firstLaunch, AppRoutes.signIn), isNull);
      expect(redirect(AppEntry.firstLaunch, AppRoutes.createAccount), isNull);
    });
  });

  group('continue offline (remembered)', () {
    test('opens the app and skips the welcome screen', () {
      expect(redirect(AppEntry.offline, AppRoutes.repertoire), isNull);
      expect(redirect(AppEntry.offline, AppRoutes.welcome), AppRoutes.initial);
    });

    test('still lets the user open sign in later', () {
      expect(redirect(AppEntry.offline, AppRoutes.signIn), isNull);
      expect(redirect(AppEntry.offline, AppRoutes.createAccount), isNull);
    });

    test('returns to the welcome screen when there is a notice', () {
      expect(
        redirect(AppEntry.offline, AppRoutes.repertoire, notice: true),
        AppRoutes.welcome,
      );
      expect(
        redirect(AppEntry.offline, AppRoutes.welcome, notice: true),
        isNull,
      );
    });

    test('keeps sign in and create account reachable with a notice', () {
      expect(
        redirect(AppEntry.offline, AppRoutes.signIn, notice: true),
        isNull,
      );
      expect(
        redirect(AppEntry.offline, AppRoutes.createAccount, notice: true),
        isNull,
      );
    });
  });

  group('signed in', () {
    test('goes straight to the app', () {
      expect(redirect(AppEntry.signedIn, AppRoutes.team), isNull);
      expect(redirect(AppEntry.signedIn, AppRoutes.settings), isNull);
    });

    test('leaves every account page', () {
      expect(redirect(AppEntry.signedIn, AppRoutes.welcome), AppRoutes.initial);
      expect(redirect(AppEntry.signedIn, AppRoutes.signIn), AppRoutes.initial);
      expect(
        redirect(AppEntry.signedIn, AppRoutes.createAccount),
        AppRoutes.initial,
      );
    });
  });

  test('does not redirect while the stored choice is loading', () {
    expect(redirect(null, AppRoutes.repertoire), isNull);
    expect(redirect(null, AppRoutes.welcome), isNull);
  });
}
