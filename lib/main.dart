/// Battuta — Main application entry point.
///
/// Initializes the app with Riverpod's [ProviderScope] and launches
/// the root [BattutaApp] widget.
library;

import 'package:battuta/app/app.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize runtime environment configuration
  EnvConfig.init(Environment.dev);

  // Attempt to load .env variables for local development
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    AppLogger.info('.env file not found or not loaded: $e');
  }

  AppLogger.info('Starting Battuta…');

  runApp(
    const ProviderScope(
      child: BattutaApp(),
    ),
  );
}
