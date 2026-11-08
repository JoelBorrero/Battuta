/// Battuta — Demo Mode Provider.
///
/// Controls application-wide Demo / Showcase Mode:
/// - When TRUE: displays sample team members, calendar schedules, mock AI credits,
///   cloud storage quotas, and demo rehearsal audio tracks.
/// - When FALSE: displays only genuine data from the local database, real zero-based
///   usage metrics, and dedicated empty/attachment states.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages application-level Demo Mode state.
class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Defaults to false for authentic production/database usage
    return false;
  }

  /// Updates Demo Mode enabled state.
  void setDemoMode(bool enabled) {
    state = enabled;
  }

  /// Toggles Demo Mode between enabled and disabled.
  void toggle() {
    state = !state;
  }
}

/// Provides application-level Demo Mode state.
final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);
