import 'package:battuta/features/scanner/presentation/providers/omr_log_provider.dart';
import 'package:battuta/features/scanner/presentation/widgets/omr_log_viewer_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOmrLogNotifier extends OmrLogNotifier {
  FakeOmrLogNotifier(this.initialState);

  final OmrLogState initialState;

  @override
  Future<OmrLogState> build() async => initialState;

  @override
  Future<void> clearLogs() async {
    state = const AsyncData(
      OmrLogState(
        filePath: '/test/logs/omr_debug.log',
        content: '',
        fileSizeBytes: 0,
      ),
    );
  }
}

void main() {
  const sampleState = OmrLogState(
    filePath: '/data/user/0/com.battuta.battuta/logs/omr_debug.log',
    fileSizeBytes: 2048,
    content: '[OMR_SESSION_START] Sample log message for UI inspection',
  );

  Widget buildSubject({OmrLogState state = sampleState}) {
    return ProviderScope(
      overrides: [
        omrLogNotifierProvider.overrideWith(() => FakeOmrLogNotifier(state)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: OmrLogViewerModal(),
        ),
      ),
    );
  }

  testWidgets('OmrLogViewerModal renders header, file path and log content',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('OMR Diagnostic Logs'), findsOneWidget);
    expect(find.text('Persistent File System Logs'), findsOneWidget);
    expect(find.byKey(const ValueKey('omr_logs_copy_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('omr_logs_refresh_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('omr_logs_clear_btn')), findsOneWidget);

    expect(find.textContaining('Sample log message for UI inspection'),
        findsOneWidget);
    expect(find.textContaining('2.0 KB'), findsOneWidget);
  });

  testWidgets('OmrLogViewerModal clears logs via dialog confirmation',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.textContaining('Sample log message for UI inspection'),
        findsOneWidget);

    // Tap clear button
    await tester.tap(find.byKey(const ValueKey('omr_logs_clear_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Clear OMR Logs?'), findsOneWidget);

    // Confirm dialog
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sample log message for UI inspection'),
        findsNothing);
  });
}
