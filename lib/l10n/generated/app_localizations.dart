import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Battuta'**
  String get appName;

  /// Generic cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Generic dismiss button text
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Generic search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// All filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Bottom nav item for Repertoire
  ///
  /// In en, this message translates to:
  /// **'Repertoire'**
  String get navRepertoire;

  /// Bottom nav item for Scan
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// Bottom nav item for Setlists
  ///
  /// In en, this message translates to:
  /// **'Setlists'**
  String get navSetlists;

  /// Bottom nav item for Team and Band Calendar
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// Bottom nav item for Live Session
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// Bottom nav item for Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Settings page header title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header for appearance settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// Theme tile title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Theme tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or system mode'**
  String get themeSubtitle;

  /// Light theme mode button
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme mode button
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// System theme mode button
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Section header for language settings
  ///
  /// In en, this message translates to:
  /// **'Language / Idioma'**
  String get languageSection;

  /// Language tile title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Language tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Select your preferred application language'**
  String get languageSubtitle;

  /// Auto/System language option
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Supabase cloud sync section header
  ///
  /// In en, this message translates to:
  /// **'Cloud Synchronization (Supabase)'**
  String get cloudSyncSection;

  /// Cloud account tile label
  ///
  /// In en, this message translates to:
  /// **'Cloud Account'**
  String get cloudAccountLabel;

  /// Supabase connection tile label
  ///
  /// In en, this message translates to:
  /// **'Supabase Connection'**
  String get supabaseConnectionLabel;

  /// Sync status tile label
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatusLabel;

  /// Sync now action button
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Sign out action button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// About section header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// Tab title for team roster
  ///
  /// In en, this message translates to:
  /// **'Team Roster'**
  String get teamRosterTab;

  /// Tab title for band calendar
  ///
  /// In en, this message translates to:
  /// **'Band Calendar'**
  String get bandCalendarTab;

  /// Button to add a musician
  ///
  /// In en, this message translates to:
  /// **'Add Musician'**
  String get addMusician;

  /// Button to add a service event
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// Button to open recurring schedules manager
  ///
  /// In en, this message translates to:
  /// **'Recurring Schedules'**
  String get recurringSchedules;

  /// Heading for recurring and upcoming services list
  ///
  /// In en, this message translates to:
  /// **'Periodic & Upcoming Services'**
  String get periodicServicesTitle;

  /// Badge for immediate next upcoming service
  ///
  /// In en, this message translates to:
  /// **'NEXT SERVICE'**
  String get nextService;

  /// Action button to find substitute musician
  ///
  /// In en, this message translates to:
  /// **'Find Cover'**
  String get findCover;

  /// Section title for workspace resource consumption
  ///
  /// In en, this message translates to:
  /// **'Workspace Resources & Quota'**
  String get workspaceResourcesSection;

  /// Label for active workspace pool
  ///
  /// In en, this message translates to:
  /// **'ACTIVE WORKSPACE POOL'**
  String get activeWorkspacePool;

  /// Title for Gemini AI credits gauge
  ///
  /// In en, this message translates to:
  /// **'Gemini AI Credits'**
  String get geminiAiCredits;

  /// Title for Cloud storage gauge
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage'**
  String get cloudStorage;

  /// Title for advanced developer options
  ///
  /// In en, this message translates to:
  /// **'Developer & Custom Endpoints'**
  String get developerOptions;

  /// Subtitle for developer options
  ///
  /// In en, this message translates to:
  /// **'Configure custom Supabase URL and local AI keys'**
  String get developerOptionsSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
