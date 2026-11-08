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

  /// Tab label for team roster
  ///
  /// In en, this message translates to:
  /// **'Team Roster'**
  String get teamRosterTab;

  /// Tab label for band calendar
  ///
  /// In en, this message translates to:
  /// **'Band Calendar'**
  String get bandCalendarTab;

  /// Button to add a musician or team member
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMusician;

  /// Button to create a new service
  ///
  /// In en, this message translates to:
  /// **'New Service'**
  String get addService;

  /// Label for recurring schedules
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

  /// Repertoire screen title
  ///
  /// In en, this message translates to:
  /// **'Repertoire'**
  String get repertoireTitle;

  /// Chord chart view mode segment
  ///
  /// In en, this message translates to:
  /// **'Chord Chart'**
  String get chordChart;

  /// Musical staff notation view mode segment
  ///
  /// In en, this message translates to:
  /// **'Musical Staff'**
  String get musicalStaff;

  /// Button and title for creating a new song
  ///
  /// In en, this message translates to:
  /// **'New Song'**
  String get newSong;

  /// Title for editing a song
  ///
  /// In en, this message translates to:
  /// **'Edit Song'**
  String get editSong;

  /// Add song button label
  ///
  /// In en, this message translates to:
  /// **'Add Song'**
  String get addSong;

  /// Delete song button label
  ///
  /// In en, this message translates to:
  /// **'Delete Song'**
  String get deleteSong;

  /// Delete song confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Song?'**
  String get deleteSongTitle;

  /// Delete song confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteSongConfirm(String title);

  /// Snackbar shown after deleting a song
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deletedSongSuccess(String title);

  /// Button label for creating a new setlist
  ///
  /// In en, this message translates to:
  /// **'New Setlist'**
  String get newSetlist;

  /// Action button to submit new setlist
  ///
  /// In en, this message translates to:
  /// **'Create Setlist'**
  String get createSetlist;

  /// Title for create new setlist dialog
  ///
  /// In en, this message translates to:
  /// **'Create New Setlist'**
  String get createNewSetlist;

  /// Title for editing a setlist
  ///
  /// In en, this message translates to:
  /// **'Edit Setlist'**
  String get editSetlist;

  /// Title for delete setlist confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Setlist?'**
  String get deleteSetlistTitle;

  /// Message for delete setlist dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteSetlistConfirm(String title);

  /// Snackbar shown after deleting a setlist
  ///
  /// In en, this message translates to:
  /// **'Deleted setlist \"{title}\"'**
  String deletedSetlistSuccess(String title);

  /// Snackbar shown after creating a setlist
  ///
  /// In en, this message translates to:
  /// **'Created setlist \"{title}\"'**
  String createdSetlistSuccess(String title);

  /// Label for songs segment tab
  ///
  /// In en, this message translates to:
  /// **'Songs ({count})'**
  String songsTab(int count);

  /// Label for setlists segment tab
  ///
  /// In en, this message translates to:
  /// **'Setlists ({count})'**
  String setlistsTab(int count);

  /// Tooltip for scan sheet music action
  ///
  /// In en, this message translates to:
  /// **'Scan sheet music'**
  String get scanSheetMusicTooltip;

  /// Tooltip for search songs action
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get searchSongsTooltip;

  /// Placeholder text in songs search view
  ///
  /// In en, this message translates to:
  /// **'Type to search songs…'**
  String get typeToSearchSongs;

  /// Empty state text when search yields no matches
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// Error banner when repertoire cannot be fetched
  ///
  /// In en, this message translates to:
  /// **'Failed to load repertoire'**
  String get failedToLoadRepertoire;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title when repertoire has no songs
  ///
  /// In en, this message translates to:
  /// **'Your repertoire is empty'**
  String get repertoireEmpty;

  /// Hint for admins when repertoire is empty
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first song'**
  String get repertoireEmptyAdminHint;

  /// Hint for team members when repertoire is empty
  ///
  /// In en, this message translates to:
  /// **'No songs available yet. Contact an administrator to add songs.'**
  String get repertoireEmptyMemberHint;

  /// Button to load pre-seeded sample songs
  ///
  /// In en, this message translates to:
  /// **'Load Sample Songs'**
  String get loadSampleSongs;

  /// Button to trigger camera score scan
  ///
  /// In en, this message translates to:
  /// **'Scan Score'**
  String get scanScore;

  /// Heading when setlists list is empty
  ///
  /// In en, this message translates to:
  /// **'No Setlists Yet'**
  String get noSetlistsYet;

  /// Hint for admins when setlists list is empty
  ///
  /// In en, this message translates to:
  /// **'Create an ordered setlist for Sunday services or rehearsals.'**
  String get setlistsEmptyAdminHint;

  /// Hint for team members when setlists list is empty
  ///
  /// In en, this message translates to:
  /// **'No setlists created yet. Setlists will appear here once published by your director.'**
  String get setlistsEmptyMemberHint;

  /// Button to load a pre-seeded setlist
  ///
  /// In en, this message translates to:
  /// **'Load Sample Setlist'**
  String get loadSampleSetlist;

  /// Subtitle count of songs in a setlist
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String setlistSongsCount(int count);

  /// Default description for a setlist without notes
  ///
  /// In en, this message translates to:
  /// **'Upcoming service'**
  String get upcomingService;

  /// Label for setlist title input
  ///
  /// In en, this message translates to:
  /// **'Setlist Title *'**
  String get setlistTitleField;

  /// Hint for setlist title input
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunday Morning - Easter'**
  String get setlistTitleHint;

  /// Label for setlist notes input
  ///
  /// In en, this message translates to:
  /// **'Notes / Service Theme'**
  String get notesServiceThemeField;

  /// Hint for setlist notes input
  ///
  /// In en, this message translates to:
  /// **'e.g. Acoustic setup, communion song in D'**
  String get notesServiceThemeHint;

  /// Tooltip for delete setlist icon button
  ///
  /// In en, this message translates to:
  /// **'Delete setlist'**
  String get deleteSetlistTooltip;

  /// Title for song detail view
  ///
  /// In en, this message translates to:
  /// **'Song Detail'**
  String get songDetail;

  /// Title for transpose bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Transpose Song'**
  String get transposeSong;

  /// Reset action button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Label indicating song is in original key
  ///
  /// In en, this message translates to:
  /// **'Original Key'**
  String get originalKey;

  /// Semitone delta display
  ///
  /// In en, this message translates to:
  /// **'{prefix}{count} semitones'**
  String semitonesCount(String prefix, int count);

  /// Tooltip for lowering transposition
  ///
  /// In en, this message translates to:
  /// **'Down 1 semitone'**
  String get downOneSemitone;

  /// Tooltip for raising transposition
  ///
  /// In en, this message translates to:
  /// **'Up 1 semitone'**
  String get upOneSemitone;

  /// Button to persist transposed key
  ///
  /// In en, this message translates to:
  /// **'Save Transposed Key ({key}) to Song'**
  String saveTransposedKey(String key);

  /// Tooltip for transpose button in app bar
  ///
  /// In en, this message translates to:
  /// **'Transpose Key'**
  String get transposeKeyTooltip;

  /// Tooltip for notation editor button in app bar
  ///
  /// In en, this message translates to:
  /// **'Notation Editor'**
  String get notationEditorTooltip;

  /// Tooltip for exporting PDF lead sheet
  ///
  /// In en, this message translates to:
  /// **'Export PDF Lead Sheet'**
  String get exportPdfTooltip;

  /// Tooltip for exporting MIDI file
  ///
  /// In en, this message translates to:
  /// **'Export MIDI File'**
  String get exportMidiTooltip;

  /// Header for interactive notation section
  ///
  /// In en, this message translates to:
  /// **'Interactive Notation View'**
  String get interactiveNotationView;

  /// Button to jump directly into notation editor
  ///
  /// In en, this message translates to:
  /// **'Edit in Notation Editor'**
  String get editInNotationEditor;

  /// Message when song has no chord sections
  ///
  /// In en, this message translates to:
  /// **'This song has no sections yet.'**
  String get noSectionsYet;

  /// Badge showing repeat count for a section
  ///
  /// In en, this message translates to:
  /// **'Repeat {count}×'**
  String repeatTimes(int count);

  /// Duration in beats of a chord cell
  ///
  /// In en, this message translates to:
  /// **'{count} beats'**
  String beatsCount(int count);

  /// Button to return to repertoire list
  ///
  /// In en, this message translates to:
  /// **'Back to Repertoire'**
  String get backToRepertoire;

  /// Message shown when song ID does not exist
  ///
  /// In en, this message translates to:
  /// **'Song not found in repertoire'**
  String get songNotFound;

  /// Badge showing song musical key
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String songKeyBadge(String key);

  /// Error snackbar when PDF export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export PDF: {error}'**
  String failedToExportPdf(String error);

  /// Error snackbar when MIDI export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export MIDI: {error}'**
  String failedToExportMidi(String error);

  /// Button label for non-admin viewers
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get viewOnly;

  /// Banner message explaining read-only song state
  ///
  /// In en, this message translates to:
  /// **'Read-only view: Administrator permissions are required to create or modify repertoire songs.'**
  String get readOnlyAdminWarning;

  /// Form label for song title
  ///
  /// In en, this message translates to:
  /// **'Song Title *'**
  String get songTitleLabel;

  /// Form placeholder for song title
  ///
  /// In en, this message translates to:
  /// **'e.g. Amazing Grace'**
  String get songTitleHint;

  /// Validation error for missing song title
  ///
  /// In en, this message translates to:
  /// **'Please enter a song title'**
  String get songTitleValidation;

  /// Form label for artist or composer
  ///
  /// In en, this message translates to:
  /// **'Artist / Composer *'**
  String get artistComposerLabel;

  /// Form placeholder for artist or composer
  ///
  /// In en, this message translates to:
  /// **'e.g. John Newton'**
  String get artistComposerHint;

  /// Validation error for missing artist
  ///
  /// In en, this message translates to:
  /// **'Please enter an artist or composer'**
  String get artistValidation;

  /// Section header for key, meter, tempo
  ///
  /// In en, this message translates to:
  /// **'Musical Setup'**
  String get musicalSetup;

  /// Label for musical key selector
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyLabel;

  /// Label for time signature selector
  ///
  /// In en, this message translates to:
  /// **'Meter'**
  String get meterLabel;

  /// Tooltip for decrementing tempo
  ///
  /// In en, this message translates to:
  /// **'Decrease BPM'**
  String get decreaseBpm;

  /// Tooltip for incrementing tempo
  ///
  /// In en, this message translates to:
  /// **'Increase BPM'**
  String get increaseBpm;

  /// Tap tempo button label
  ///
  /// In en, this message translates to:
  /// **'Tap Tempo'**
  String get tapTempo;

  /// Input label and tooltip for adding a tag
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// Placeholder for tag input
  ///
  /// In en, this message translates to:
  /// **'e.g. worship, rock, ballad'**
  String get tagHint;

  /// Label for song performance notes
  ///
  /// In en, this message translates to:
  /// **'Notes / Performance Instructions'**
  String get notesInstructionsLabel;

  /// Placeholder for song performance notes
  ///
  /// In en, this message translates to:
  /// **'e.g. Capo 3rd fret, slow acoustic intro...'**
  String get notesInstructionsHint;

  /// Header for song sections list
  ///
  /// In en, this message translates to:
  /// **'Song Sections ({count})'**
  String songSectionsCount(int count);

  /// Button to add a section
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSection;

  /// Prefix label for quick section chips
  ///
  /// In en, this message translates to:
  /// **'Quick add: '**
  String get quickAdd;

  /// Message when no sections have been added to editor
  ///
  /// In en, this message translates to:
  /// **'No sections added. Tap \"+ Add Section\" to build your song.'**
  String get noSectionsAddedHint;

  /// Label for section name input
  ///
  /// In en, this message translates to:
  /// **'Section Name'**
  String get sectionName;

  /// Tooltip for decreasing section repeats
  ///
  /// In en, this message translates to:
  /// **'Decrease repeats'**
  String get decreaseRepeats;

  /// Tooltip for increasing section repeats
  ///
  /// In en, this message translates to:
  /// **'Increase repeats'**
  String get increaseRepeats;

  /// Tooltip for moving section up
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// Tooltip for moving section down
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// Tooltip for deleting section
  ///
  /// In en, this message translates to:
  /// **'Delete Section'**
  String get deleteSection;

  /// Label for quick chord input field
  ///
  /// In en, this message translates to:
  /// **'Chords (e.g. C | G/B | Am | F)'**
  String get chordsFieldLabel;

  /// Placeholder for chord input field
  ///
  /// In en, this message translates to:
  /// **'Type chord symbols separated by spaces or bars'**
  String get chordsFieldHint;

  /// Tooltip for applying parsed chords
  ///
  /// In en, this message translates to:
  /// **'Apply chords text'**
  String get applyChordsTooltip;

  /// Tooltip for launching structured chord dialog
  ///
  /// In en, this message translates to:
  /// **'Add chord builder'**
  String get addChordBuilderTooltip;

  /// Label for section lyrics input
  ///
  /// In en, this message translates to:
  /// **'Section Lyrics'**
  String get sectionLyricsLabel;

  /// Placeholder for section lyrics
  ///
  /// In en, this message translates to:
  /// **'Enter lyrics line by line...'**
  String get sectionLyricsHint;

  /// Label for rehearsal notes
  ///
  /// In en, this message translates to:
  /// **'Rehearsal Notes (optional)'**
  String get rehearsalNotesLabel;

  /// Placeholder for rehearsal notes
  ///
  /// In en, this message translates to:
  /// **'e.g. Guitar solo starts here...'**
  String get rehearsalNotesHint;

  /// Title and button for chord builder dialog
  ///
  /// In en, this message translates to:
  /// **'Add Chord'**
  String get addChord;

  /// Label for root note dropdown
  ///
  /// In en, this message translates to:
  /// **'Root Note'**
  String get rootNote;

  /// Label for chord quality dropdown
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// Label for slash bass note dropdown
  ///
  /// In en, this message translates to:
  /// **'Bass Note (Slash Chord)'**
  String get bassNote;

  /// Option representing no selection
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneOption;

  /// Label for beats selection chips
  ///
  /// In en, this message translates to:
  /// **'Beats: '**
  String get beatsLabel;

  /// Generic add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Snackbar shown after updating song
  ///
  /// In en, this message translates to:
  /// **'Song \"{title}\" updated successfully'**
  String songUpdatedSuccess(String title);

  /// Snackbar shown after creating song
  ///
  /// In en, this message translates to:
  /// **'Song \"{title}\" created successfully'**
  String songCreatedSuccess(String title);

  /// Snackbar error when saving song
  ///
  /// In en, this message translates to:
  /// **'Failed to save song: {error}'**
  String failedToSaveSong(String error);

  /// Snackbar shown after deleting song
  ///
  /// In en, this message translates to:
  /// **'Song deleted'**
  String get songDeletedSuccess;

  /// Snackbar when non-admin tries to modify repertoire
  ///
  /// In en, this message translates to:
  /// **'Administrator permissions required to create or modify songs.'**
  String get adminRequiredWarning;

  /// Title for setlist detail view
  ///
  /// In en, this message translates to:
  /// **'Setlist'**
  String get setlistTitle;

  /// Label for setlist notes and description
  ///
  /// In en, this message translates to:
  /// **'Description / Notes'**
  String get descriptionNotesField;

  /// Modal title and button to append song to setlist
  ///
  /// In en, this message translates to:
  /// **'Add Song to Setlist'**
  String get addSongToSetlist;

  /// Empty state when trying to add to setlist from empty library
  ///
  /// In en, this message translates to:
  /// **'No songs in repertoire yet. Create or load sample songs.'**
  String get noSongsInRepertoireYet;

  /// State when all existing songs have been added to the setlist
  ///
  /// In en, this message translates to:
  /// **'All songs are already in this setlist.'**
  String get allSongsAlreadyInSetlist;

  /// Empty state for setlist without songs
  ///
  /// In en, this message translates to:
  /// **'This setlist has no songs yet.'**
  String get setlistEmpty;

  /// Hint instructing user how to add songs to setlist
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Song\" below to build your set.'**
  String get tapAddSongHint;

  /// Tooltip for removing song from setlist
  ///
  /// In en, this message translates to:
  /// **'Remove from setlist'**
  String get removeFromSetlistTooltip;

  /// Subtitle format in setlist item
  ///
  /// In en, this message translates to:
  /// **'{artist} • Original: {key} ({tempo} BPM)'**
  String songOriginalMeta(String artist, String key, int tempo);

  /// Fallback text when song artist is unspecified
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// Tooltip for editing setlist metadata
  ///
  /// In en, this message translates to:
  /// **'Edit setlist info'**
  String get editSetlistInfoTooltip;

  /// AppBar title for scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan Lead Sheet'**
  String get scanLeadSheet;

  /// Landing page title for OMR feature
  ///
  /// In en, this message translates to:
  /// **'OMR Scanner'**
  String get omrScannerTitle;

  /// Landing page subtitle explaining OMR capabilities
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a lead sheet or pick an image to extract\nchords, melody, and structure using Gemini AI.'**
  String get omrScannerSubtitle;

  /// Button to launch camera capture
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get openCamera;

  /// Button to launch photo gallery picker
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get chooseFromLibrary;

  /// Snackbar confirming imported score saved to repertoire
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to Repertoire!'**
  String addedToRepertoireSuccess(String title);

  /// Snackbar confirming imported section rhythm
  ///
  /// In en, this message translates to:
  /// **'Extracted {measures} measures for \"{section}\".'**
  String extractedMeasuresSuccess(int measures, String section);

  /// Title for scan flow modal
  ///
  /// In en, this message translates to:
  /// **'Scan Sheet Music'**
  String get scanSheetMusic;

  /// Tooltip for opening OMR log viewer
  ///
  /// In en, this message translates to:
  /// **'OMR Debug Logs'**
  String get omrDebugLogs;

  /// Segmented button label for full lead sheet scan
  ///
  /// In en, this message translates to:
  /// **'Full Sheet (Schema A)'**
  String get fullSheetSchemaA;

  /// Segmented button label for melody staff system snippet
  ///
  /// In en, this message translates to:
  /// **'Staff Snippet (Schema B)'**
  String get staffSnippetSchemaB;

  /// Button label for camera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Button label for photos gallery
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// Explanation text for Schema A full sheet capture
  ///
  /// In en, this message translates to:
  /// **'Captures complete arrangement with metadata, staves, chords, and lyrics.'**
  String get fullSheetDesc;

  /// Explanation text for Schema B snippet capture
  ///
  /// In en, this message translates to:
  /// **'Crops a single system or melody line for rapid tap-first rhythm entry.'**
  String get staffSnippetDesc;

  /// Button to crop staff snippet image
  ///
  /// In en, this message translates to:
  /// **'Crop System'**
  String get cropSystem;

  /// Button to replace selected image
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// Primary action button to trigger OMR recognition
  ///
  /// In en, this message translates to:
  /// **'Analyze with Gemini AI'**
  String get analyzeWithGemini;

  /// Header for recognition failure banner
  ///
  /// In en, this message translates to:
  /// **'Recognition Error'**
  String get recognitionError;

  /// Button to open diagnostic logs modal on error
  ///
  /// In en, this message translates to:
  /// **'View Debug Logs'**
  String get viewDebugLogs;

  /// Banner title for successful OMR extraction
  ///
  /// In en, this message translates to:
  /// **'Recognition Complete!'**
  String get recognitionComplete;

  /// Button to review imported lead sheet in repertoire
  ///
  /// In en, this message translates to:
  /// **'Open in Repertoire'**
  String get openInRepertoire;

  /// Button to review imported snippet in rhythm editor
  ///
  /// In en, this message translates to:
  /// **'Open in Rhythm Editor'**
  String get openInRhythmEditor;

  /// Progress dialog title during Gemini analysis
  ///
  /// In en, this message translates to:
  /// **'Analyzing sheet with Gemini AI...'**
  String get analyzingSheet;

  /// Progress dialog title during local pre-processing
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get processingImage;

  /// Progress dialog subtitle during transcription
  ///
  /// In en, this message translates to:
  /// **'Transcribing notes, chords & staves'**
  String get transcribingSheet;

  /// Title for OMR debug logs modal
  ///
  /// In en, this message translates to:
  /// **'OMR Diagnostic Logs'**
  String get omrDiagnosticLogs;

  /// Subtitle for OMR logs modal
  ///
  /// In en, this message translates to:
  /// **'Persistent File System Logs'**
  String get persistentFileSystemLogs;

  /// Tooltip for refreshing log viewer
  ///
  /// In en, this message translates to:
  /// **'Refresh Logs'**
  String get refreshLogs;

  /// Tooltip for clearing log file
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// Title for clear logs confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear OMR Logs?'**
  String get clearOmrLogsTitle;

  /// Message for clear logs dialog
  ///
  /// In en, this message translates to:
  /// **'This will empty the omr_debug.log file on the device.'**
  String get clearOmrLogsConfirm;

  /// Clear action button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// Snackbar confirming logs cleared
  ///
  /// In en, this message translates to:
  /// **'OMR logs cleared from file system.'**
  String get omrLogsCleared;

  /// Placeholder while log file path is resolved
  ///
  /// In en, this message translates to:
  /// **'Locating log file...'**
  String get locatingLogFile;

  /// Message while logs are reading from disk
  ///
  /// In en, this message translates to:
  /// **'Loading diagnostic logs...'**
  String get loadingDiagnosticLogs;

  /// Empty state message in log viewer
  ///
  /// In en, this message translates to:
  /// **'No logs recorded yet.\nRun an OMR scan to capture diagnostic logs.'**
  String get noLogsRecordedYet;

  /// Button to copy full log file content to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy All Logs'**
  String get copyAllLogs;

  /// Snackbar confirming logs copied
  ///
  /// In en, this message translates to:
  /// **'OMR logs copied to clipboard.'**
  String get omrLogsCopied;

  /// Title for score and notation editor
  ///
  /// In en, this message translates to:
  /// **'Score Editor'**
  String get scoreEditor;

  /// Snackbar confirming notation changes saved
  ///
  /// In en, this message translates to:
  /// **'Notation changes saved to Song!'**
  String get notationSavedSuccess;

  /// Snackbar error when saving score
  ///
  /// In en, this message translates to:
  /// **'Failed to save score: {error}'**
  String failedToSaveScore(String error);

  /// Title for playback tempo dialog
  ///
  /// In en, this message translates to:
  /// **'Playback Tempo'**
  String get playbackTempo;

  /// Button to confirm playback tempo
  ///
  /// In en, this message translates to:
  /// **'Set Tempo'**
  String get setTempo;

  /// Status badge label when preview is idle
  ///
  /// In en, this message translates to:
  /// **'Score Audio Preview'**
  String get scoreAudioPreview;

  /// Tooltip for pausing melody playback
  ///
  /// In en, this message translates to:
  /// **'Pause Melody'**
  String get pauseMelody;

  /// Tooltip for starting melody playback
  ///
  /// In en, this message translates to:
  /// **'Play / Preview Melody'**
  String get playMelody;

  /// Tooltip for stopping playback and rewinding
  ///
  /// In en, this message translates to:
  /// **'Stop & Rewind'**
  String get stopRewind;

  /// Tooltip to unmute tone feedback
  ///
  /// In en, this message translates to:
  /// **'Unmute Note Sound Feedback'**
  String get unmuteSound;

  /// Tooltip to mute tone feedback
  ///
  /// In en, this message translates to:
  /// **'Mute Note Sound Feedback'**
  String get muteSound;

  /// Header for API configuration settings
  ///
  /// In en, this message translates to:
  /// **'API Configuration'**
  String get apiConfigurationSection;

  /// Tile label for Gemini API Key
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key'**
  String get geminiApiKeyLabel;

  /// Subtitle when Gemini key is not configured
  ///
  /// In en, this message translates to:
  /// **'Not configured — tap to enter key'**
  String get geminiKeyNotConfigured;

  /// Tag indicating user custom key
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// Tag indicating build environment key
  ///
  /// In en, this message translates to:
  /// **'Dev .env'**
  String get devEnvLabel;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading status...'**
  String get loadingStatus;

  /// Error indicator text
  ///
  /// In en, this message translates to:
  /// **'Error loading key'**
  String get errorLoadingKey;

  /// Subtitle for OMR logs tile in settings
  ///
  /// In en, this message translates to:
  /// **'Inspect Gemini requests, latencies & responses'**
  String get omrDiagnosticLogsSubtitle;

  /// Application description in about section
  ///
  /// In en, this message translates to:
  /// **'A music rehearsal & lead-sheet companion\nfor worship teams and bands.'**
  String get appTagline;

  /// Licenses tile title
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licensesLabel;

  /// Footer quote at bottom of settings
  ///
  /// In en, this message translates to:
  /// **'Made with ♪ for worship teams'**
  String get footerAttribution;

  /// Subtitle for Supabase connection tile
  ///
  /// In en, this message translates to:
  /// **'Configure Project URL & Anon Key'**
  String get supabaseConfigSubtitle;

  /// Subtitle when user is unauthenticated
  ///
  /// In en, this message translates to:
  /// **'Not signed in — Offline SQLite active'**
  String get notSignedInOffline;

  /// Status text while cloud sync is active
  ///
  /// In en, this message translates to:
  /// **'Synchronizing local Drift database with cloud…'**
  String get synchronizingDatabase;

  /// Status text when device is offline
  ///
  /// In en, this message translates to:
  /// **'Offline: Local changes safely cached'**
  String get offlineCached;

  /// Status text when idle
  ///
  /// In en, this message translates to:
  /// **'Ready to sync'**
  String get readyToSync;

  /// Workspace metrics line for scans
  ///
  /// In en, this message translates to:
  /// **'{count} full lead-sheet scans this billing period'**
  String billingPeriodScans(int count);

  /// Workspace metrics line for storage
  ///
  /// In en, this message translates to:
  /// **'{count} scores and audio tracks stored'**
  String storageTracksCount(int count);

  /// Error banner when workspace metrics cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Workspace metrics unavailable'**
  String get workspaceMetricsUnavailable;

  /// AppBar title for team roster and calendar
  ///
  /// In en, this message translates to:
  /// **'Worship Team & Band'**
  String get worshipTeamTitle;

  /// AppBar title for live sync page
  ///
  /// In en, this message translates to:
  /// **'Live Stage Sync'**
  String get liveStageSync;

  /// Segment label for director live mode
  ///
  /// In en, this message translates to:
  /// **'Director (Host)'**
  String get directorHost;

  /// Segment label for musician live mode
  ///
  /// In en, this message translates to:
  /// **'Musician (Follower)'**
  String get musicianFollower;

  /// Connection badge for live director host
  ///
  /// In en, this message translates to:
  /// **'HOSTING'**
  String get hostingStatus;

  /// Connection badge for synced live follower
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
  String get syncedStatus;

  /// Connection badge when live sync is disconnected
  ///
  /// In en, this message translates to:
  /// **'STANDALONE'**
  String get standaloneStatus;

  /// Tooltip while syncing with Supabase
  ///
  /// In en, this message translates to:
  /// **'Syncing changes with Supabase…'**
  String get syncingChangesTooltip;

  /// Tooltip when synced with Supabase
  ///
  /// In en, this message translates to:
  /// **'Cloud synced'**
  String get cloudSyncedTooltip;

  /// Tooltip when synced with Supabase with time
  ///
  /// In en, this message translates to:
  /// **'Cloud synced ({time})'**
  String cloudSyncedWithTimeTooltip(String time);

  /// Tooltip when offline
  ///
  /// In en, this message translates to:
  /// **'Offline — working with local SQLite database'**
  String get offlineSQLiteTooltip;

  /// Tooltip when sync encountered error
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncErrorTooltip;

  /// Tooltip when cloud sync is idle
  ///
  /// In en, this message translates to:
  /// **'Cloud ready (tap to sync)'**
  String get cloudReadyTooltip;

  /// Syncing status text
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncingStatus;

  /// Synced status text
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedStatusLabel;

  /// Offline status text
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatusLabel;

  /// Tooltip for active user switcher
  ///
  /// In en, this message translates to:
  /// **'Switch active user profile'**
  String get switchActiveProfileTooltip;

  /// Tooltip for active profile badge
  ///
  /// In en, this message translates to:
  /// **'Active Profile: {name} ({role})'**
  String activeProfileTooltip(String name, String role);

  /// Tooltip for musician coverage alerts bell
  ///
  /// In en, this message translates to:
  /// **'Musician Coverage Alerts'**
  String get coverageAlertsTooltip;

  /// Tooltip for musician coverage alerts count
  ///
  /// In en, this message translates to:
  /// **'{count} cover alert(s)'**
  String coverageAlertsCountTooltip(int count);

  /// Tooltip to add a team member
  ///
  /// In en, this message translates to:
  /// **'Add team member'**
  String get addTeamMemberTooltip;

  /// Tooltip to add a service event
  ///
  /// In en, this message translates to:
  /// **'Add service event'**
  String get addServiceEventTooltip;

  /// Empty state text for upcoming services
  ///
  /// In en, this message translates to:
  /// **'No upcoming services scheduled.'**
  String get noUpcomingServices;

  /// Button to schedule the first service
  ///
  /// In en, this message translates to:
  /// **'Schedule First Service'**
  String get scheduleFirstService;

  /// Action to edit team member
  ///
  /// In en, this message translates to:
  /// **'Edit Member'**
  String get editMember;

  /// Action to schedule member for a service
  ///
  /// In en, this message translates to:
  /// **'Schedule for Service'**
  String get scheduleForService;

  /// Action to edit service
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// Action to assign group to service
  ///
  /// In en, this message translates to:
  /// **'Assign Group'**
  String get assignGroup;

  /// Action to assign musician to service
  ///
  /// In en, this message translates to:
  /// **'Assign Musician'**
  String get assignMusician;

  /// Button to trigger test stage cue
  ///
  /// In en, this message translates to:
  /// **'Trigger Test Cue'**
  String get triggerTestCue;

  /// Button to approve section jump in live sync
  ///
  /// In en, this message translates to:
  /// **'Approve Jump'**
  String get approveJump;

  /// Notification when Gemini API key is saved
  ///
  /// In en, this message translates to:
  /// **'Gemini API key saved securely.'**
  String get geminiApiKeySaved;

  /// Confirmation title for removing API key
  ///
  /// In en, this message translates to:
  /// **'Remove API Key?'**
  String get removeApiKeyTitle;

  /// Notification when custom API key is removed
  ///
  /// In en, this message translates to:
  /// **'Custom API key removed.'**
  String get customApiKeyRemoved;

  /// Button to remove API key
  ///
  /// In en, this message translates to:
  /// **'Remove Key'**
  String get removeKey;

  /// Button to save API key
  ///
  /// In en, this message translates to:
  /// **'Save Key'**
  String get saveKey;

  /// Title for Supabase setup dialog
  ///
  /// In en, this message translates to:
  /// **'Supabase Project Setup'**
  String get supabaseProjectSetup;

  /// Button to restore default settings
  ///
  /// In en, this message translates to:
  /// **'Restore Default'**
  String get restoreDefault;

  /// Button to save Supabase settings and connect
  ///
  /// In en, this message translates to:
  /// **'Save & Connect'**
  String get saveAndConnect;

  /// Title for modal to select active profile
  ///
  /// In en, this message translates to:
  /// **'Select Active User Profile'**
  String get selectActiveProfileTitle;

  /// Explanation for active user switcher
  ///
  /// In en, this message translates to:
  /// **'Switch active user to preview musician permissions vs administrator capabilities.'**
  String get switchActiveProfileDesc;

  /// Badge label for admin role
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// Full title for administrator
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// Full title for musician
  ///
  /// In en, this message translates to:
  /// **'Musician'**
  String get musician;

  /// Snackbar text when active profile changes
  ///
  /// In en, this message translates to:
  /// **'Active user: {name} ({role})'**
  String activeUserChanged(String name, String role);

  /// Summary label for total roster count
  ///
  /// In en, this message translates to:
  /// **'Total Roster'**
  String get totalRoster;

  /// Summary label for scheduled count
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledLabel;

  /// Summary label for available count
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// Status text for member availability
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableStatus;

  /// Prefix for next service date
  ///
  /// In en, this message translates to:
  /// **'Next:'**
  String get nextServicePrefix;

  /// Filter chip for all members
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter chip for scheduled members
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get filterScheduled;

  /// Filter chip for vocal members
  ///
  /// In en, this message translates to:
  /// **'Vocals'**
  String get filterVocals;

  /// Filter chip for instrumental band members
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get filterBand;

  /// Empty state text when filter matches 0 members
  ///
  /// In en, this message translates to:
  /// **'No team members match this filter.'**
  String get noMembersMatchFilter;

  /// Badge highlighting the next upcoming service
  ///
  /// In en, this message translates to:
  /// **'NEXT SERVICE'**
  String get nextServiceBadge;

  /// Title for band lineup section in service card
  ///
  /// In en, this message translates to:
  /// **'Band Lineup'**
  String get bandLineupTitle;

  /// Badge text for declined member assignment
  ///
  /// In en, this message translates to:
  /// **'Can\'\'t attend'**
  String get cantAttendBadge;

  /// Subtitle when member is not in any lineup
  ///
  /// In en, this message translates to:
  /// **'Not currently scheduled for upcoming services'**
  String get notScheduledForServices;

  /// Snackbar when cloud sync succeeds
  ///
  /// In en, this message translates to:
  /// **'Cloud synced successfully ({pushed} pushed, {pulled} pulled)'**
  String cloudSyncSuccess(int pushed, int pulled);

  /// Title for cloud sync bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Cloud Synchronization'**
  String get cloudSyncStatusTitle;

  /// Message when cloud sync requires sign in
  ///
  /// In en, this message translates to:
  /// **'Please sign in to Supabase to enable cloud sync.'**
  String get cloudSignInRequired;

  /// Message when sync is in offline mode
  ///
  /// In en, this message translates to:
  /// **'Offline mode active. All changes are saved safely to local SQLite.'**
  String get cloudOfflineMode;

  /// Button to open sign-in dialog
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInAction;

  /// Button to configure Supabase credentials
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configureAction;

  /// Button to retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// Empty state text in band lineup
  ///
  /// In en, this message translates to:
  /// **'No musicians assigned yet. Tap \"Assign Musician\" to schedule band members.'**
  String get noMusiciansAssignedYet;

  /// Action to delete a service
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// Message when Supabase client is not configured
  ///
  /// In en, this message translates to:
  /// **'Supabase client is not configured. Local changes cached.'**
  String get supabaseNotConfigured;

  /// Label for currently active stage section
  ///
  /// In en, this message translates to:
  /// **'ON STAGE NOW'**
  String get onStageNow;

  /// Default active section when none is cued
  ///
  /// In en, this message translates to:
  /// **'INTRO / PRE-ROLL'**
  String get introPreRoll;

  /// Label for upcoming queued section
  ///
  /// In en, this message translates to:
  /// **'Queued Next:'**
  String get queuedNext;

  /// Placeholder when no section is queued
  ///
  /// In en, this message translates to:
  /// **'None (Waiting for cue)'**
  String get waitingForCue;

  /// Header for director server card
  ///
  /// In en, this message translates to:
  /// **'LOCAL LAN DIRECTOR SERVER'**
  String get localLanDirectorServer;

  /// Header for follower connection card
  ///
  /// In en, this message translates to:
  /// **'CONNECT TO DIRECTOR DEVICE'**
  String get connectToDirectorDevice;

  /// Instruction for starting director server
  ///
  /// In en, this message translates to:
  /// **'Start a zero-configuration local WebSocket server so all band members follow your live cues.'**
  String get startZeroConfigServer;

  /// Status message when director server is active
  ///
  /// In en, this message translates to:
  /// **'Server running on ephemeral port {port}. Band member tablets can connect on this local Wi-Fi.'**
  String serverRunningOnPort(int port);

  /// Button to stop director server
  ///
  /// In en, this message translates to:
  /// **'Stop Host Server'**
  String get stopHostServer;

  /// Button to start director server
  ///
  /// In en, this message translates to:
  /// **'Start LAN Host'**
  String get startLanHost;

  /// Input label for director IP address
  ///
  /// In en, this message translates to:
  /// **'Director Host IP'**
  String get directorHostIp;

  /// Input label for port number
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// Button to disconnect from live session
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Button to connect as live session follower
  ///
  /// In en, this message translates to:
  /// **'Connect as Follower'**
  String get connectAsFollower;

  /// Snackbar message when live connection fails
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailed(String error);

  /// Header for incoming follower override requests
  ///
  /// In en, this message translates to:
  /// **'LeaderLock: Musician Transition Requests'**
  String get leaderLockRequestsTitle;

  /// Subtitle for follower transition request
  ///
  /// In en, this message translates to:
  /// **'Follower requested section change'**
  String get followerRequestedChange;

  /// Title for follower request item
  ///
  /// In en, this message translates to:
  /// **'Request: {section}'**
  String requestPrefix(String section);

  /// Button to immediately jump to section
  ///
  /// In en, this message translates to:
  /// **'JUMP'**
  String get jumpAction;

  /// Button to clear queued live section
  ///
  /// In en, this message translates to:
  /// **'CLEAR QUEUE'**
  String get clearQueueAction;

  /// Explanation text in Supabase config dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your Supabase project endpoint and anon public key to enable cloud sync.'**
  String get supabaseConfigExplanation;

  /// Field label for Supabase URL
  ///
  /// In en, this message translates to:
  /// **'Project URL'**
  String get projectUrlLabel;

  /// Field label for Supabase anon key
  ///
  /// In en, this message translates to:
  /// **'Anon Public Key'**
  String get anonPublicKeyLabel;

  /// Title for magic link sign in dialog
  ///
  /// In en, this message translates to:
  /// **'Magic Link Sign In'**
  String get magicLinkSignInTitle;

  /// Title for account creation dialog
  ///
  /// In en, this message translates to:
  /// **'Create Supabase Account'**
  String get createAccountTitle;

  /// Title for sign in dialog
  ///
  /// In en, this message translates to:
  /// **'Sign In to Supabase'**
  String get signInTitle;

  /// Field label for full name
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// Field label for email
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// Field label for password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Toggle to use password authentication
  ///
  /// In en, this message translates to:
  /// **'Use Password'**
  String get usePasswordAction;

  /// Toggle to send magic link
  ///
  /// In en, this message translates to:
  /// **'Send Magic Link'**
  String get sendMagicLinkAction;

  /// Toggle for existing users to sign in
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign In'**
  String get haveAccountSignInAction;

  /// Toggle for new users to register
  ///
  /// In en, this message translates to:
  /// **'New? Register'**
  String get newRegisterAction;

  /// Button to send login link
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendLinkAction;

  /// Button to submit registration
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// Title for admin scheduling gaps banner
  ///
  /// In en, this message translates to:
  /// **'Scheduling Attention Needed ({count})'**
  String schedulingAttentionNeeded(int count);

  /// Button to dismiss alert
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissAction;

  /// Title for coverage alerts modal
  ///
  /// In en, this message translates to:
  /// **'Coverage Alerts ({count})'**
  String coverageAlertsCount(int count);

  /// Empty state for coverage alerts
  ///
  /// In en, this message translates to:
  /// **'No pending scheduling gaps. All services are covered!'**
  String get noPendingGaps;

  /// Dialog title for replacing musician
  ///
  /// In en, this message translates to:
  /// **'Assign Musician Replacement'**
  String get assignMusicianReplacement;

  /// Label indicating which member cannot attend
  ///
  /// In en, this message translates to:
  /// **'Cannot Attend: {name}'**
  String cannotAttendPrefix(String name);

  /// Role and date information line
  ///
  /// In en, this message translates to:
  /// **'Role: {role} • {date}'**
  String roleDatePrefix(String role, String date);

  /// Dropdown label for substitute musician
  ///
  /// In en, this message translates to:
  /// **'Select Substitute Musician:'**
  String get selectSubstituteMusician;

  /// Field label for substitute musician
  ///
  /// In en, this message translates to:
  /// **'Substitute Musician'**
  String get substituteMusicianLabel;

  /// Tag indicating substitute plays the requested role
  ///
  /// In en, this message translates to:
  /// **'★ Plays {role}'**
  String playsRoleTag(String role);

  /// Tag indicating member is already scheduled
  ///
  /// In en, this message translates to:
  /// **'(In Lineup)'**
  String get inLineupTag;

  /// Field label for assigned role
  ///
  /// In en, this message translates to:
  /// **'Assigned Role'**
  String get assignedRoleLabel;

  /// Field label for attendance status
  ///
  /// In en, this message translates to:
  /// **'Attendance Status'**
  String get attendanceStatusLabel;

  /// Button to confirm replacement
  ///
  /// In en, this message translates to:
  /// **'Confirm Replacement'**
  String get confirmReplacement;

  /// Snackbar confirming musician replacement
  ///
  /// In en, this message translates to:
  /// **'Replaced {oldMember} with {newMember} for {date}!'**
  String replacedMusicianSuccess(
    String oldMember,
    String newMember,
    String date,
  );

  /// Snackbar when no substitute is available
  ///
  /// In en, this message translates to:
  /// **'No other team members available to substitute.'**
  String get noOtherMembersToSubstitute;

  /// Action to confirm attendance
  ///
  /// In en, this message translates to:
  /// **'Confirm Attendance'**
  String get confirmAttendance;

  /// Action to mark unavailable
  ///
  /// In en, this message translates to:
  /// **'Mark Unavailable / Cannot Attend'**
  String get markUnavailableCannotAttend;

  /// Subtitle explaining decline action
  ///
  /// In en, this message translates to:
  /// **'Flags date so admin can set a replacement'**
  String get flagsDateReplacement;

  /// Action to find replacement
  ///
  /// In en, this message translates to:
  /// **'Find Replacement / Substitute'**
  String get findReplacementSubstitute;

  /// Subtitle explaining find replacement
  ///
  /// In en, this message translates to:
  /// **'Assign another team member to take this spot'**
  String get assignAnotherMember;

  /// Action to remove member from lineup
  ///
  /// In en, this message translates to:
  /// **'Remove from Lineup'**
  String get removeFromLineup;

  /// Dialog title for assigning musician
  ///
  /// In en, this message translates to:
  /// **'Assign Musician to {date}'**
  String assignMusicianToDate(String date);

  /// Field label for band member
  ///
  /// In en, this message translates to:
  /// **'Band Member'**
  String get bandMemberLabel;

  /// Field label for role in service
  ///
  /// In en, this message translates to:
  /// **'Assigned Role for Service'**
  String get assignedRoleForService;

  /// Button to assign musician to lineup
  ///
  /// In en, this message translates to:
  /// **'Assign to Lineup'**
  String get assignToLineupAction;

  /// Empty state for arrangement groups
  ///
  /// In en, this message translates to:
  /// **'No arrangement groups created yet.'**
  String get noArrangementGroupsYet;

  /// Dialog title for assigning group
  ///
  /// In en, this message translates to:
  /// **'Assign Group to Service'**
  String get assignGroupToService;

  /// Button to add recurring schedule rule
  ///
  /// In en, this message translates to:
  /// **'Add Repetitive Schedule Rule'**
  String get addRepetitiveScheduleRule;

  /// Label for lookahead count
  ///
  /// In en, this message translates to:
  /// **'{count} ahead'**
  String aheadCount(int count);

  /// Field label for full name required
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullNameRequired;

  /// Label for roles and instruments section
  ///
  /// In en, this message translates to:
  /// **'Roles & Instruments *'**
  String get rolesInstrumentsRequired;

  /// Badge showing how many roles are selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String rolesSelectedCount(int count);

  /// Hint text for role selection
  ///
  /// In en, this message translates to:
  /// **'Select at least one role (musicians can hold multiple roles)'**
  String get selectAtLeastOneRole;

  /// Field label for vocal tessitura
  ///
  /// In en, this message translates to:
  /// **'Vocal Tessitura (Range)'**
  String get vocalTessituraRange;

  /// Field label for general availability
  ///
  /// In en, this message translates to:
  /// **'General Availability'**
  String get generalAvailabilityLabel;

  /// Field label for notes or assignment details
  ///
  /// In en, this message translates to:
  /// **'Notes / Assignment'**
  String get notesAssignmentLabel;

  /// Field label for service title required
  ///
  /// In en, this message translates to:
  /// **'Service Title *'**
  String get serviceTitleRequired;

  /// Field label for service type
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceTypeLabel;

  /// Field label for recurrence schedule
  ///
  /// In en, this message translates to:
  /// **'Recurrence Schedule'**
  String get recurrenceScheduleLabel;

  /// Field label for number of occurrences to generate
  ///
  /// In en, this message translates to:
  /// **'Occurrences to Generate'**
  String get occurrencesToGenerate;

  /// Field label for location or venue
  ///
  /// In en, this message translates to:
  /// **'Location / Venue'**
  String get locationVenueLabel;

  /// Field label for call time and instructions
  ///
  /// In en, this message translates to:
  /// **'Call Time & Instructions'**
  String get callTimeInstructionsLabel;

  /// Option for single service date
  ///
  /// In en, this message translates to:
  /// **'1 service (Single date only)'**
  String get singleDateOnly;

  /// Option for recurring series generation
  ///
  /// In en, this message translates to:
  /// **'{count} services ({weeks} weeks ahead)'**
  String seriesCountServices(int count, int weeks);

  /// Alert reason when member declined
  ///
  /// In en, this message translates to:
  /// **'Can\'\'t attend — missing cover for {role}'**
  String cantAttendCoverNeeded(String role);

  /// Alert reason when member is unavailable
  ///
  /// In en, this message translates to:
  /// **'General status is Unavailable — may need substitute'**
  String get statusUnavailableNeedsSub;

  /// User friendly message when Gemini network connection fails
  ///
  /// In en, this message translates to:
  /// **'Network error: Unable to connect to Gemini AI. Please check your internet connection.'**
  String get networkErrorNoInternet;

  /// User friendly message when Gemini analysis times out
  ///
  /// In en, this message translates to:
  /// **'The AI analysis request timed out. Please check your internet connection or try again.'**
  String get omrTimeoutError;

  /// User friendly message when Gemini API key is missing
  ///
  /// In en, this message translates to:
  /// **'Gemini API key is not configured. Please configure your key in Settings.'**
  String get geminiApiKeyNotConfigured;

  /// User friendly message when Gemini response cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'Could not transcribe the sheet music. Please ensure the image is clear and try again.'**
  String get omrParseError;

  /// Extracted score title prefix
  ///
  /// In en, this message translates to:
  /// **'Title: {title}'**
  String scanTitlePrefix(String title);

  /// Extracted score sections count
  ///
  /// In en, this message translates to:
  /// **'Sections: {count}'**
  String scanSectionsCount(int count);

  /// Extracted pitch section name
  ///
  /// In en, this message translates to:
  /// **'Section: {name}'**
  String scanSectionName(String name);

  /// Extracted pitch measures count
  ///
  /// In en, this message translates to:
  /// **'Measures: {count}'**
  String scanMeasuresCount(int count);

  /// Action to remove member from roster
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// Tooltip for member options popup
  ///
  /// In en, this message translates to:
  /// **'Member options'**
  String get memberOptionsTooltip;

  /// Badge showing non-admin musician view
  ///
  /// In en, this message translates to:
  /// **'Musician View'**
  String get musicianViewLabel;

  /// Button to replace a member in lineup
  ///
  /// In en, this message translates to:
  /// **'Replace {name}'**
  String replaceMemberAction(String name);

  /// Label for lookahead dropdown
  ///
  /// In en, this message translates to:
  /// **'Show: '**
  String get showLabel;

  /// Title for recurring series management modal
  ///
  /// In en, this message translates to:
  /// **'Recurring Service Schedules'**
  String get recurringServiceSchedules;

  /// Subtitle explaining recurring schedules
  ///
  /// In en, this message translates to:
  /// **'Each repetitive event is a single recurring instance. Adjust the rolling lookahead (X events ahead), or set a cutoff date to stop generating new events.'**
  String get recurringSchedulesSubtitle;

  /// Empty state for recurring schedules
  ///
  /// In en, this message translates to:
  /// **'No recurring schedules configured yet.'**
  String get noRecurringSchedulesYet;

  /// Notice banner when schedule is paused
  ///
  /// In en, this message translates to:
  /// **'Schedule Paused — no occurrences generated'**
  String get schedulePausedNotice;

  /// Button to set a cutoff date for a recurring schedule
  ///
  /// In en, this message translates to:
  /// **'Disable Since Date...'**
  String get disableSinceDate;

  /// Chip label showing disabled date
  ///
  /// In en, this message translates to:
  /// **'Disabled from {date}'**
  String disabledFromDate(String date);

  /// Snackbar confirming member updated
  ///
  /// In en, this message translates to:
  /// **'Updated {name}'**
  String updatedMemberSuccess(String name);

  /// Snackbar confirming member added
  ///
  /// In en, this message translates to:
  /// **'Added {name} to the team!'**
  String addedMemberSuccess(String name);

  /// Snackbar confirming service updated
  ///
  /// In en, this message translates to:
  /// **'Updated {title}'**
  String updatedServiceSuccess(String title);

  /// Snackbar confirming service scheduled
  ///
  /// In en, this message translates to:
  /// **'Scheduled {title}!'**
  String scheduledServiceSuccess(String title);

  /// Snackbar confirming recurring schedule configured
  ///
  /// In en, this message translates to:
  /// **'Configured recurring schedule for {title} (showing next {count} events)!'**
  String recurringScheduleSuccess(String title, int count);

  /// Snackbar confirming musician assigned
  ///
  /// In en, this message translates to:
  /// **'Assigned {name} to {title}!'**
  String assignedMusicianSuccess(String name, String title);

  /// Snackbar confirming group assigned
  ///
  /// In en, this message translates to:
  /// **'Assigned {group} ({count} members) to {date}!'**
  String assignedGroupSuccess(String group, int count, String date);

  /// Dialog title for editing a team member
  ///
  /// In en, this message translates to:
  /// **'Edit Team Member'**
  String get editTeamMember;

  /// Dialog title for adding a team member
  ///
  /// In en, this message translates to:
  /// **'Add Team Member'**
  String get addTeamMember;

  /// Helper text for selecting roles
  ///
  /// In en, this message translates to:
  /// **'Tap to toggle roles (e.g. Pianist + Singer + Guitarist):'**
  String get tapToToggleRoles;

  /// Title when vocal range is discarded
  ///
  /// In en, this message translates to:
  /// **'Vocal Tessitura: Discarded (Instrumental)'**
  String get vocalTessituraDiscardedTitle;

  /// Subtitle when vocal range is discarded
  ///
  /// In en, this message translates to:
  /// **'Automatically omitted because only instruments or production roles are selected.'**
  String get vocalTessituraDiscardedSubtitle;

  /// Section title for arrangement groups
  ///
  /// In en, this message translates to:
  /// **'Arrangement Groups / Sub-teams'**
  String get arrangementGroupsSubteams;

  /// Badge showing number of groups assigned
  ///
  /// In en, this message translates to:
  /// **'{count} assigned'**
  String groupsAssignedCount(int count);

  /// Helper text for groups
  ///
  /// In en, this message translates to:
  /// **'Member can belong to multiple rotating teams:'**
  String get memberRotatingTeamsSubtitle;

  /// Switch title for administrator role
  ///
  /// In en, this message translates to:
  /// **'Administrator Role'**
  String get administratorRole;

  /// Subtitle explaining administrator role
  ///
  /// In en, this message translates to:
  /// **'Grants authority to create songs, schedule services, and assign musician replacements.'**
  String get administratorRoleSubtitle;

  /// Button to save form changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Button to add a member
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberAction;

  /// Dialog title for editing a service
  ///
  /// In en, this message translates to:
  /// **'Edit Service Event'**
  String get editServiceEvent;

  /// Dialog title for adding a service
  ///
  /// In en, this message translates to:
  /// **'Add Service / Rehearsal'**
  String get addServiceRehearsal;

  /// Badge showing member count of group
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupMembersCount(int count);

  /// Subtitle showing unavailable count
  ///
  /// In en, this message translates to:
  /// **'{count} unavailable'**
  String unavailableCountSubtitle(int count);

  /// Dialog title to attach reference audio
  ///
  /// In en, this message translates to:
  /// **'Attach Reference Audio'**
  String get attachReferenceAudio;

  /// Instructions for attaching reference audio
  ///
  /// In en, this message translates to:
  /// **'Select an audio file or paste a rehearsal reference link (MP3, WAV, M4A):'**
  String get attachAudioInstructions;

  /// Input label for audio track source
  ///
  /// In en, this message translates to:
  /// **'Audio Track Source'**
  String get audioTrackSource;

  /// Button to attach audio track
  ///
  /// In en, this message translates to:
  /// **'Attach Track'**
  String get attachTrackAction;

  /// Practice reference default title suffix
  ///
  /// In en, this message translates to:
  /// **'Practice Reference'**
  String get practiceReference;

  /// Tooltip for metronome button
  ///
  /// In en, this message translates to:
  /// **'Metronome Click ({tempo} BPM)'**
  String metronomeClickTooltip(int tempo);

  /// Tooltip for attaching audio track
  ///
  /// In en, this message translates to:
  /// **'Attach Audio Track'**
  String get attachAudioTrackTooltip;

  /// Badge text when looping a section
  ///
  /// In en, this message translates to:
  /// **'Looping: {section}'**
  String loopingPrefix(String section);

  /// Tooltip for playback speed menu
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeedTooltip;

  /// Label for playback speed menu items
  ///
  /// In en, this message translates to:
  /// **'{speed}× Speed'**
  String speedLabel(double speed);

  /// Tooltip for rewind button
  ///
  /// In en, this message translates to:
  /// **'Rewind {seconds} seconds'**
  String rewindSecondsTooltip(int seconds);

  /// Tooltip for forward button
  ///
  /// In en, this message translates to:
  /// **'Forward {seconds} seconds'**
  String forwardSecondsTooltip(int seconds);

  /// Tooltip for pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseAction;

  /// Tooltip for play button
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playAction;

  /// Tooltip for looping section button
  ///
  /// In en, this message translates to:
  /// **'Loop Section'**
  String get loopSectionTooltip;

  /// Option for no looping
  ///
  /// In en, this message translates to:
  /// **'No Loop (Full Song)'**
  String get noLoopFullSong;

  /// Menu item to loop a specific section
  ///
  /// In en, this message translates to:
  /// **'Loop: {section}'**
  String loopSectionItem(String section);

  /// Button to create a single service
  ///
  /// In en, this message translates to:
  /// **'Create Service'**
  String get createService;

  /// Button to create a series of services
  ///
  /// In en, this message translates to:
  /// **'Create Series ({count})'**
  String createSeriesCount(int count);

  /// View mode segment for lyrics with chords over words
  ///
  /// In en, this message translates to:
  /// **'Lyrics & Chords'**
  String get lyricsAndChords;

  /// Button to open karaoke chord alignment editor
  ///
  /// In en, this message translates to:
  /// **'Align Chords'**
  String get alignChordsAction;

  /// Title for karaoke chord alignment modal
  ///
  /// In en, this message translates to:
  /// **'Karaoke Chord Alignment'**
  String get karaokeAlignTitle;

  /// Instructions for karaoke chord alignment
  ///
  /// In en, this message translates to:
  /// **'Tap a chord, then tap the target word where it enters.'**
  String get karaokeAlignSubtitle;

  /// Visual word-tap alignment tab
  ///
  /// In en, this message translates to:
  /// **'Visual Tap / Karaoke'**
  String get visualTapMode;

  /// ChordPro text editor tab
  ///
  /// In en, this message translates to:
  /// **'ChordPro Text'**
  String get chordProTextMode;

  /// Label for available chords palette
  ///
  /// In en, this message translates to:
  /// **'Chord Palette'**
  String get chordPalette;

  /// Button to add a custom chord to the palette
  ///
  /// In en, this message translates to:
  /// **'Add Chord'**
  String get addChordLabel;

  /// Tool to remove chords from words
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraserMode;

  /// Button to automatically space chords evenly across words
  ///
  /// In en, this message translates to:
  /// **'Auto Distribute'**
  String get autoAlignAction;

  /// Button to remove all chords from lyrics
  ///
  /// In en, this message translates to:
  /// **'Clear Chords'**
  String get clearChordsAction;

  /// Button to start live karaoke cueing
  ///
  /// In en, this message translates to:
  /// **'Live Cue'**
  String get liveCueMode;

  /// Button to stop live karaoke cueing
  ///
  /// In en, this message translates to:
  /// **'Stop Cue'**
  String get stopCueMode;

  /// Instructions for ChordPro text editor
  ///
  /// In en, this message translates to:
  /// **'Edit ChordPro notation directly. Enclose chords in brackets before words: [G]Amazing [C]grace'**
  String get chordProEditorInstructions;

  /// Placeholder when section has no lyrics
  ///
  /// In en, this message translates to:
  /// **'No lyrics or chord alignment for this section yet.'**
  String get noLyricsForSection;

  /// Tooltip for duplicate section action
  ///
  /// In en, this message translates to:
  /// **'Duplicate section'**
  String get duplicateSection;

  /// Snackbar notice when section is duplicated
  ///
  /// In en, this message translates to:
  /// **'Duplicated {name}'**
  String sectionDuplicatedNotice(String name);

  /// Snackbar notice when chords and lyrics are pre-loaded from an earlier section with the same name
  ///
  /// In en, this message translates to:
  /// **'Pre-loaded chords and lyrics from previous {name}'**
  String sectionPreloadedNotice(String name);

  /// Chip or button to pre-load chords/lyrics from earlier section of same name
  ///
  /// In en, this message translates to:
  /// **'Pre-load from previous {name}'**
  String preloadFromPrevious(String name);

  /// Action to copy chords and lyrics from another section
  ///
  /// In en, this message translates to:
  /// **'Copy from another section...'**
  String get copyFromExistingSection;

  /// Dialog title for copying section content
  ///
  /// In en, this message translates to:
  /// **'Copy Content'**
  String get copySectionContent;
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
