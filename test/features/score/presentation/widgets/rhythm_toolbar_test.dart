import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/presentation/providers/rhythm_editor_controller.dart';
import 'package:battuta/features/score/presentation/widgets/measure_progress_bar.dart';
import 'package:battuta/features/score/presentation/widgets/rhythm_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Score createTestScore() {
    return Score(
      id: 'score-test',
      title: 'Rhythm Test Song',
      sections: [
        Section(
          id: 'sec-1',
          name: 'Verse',
          measures: [
            Measure(
              number: 1,
              timeSignature: TimeSignature.fourFour, // 1920 ticks max
              events: [
                NoteEvent.note(
                  id: 'm1-e1',
                  pitch: Pitch.parse('C4'),
                  rhythmicValue: RhythmicValue.unassigned, // 0 ticks
                ),
                NoteEvent.note(
                  id: 'm1-e2',
                  pitch: Pitch.parse('D4'),
                  rhythmicValue: RhythmicValue.unassigned, // 0 ticks
                ),
                NoteEvent.note(
                  id: 'm1-e3',
                  pitch: Pitch.parse('E4'),
                  rhythmicValue: RhythmicValue.unassigned, // 0 ticks
                ),
              ],
            ),
            Measure(
              number: 2,
              timeSignature: TimeSignature.fourFour,
              events: [
                NoteEvent.note(
                  id: 'm2-e1',
                  pitch: Pitch.parse('F4'),
                  rhythmicValue: RhythmicValue.unassigned,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  group('RhythmEditorController (Checklist Requirements)', () {
    test('auto-selects first unassigned note upon initialization', () {
      final score = createTestScore();
      final controller = RhythmEditorController(initialScore: score);

      expect(controller.state.cursor, isNotNull);
      expect(controller.state.cursor!.sectionId, equals('sec-1'));
      expect(controller.state.cursor!.measureNumber, equals(1));
      expect(controller.state.cursor!.eventIndex, equals(0));
    });

    test('assignDuration assigns RhythmicValue and advances cursor to next unassigned note', () {
      final score = createTestScore();
      final controller = RhythmEditorController(initialScore: score);

      // Assign Quarter (480 ticks) to Note 0 (C4)
      final success1 = controller.assignDuration(RhythmicValue.quarter);
      expect(success1, isTrue);

      final m1 = controller.state.activeMeasure!;
      expect(m1.events[0].rhythmicValue, equals(RhythmicValue.quarter));
      expect(m1.events[0].tickOffset, equals(0));

      // Cursor automatically advances to note index 1 (D4)
      expect(controller.state.cursor!.eventIndex, equals(1));

      // Assign Half (960 ticks) to Note 1 (D4)
      final success2 = controller.assignDuration(RhythmicValue.half);
      expect(success2, isTrue);

      expect(
        controller.state.activeMeasure!.events[1].rhythmicValue,
        equals(RhythmicValue.half),
      );
      expect(controller.state.activeMeasure!.events[1].tickOffset, equals(480));

      // Cursor automatically advances to note index 2 (E4)
      expect(controller.state.cursor!.eventIndex, equals(2));
    });

    test(
      'advances across measures when current measure has no unassigned notes',
      () {
        final score = createTestScore();
        final controller = RhythmEditorController(initialScore: score);

        // Assign Note 0
        controller.assignDuration(RhythmicValue.quarter);
        // Assign Note 1
        controller.assignDuration(RhythmicValue.quarter);
        // Assign Note 2 (last note in Measure 1)
        controller.assignDuration(RhythmicValue.half);

        // Cursor should advance to Measure 2, Note 0 (F4)
        expect(controller.state.cursor!.measureNumber, equals(2));
        expect(controller.state.cursor!.eventIndex, equals(0));
      },
    );

    test(
      'disables assigning rhythm when it would exceed Measure.remainingTicks',
      () {
        final score = createTestScore();
        final controller = RhythmEditorController(initialScore: score);

        // Remaining ticks in Measure 1 = 1920
        // Assign Dotted Half (1440 ticks) to note 0
        controller.assignDuration(RhythmicValue.dottedHalf);
        // Now remaining ticks = 1920 - 1440 = 480 ticks!

        // Note 1 cursor:
        expect(controller.state.cursor!.eventIndex, equals(1));
        expect(controller.state.activeMeasureRemainingTicks, equals(480));

        // Whole note (1920) cannot fit (1440 + 1920 > 1920)
        expect(controller.state.canFitRhythm(RhythmicValue.whole), isFalse);
        // Half note (960) cannot fit (1440 + 960 > 1920)
        expect(controller.state.canFitRhythm(RhythmicValue.half), isFalse);
        // Quarter note (480) fits exactly (1440 + 480 == 1920)
        expect(controller.state.canFitRhythm(RhythmicValue.quarter), isTrue);
        // Eighth note (240) fits (1440 + 240 < 1920)
        expect(controller.state.canFitRhythm(RhythmicValue.eighth), isTrue);

        // Attempting to assign Half fails and returns false
        final assigned = controller.assignDuration(RhythmicValue.half);
        expect(assigned, isFalse);
        // State and cursor unchanged
        expect(controller.state.cursor!.eventIndex, equals(1));
      },
    );

    test('toggleRest and toggleTie update note state at cursor', () {
      final score = createTestScore();
      final controller = RhythmEditorController(initialScore: score);

      // Note 0 has a pitch (not rest)
      expect(controller.state.activeEvent!.isRest, isFalse);
      expect(controller.state.activeEvent!.isTied, isFalse);

      controller.toggleRest();
      expect(controller.state.activeEvent!.isRest, isTrue);

      controller.toggleRest();
      expect(controller.state.activeEvent!.isRest, isFalse);

      controller.toggleTie();
      expect(controller.state.activeEvent!.isTied, isTrue);
    });
  });

  group('MeasureProgressBar Widget', () {
    testWidgets('renders ticks, ratio, and completion status', (tester) async {
      const measure = Measure(
        number: 3,
        timeSignature: TimeSignature.fourFour,
        events: [
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.middleC,
            rhythmicValue: RhythmicValue.half, // 960
            tickOffset: 0,
          ),
          NoteEvent.note(
            id: 'e2',
            pitch: Pitch.middleC,
            rhythmicValue: RhythmicValue.half, // 960 (total 1920 = 100%)
            tickOffset: 960,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MeasureProgressBar(measure: measure)),
        ),
      );

      expect(find.text('Measure #3 (4/4)'), findsOneWidget);
      expect(find.text('Complete (1920t)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('RhythmToolbar Widget (Checklist Verification)', () {
    testWidgets(
      'Tapping duration button assigns rhythm and advances cursor; buttons exceeding capacity are disabled',
      (tester) async {
        final score = createTestScore();
        final controller = RhythmEditorController(initialScore: score);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RhythmToolbar(controller: controller)),
          ),
        );

        await tester.pumpAndSettle();

        // At start (0 ticks filled), all buttons should be enabled
        final wholeBtnFinder = find.byKey(const Key('rhythm_btn_Whole'));
        final quarterBtnFinder = find.byKey(const Key('rhythm_btn_Quarter'));
        final halfBtnFinder = find.byKey(const Key('rhythm_btn_Half'));

        expect(
          tester.widget<OutlinedButton>(wholeBtnFinder).onPressed,
          isNotNull,
        );
        expect(
          tester.widget<OutlinedButton>(quarterBtnFinder).onPressed,
          isNotNull,
        );

        // Tap Dotted Half button (1440 ticks)
        final dottedHalfBtnFinder = find.byKey(
          const Key('rhythm_btn_Dotted Half'),
        );
        await tester.tap(dottedHalfBtnFinder);
        await tester.pumpAndSettle();

        // Now Note 0 is assigned Dotted Half (1440t). Remaining in measure = 480t!
        // Cursor has advanced to Note 1:
        expect(controller.state.cursor!.eventIndex, equals(1));

        // Checklist: "Buttons exceeding Measure.remainingTicks are disabled."
        // Whole (1920) must be disabled:
        expect(tester.widget<OutlinedButton>(wholeBtnFinder).onPressed, isNull);
        // Dotted Half (1440) must be disabled:
        expect(
          tester.widget<OutlinedButton>(dottedHalfBtnFinder).onPressed,
          isNull,
        );
        // Half (960) must be disabled:
        expect(tester.widget<OutlinedButton>(halfBtnFinder).onPressed, isNull);
        // Quarter (480) fits remaining capacity: must be enabled!
        expect(
          tester.widget<OutlinedButton>(quarterBtnFinder).onPressed,
          isNotNull,
        );

        // Tap Quarter button to fill measure (1440 + 480 = 1920t)
        await tester.tap(quarterBtnFinder);
        await tester.pumpAndSettle();

        // Measure 1 is now completely full (1920t).
        // Cursor advances to Note 2:
        expect(controller.state.cursor!.eventIndex, equals(2));
        // Remaining ticks in Measure 1 = 0!
        // All duration buttons should now be disabled for Note 2 since measure is full!
        expect(
          tester.widget<OutlinedButton>(quarterBtnFinder).onPressed,
          isNull,
        );
      },
    );
  });
}
