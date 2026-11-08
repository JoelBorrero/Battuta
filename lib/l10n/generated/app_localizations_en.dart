// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Battuta';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get navRepertoire => 'Repertoire';

  @override
  String get navScan => 'Scan';

  @override
  String get navSetlists => 'Setlists';

  @override
  String get navTeam => 'Team';

  @override
  String get navLive => 'Live';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSubtitle => 'Choose light, dark, or system mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageSection => 'Language / Idioma';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSubtitle => 'Select your preferred application language';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get cloudSyncSection => 'Cloud Synchronization (Supabase)';

  @override
  String get cloudAccountLabel => 'Cloud Account';

  @override
  String get supabaseConnectionLabel => 'Supabase Connection';

  @override
  String get syncStatusLabel => 'Sync Status';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get signOut => 'Sign Out';

  @override
  String get aboutSection => 'About';

  @override
  String get versionLabel => 'Version';

  @override
  String get teamRosterTab => 'Team Roster';

  @override
  String get bandCalendarTab => 'Band Calendar';

  @override
  String get addMusician => 'Add Member';

  @override
  String get addService => 'New Service';

  @override
  String get recurringSchedules => 'Recurring Schedules';

  @override
  String get periodicServicesTitle => 'Periodic & Upcoming Services';

  @override
  String get nextService => 'NEXT SERVICE';

  @override
  String get findCover => 'Find Cover';

  @override
  String get workspaceResourcesSection => 'Workspace Resources & Quota';

  @override
  String get activeWorkspacePool => 'ACTIVE WORKSPACE POOL';

  @override
  String get geminiAiCredits => 'Gemini AI Credits';

  @override
  String get cloudStorage => 'Cloud Storage';

  @override
  String get developerOptions => 'Developer & Custom Endpoints';

  @override
  String get developerOptionsSubtitle =>
      'Configure custom Supabase URL and local AI keys';

  @override
  String get repertoireTitle => 'Repertoire';

  @override
  String get chordChart => 'Chord Chart';

  @override
  String get musicalStaff => 'Musical Staff';

  @override
  String get newSong => 'New Song';

  @override
  String get editSong => 'Edit Song';

  @override
  String get addSong => 'Add Song';

  @override
  String get deleteSong => 'Delete Song';

  @override
  String get deleteSongTitle => 'Delete Song?';

  @override
  String deleteSongConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String deletedSongSuccess(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get newSetlist => 'New Setlist';

  @override
  String get createSetlist => 'Create Setlist';

  @override
  String get createNewSetlist => 'Create New Setlist';

  @override
  String get editSetlist => 'Edit Setlist';

  @override
  String get deleteSetlistTitle => 'Delete Setlist?';

  @override
  String deleteSetlistConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String deletedSetlistSuccess(String title) {
    return 'Deleted setlist \"$title\"';
  }

  @override
  String createdSetlistSuccess(String title) {
    return 'Created setlist \"$title\"';
  }

  @override
  String songsTab(int count) {
    return 'Songs ($count)';
  }

  @override
  String setlistsTab(int count) {
    return 'Setlists ($count)';
  }

  @override
  String get scanSheetMusicTooltip => 'Scan sheet music';

  @override
  String get searchSongsTooltip => 'Search songs';

  @override
  String get typeToSearchSongs => 'Type to search songs…';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get failedToLoadRepertoire => 'Failed to load repertoire';

  @override
  String get retry => 'Retry';

  @override
  String get repertoireEmpty => 'Your repertoire is empty';

  @override
  String get repertoireEmptyAdminHint =>
      'Tap the + button to add your first song';

  @override
  String get repertoireEmptyMemberHint =>
      'No songs available yet. Contact an administrator to add songs.';

  @override
  String get loadSampleSongs => 'Load Sample Songs';

  @override
  String get scanScore => 'Scan Score';

  @override
  String get noSetlistsYet => 'No Setlists Yet';

  @override
  String get setlistsEmptyAdminHint =>
      'Create an ordered setlist for Sunday services or rehearsals.';

  @override
  String get setlistsEmptyMemberHint =>
      'No setlists created yet. Setlists will appear here once published by your director.';

  @override
  String get loadSampleSetlist => 'Load Sample Setlist';

  @override
  String setlistSongsCount(int count) {
    return '$count songs';
  }

  @override
  String get upcomingService => 'Upcoming service';

  @override
  String get setlistTitleField => 'Setlist Title *';

  @override
  String get setlistTitleHint => 'e.g. Sunday Morning - Easter';

  @override
  String get notesServiceThemeField => 'Notes / Service Theme';

  @override
  String get notesServiceThemeHint =>
      'e.g. Acoustic setup, communion song in D';

  @override
  String get deleteSetlistTooltip => 'Delete setlist';

  @override
  String get songDetail => 'Song Detail';

  @override
  String get transposeSong => 'Transpose Song';

  @override
  String get reset => 'Reset';

  @override
  String get originalKey => 'Original Key';

  @override
  String semitonesCount(String prefix, int count) {
    return '$prefix$count semitones';
  }

  @override
  String get downOneSemitone => 'Down 1 semitone';

  @override
  String get upOneSemitone => 'Up 1 semitone';

  @override
  String saveTransposedKey(String key) {
    return 'Save Transposed Key ($key) to Song';
  }

  @override
  String get transposeKeyTooltip => 'Transpose Key';

  @override
  String get notationEditorTooltip => 'Notation Editor';

  @override
  String get exportPdfTooltip => 'Export PDF Lead Sheet';

  @override
  String get exportMidiTooltip => 'Export MIDI File';

  @override
  String get interactiveNotationView => 'Interactive Notation View';

  @override
  String get editInNotationEditor => 'Edit in Notation Editor';

  @override
  String get noSectionsYet => 'This song has no sections yet.';

  @override
  String repeatTimes(int count) {
    return 'Repeat $count×';
  }

  @override
  String beatsCount(int count) {
    return '$count beats';
  }

  @override
  String get backToRepertoire => 'Back to Repertoire';

  @override
  String get songNotFound => 'Song not found in repertoire';

  @override
  String songKeyBadge(String key) {
    return 'Key: $key';
  }

  @override
  String failedToExportPdf(String error) {
    return 'Failed to export PDF: $error';
  }

  @override
  String failedToExportMidi(String error) {
    return 'Failed to export MIDI: $error';
  }

  @override
  String get viewOnly => 'View Only';

  @override
  String get readOnlyAdminWarning =>
      'Read-only view: Administrator permissions are required to create or modify repertoire songs.';

  @override
  String get songTitleLabel => 'Song Title *';

  @override
  String get songTitleHint => 'e.g. Amazing Grace';

  @override
  String get songTitleValidation => 'Please enter a song title';

  @override
  String get artistComposerLabel => 'Artist / Composer *';

  @override
  String get artistComposerHint => 'e.g. John Newton';

  @override
  String get artistValidation => 'Please enter an artist or composer';

  @override
  String get musicalSetup => 'Musical Setup';

  @override
  String get keyLabel => 'Key';

  @override
  String get meterLabel => 'Meter';

  @override
  String get decreaseBpm => 'Decrease BPM';

  @override
  String get increaseBpm => 'Increase BPM';

  @override
  String get tapTempo => 'Tap Tempo';

  @override
  String get addTag => 'Add Tag';

  @override
  String get tagHint => 'e.g. worship, rock, ballad';

  @override
  String get notesInstructionsLabel => 'Notes / Performance Instructions';

  @override
  String get notesInstructionsHint =>
      'e.g. Capo 3rd fret, slow acoustic intro...';

  @override
  String songSectionsCount(int count) {
    return 'Song Sections ($count)';
  }

  @override
  String get addSection => 'Add Section';

  @override
  String get quickAdd => 'Quick add: ';

  @override
  String get noSectionsAddedHint =>
      'No sections added. Tap \"+ Add Section\" to build your song.';

  @override
  String get sectionName => 'Section Name';

  @override
  String get decreaseRepeats => 'Decrease repeats';

  @override
  String get increaseRepeats => 'Increase repeats';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get deleteSection => 'Delete Section';

  @override
  String get chordsFieldLabel => 'Chords (e.g. C | G/B | Am | F)';

  @override
  String get chordsFieldHint =>
      'Type chord symbols separated by spaces or bars';

  @override
  String get applyChordsTooltip => 'Apply chords text';

  @override
  String get addChordBuilderTooltip => 'Add chord builder';

  @override
  String get sectionLyricsLabel => 'Section Lyrics';

  @override
  String get sectionLyricsHint => 'Enter lyrics line by line...';

  @override
  String get rehearsalNotesLabel => 'Rehearsal Notes (optional)';

  @override
  String get rehearsalNotesHint => 'e.g. Guitar solo starts here...';

  @override
  String get addChord => 'Add Chord';

  @override
  String get rootNote => 'Root Note';

  @override
  String get quality => 'Quality';

  @override
  String get bassNote => 'Bass Note (Slash Chord)';

  @override
  String get noneOption => 'None';

  @override
  String get beatsLabel => 'Beats: ';

  @override
  String get add => 'Add';

  @override
  String songUpdatedSuccess(String title) {
    return 'Song \"$title\" updated successfully';
  }

  @override
  String songCreatedSuccess(String title) {
    return 'Song \"$title\" created successfully';
  }

  @override
  String failedToSaveSong(String error) {
    return 'Failed to save song: $error';
  }

  @override
  String get songDeletedSuccess => 'Song deleted';

  @override
  String get adminRequiredWarning =>
      'Administrator permissions required to create or modify songs.';

  @override
  String get setlistTitle => 'Setlist';

  @override
  String get descriptionNotesField => 'Description / Notes';

  @override
  String get addSongToSetlist => 'Add Song to Setlist';

  @override
  String get noSongsInRepertoireYet =>
      'No songs in repertoire yet. Create or load sample songs.';

  @override
  String get allSongsAlreadyInSetlist =>
      'All songs are already in this setlist.';

  @override
  String get setlistEmpty => 'This setlist has no songs yet.';

  @override
  String get tapAddSongHint => 'Tap \"Add Song\" below to build your set.';

  @override
  String get removeFromSetlistTooltip => 'Remove from setlist';

  @override
  String songOriginalMeta(String artist, String key, int tempo) {
    return '$artist • Original: $key ($tempo BPM)';
  }

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get editSetlistInfoTooltip => 'Edit setlist info';

  @override
  String get scanLeadSheet => 'Scan Lead Sheet';

  @override
  String get omrScannerTitle => 'OMR Scanner';

  @override
  String get omrScannerSubtitle =>
      'Point your camera at a lead sheet or pick an image to extract\nchords, melody, and structure using Gemini AI.';

  @override
  String get openCamera => 'Open Camera';

  @override
  String get chooseFromLibrary => 'Choose from Library';

  @override
  String addedToRepertoireSuccess(String title) {
    return 'Added \"$title\" to Repertoire!';
  }

  @override
  String extractedMeasuresSuccess(int measures, String section) {
    return 'Extracted $measures measures for \"$section\".';
  }

  @override
  String get scanSheetMusic => 'Scan Sheet Music';

  @override
  String get omrDebugLogs => 'OMR Debug Logs';

  @override
  String get fullSheetSchemaA => 'Full Sheet (Schema A)';

  @override
  String get staffSnippetSchemaB => 'Staff Snippet (Schema B)';

  @override
  String get camera => 'Camera';

  @override
  String get photos => 'Photos';

  @override
  String get fullSheetDesc =>
      'Captures complete arrangement with metadata, staves, chords, and lyrics.';

  @override
  String get staffSnippetDesc =>
      'Crops a single system or melody line for rapid tap-first rhythm entry.';

  @override
  String get cropSystem => 'Crop System';

  @override
  String get changeImage => 'Change Image';

  @override
  String get analyzeWithGemini => 'Analyze with Gemini AI';

  @override
  String get recognitionError => 'Recognition Error';

  @override
  String get viewDebugLogs => 'View Debug Logs';

  @override
  String get recognitionComplete => 'Recognition Complete!';

  @override
  String get openInRepertoire => 'Open in Repertoire';

  @override
  String get openInRhythmEditor => 'Open in Rhythm Editor';

  @override
  String get analyzingSheet => 'Analyzing sheet with Gemini AI...';

  @override
  String get processingImage => 'Processing image...';

  @override
  String get transcribingSheet => 'Transcribing notes, chords & staves';

  @override
  String get omrDiagnosticLogs => 'OMR Diagnostic Logs';

  @override
  String get persistentFileSystemLogs => 'Persistent File System Logs';

  @override
  String get refreshLogs => 'Refresh Logs';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get clearOmrLogsTitle => 'Clear OMR Logs?';

  @override
  String get clearOmrLogsConfirm =>
      'This will empty the omr_debug.log file on the device.';

  @override
  String get clearAction => 'Clear';

  @override
  String get omrLogsCleared => 'OMR logs cleared from file system.';

  @override
  String get locatingLogFile => 'Locating log file...';

  @override
  String get loadingDiagnosticLogs => 'Loading diagnostic logs...';

  @override
  String get noLogsRecordedYet =>
      'No logs recorded yet.\nRun an OMR scan to capture diagnostic logs.';

  @override
  String get copyAllLogs => 'Copy All Logs';

  @override
  String get omrLogsCopied => 'OMR logs copied to clipboard.';

  @override
  String get scoreEditor => 'Score Editor';

  @override
  String get notationSavedSuccess => 'Notation changes saved to Song!';

  @override
  String failedToSaveScore(String error) {
    return 'Failed to save score: $error';
  }

  @override
  String get playbackTempo => 'Playback Tempo';

  @override
  String get setTempo => 'Set Tempo';

  @override
  String get scoreAudioPreview => 'Score Audio Preview';

  @override
  String get pauseMelody => 'Pause Melody';

  @override
  String get playMelody => 'Play / Preview Melody';

  @override
  String get stopRewind => 'Stop & Rewind';

  @override
  String get unmuteSound => 'Unmute Note Sound Feedback';

  @override
  String get muteSound => 'Mute Note Sound Feedback';

  @override
  String get apiConfigurationSection => 'API Configuration';

  @override
  String get geminiApiKeyLabel => 'Gemini API Key';

  @override
  String get geminiKeyNotConfigured => 'Not configured — tap to enter key';

  @override
  String get customLabel => 'Custom';

  @override
  String get devEnvLabel => 'Dev .env';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get errorLoadingKey => 'Error loading key';

  @override
  String get omrDiagnosticLogsSubtitle =>
      'Inspect Gemini requests, latencies & responses';

  @override
  String get appTagline =>
      'A music rehearsal & lead-sheet companion\nfor worship teams and bands.';

  @override
  String get licensesLabel => 'Licenses';

  @override
  String get footerAttribution => 'Made with ♪ for worship teams';

  @override
  String get supabaseConfigSubtitle => 'Configure Project URL & Anon Key';

  @override
  String get notSignedInOffline => 'Not signed in — Offline SQLite active';

  @override
  String get synchronizingDatabase =>
      'Synchronizing local Drift database with cloud…';

  @override
  String get offlineCached => 'Offline: Local changes safely cached';

  @override
  String get readyToSync => 'Ready to sync';

  @override
  String billingPeriodScans(int count) {
    return '$count full lead-sheet scans this billing period';
  }

  @override
  String storageTracksCount(int count) {
    return '$count scores and audio tracks stored';
  }

  @override
  String get workspaceMetricsUnavailable => 'Workspace metrics unavailable';

  @override
  String get worshipTeamTitle => 'Worship Team & Band';

  @override
  String get liveStageSync => 'Live Stage Sync';

  @override
  String get directorHost => 'Director (Host)';

  @override
  String get musicianFollower => 'Musician (Follower)';

  @override
  String get hostingStatus => 'HOSTING';

  @override
  String get syncedStatus => 'SYNCED';

  @override
  String get standaloneStatus => 'STANDALONE';

  @override
  String get syncingChangesTooltip => 'Syncing changes with Supabase…';

  @override
  String get cloudSyncedTooltip => 'Cloud synced';

  @override
  String cloudSyncedWithTimeTooltip(String time) {
    return 'Cloud synced ($time)';
  }

  @override
  String get offlineSQLiteTooltip =>
      'Offline — working with local SQLite database';

  @override
  String get syncErrorTooltip => 'Sync error';

  @override
  String get cloudReadyTooltip => 'Cloud ready (tap to sync)';

  @override
  String get syncingStatus => 'Syncing…';

  @override
  String get syncedStatusLabel => 'Synced';

  @override
  String get offlineStatusLabel => 'Offline';

  @override
  String get switchActiveProfileTooltip => 'Switch active user profile';

  @override
  String activeProfileTooltip(String name, String role) {
    return 'Active Profile: $name ($role)';
  }

  @override
  String get coverageAlertsTooltip => 'Musician Coverage Alerts';

  @override
  String coverageAlertsCountTooltip(int count) {
    return '$count cover alert(s)';
  }

  @override
  String get addTeamMemberTooltip => 'Add team member';

  @override
  String get addServiceEventTooltip => 'Add service event';

  @override
  String get noUpcomingServices => 'No upcoming services scheduled.';

  @override
  String get scheduleFirstService => 'Schedule First Service';

  @override
  String get editMember => 'Edit Member';

  @override
  String get scheduleForService => 'Schedule for Service';

  @override
  String get editService => 'Edit Service';

  @override
  String get assignGroup => 'Assign Group';

  @override
  String get assignMusician => 'Assign Musician';

  @override
  String get triggerTestCue => 'Trigger Test Cue';

  @override
  String get approveJump => 'Approve Jump';

  @override
  String get geminiApiKeySaved => 'Gemini API key saved securely.';

  @override
  String get removeApiKeyTitle => 'Remove API Key?';

  @override
  String get customApiKeyRemoved => 'Custom API key removed.';

  @override
  String get removeKey => 'Remove Key';

  @override
  String get saveKey => 'Save Key';

  @override
  String get supabaseProjectSetup => 'Supabase Project Setup';

  @override
  String get restoreDefault => 'Restore Default';

  @override
  String get saveAndConnect => 'Save & Connect';

  @override
  String get selectActiveProfileTitle => 'Select Active User Profile';

  @override
  String get switchActiveProfileDesc =>
      'Switch active user to preview musician permissions vs administrator capabilities.';

  @override
  String get adminRole => 'Admin';

  @override
  String get administrator => 'Administrator';

  @override
  String get musician => 'Musician';

  @override
  String activeUserChanged(String name, String role) {
    return 'Active user: $name ($role)';
  }

  @override
  String get totalRoster => 'Total Roster';

  @override
  String get scheduledLabel => 'Scheduled';

  @override
  String get availableLabel => 'Available';

  @override
  String get availableStatus => 'Available';

  @override
  String get nextServicePrefix => 'Next:';

  @override
  String get filterAll => 'All';

  @override
  String get filterScheduled => 'Scheduled';

  @override
  String get filterVocals => 'Vocals';

  @override
  String get filterBand => 'Band';

  @override
  String get noMembersMatchFilter => 'No team members match this filter.';

  @override
  String get nextServiceBadge => 'NEXT SERVICE';

  @override
  String get bandLineupTitle => 'Band Lineup';

  @override
  String get cantAttendBadge => 'Can\'t attend';

  @override
  String get notScheduledForServices =>
      'Not currently scheduled for upcoming services';

  @override
  String cloudSyncSuccess(int pushed, int pulled) {
    return 'Cloud synced successfully ($pushed pushed, $pulled pulled)';
  }

  @override
  String get cloudSyncStatusTitle => 'Cloud Synchronization';

  @override
  String get cloudSignInRequired =>
      'Please sign in to Supabase to enable cloud sync.';

  @override
  String get cloudOfflineMode =>
      'Offline mode active. All changes are saved safely to local SQLite.';

  @override
  String get signInAction => 'Sign In';

  @override
  String get configureAction => 'Configure';

  @override
  String get retryAction => 'Retry';

  @override
  String get noMusiciansAssignedYet =>
      'No musicians assigned yet. Tap \"Assign Musician\" to schedule band members.';

  @override
  String get deleteService => 'Delete Service';
}
