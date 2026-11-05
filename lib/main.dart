/// Battuta — Main application entry point.
///
/// Initializes the app with Riverpod's [ProviderScope] and launches
/// the root [BattutaApp] widget.
library;

import 'package:battuta/app/app.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('Starting Battuta…');

  runApp(
    const ProviderScope(
      child: BattutaApp(),
    ),
  );
}
