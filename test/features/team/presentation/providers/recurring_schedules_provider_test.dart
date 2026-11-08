import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:battuta/features/team/presentation/providers/recurring_schedules_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDemoModeNotifier extends DemoModeNotifier {
  _FakeDemoModeNotifier([this._initial = true]);
  final bool _initial;
  @override
  bool build() => _initial;
}

void main() {
  group('RecurringSchedulesProvider', () {
    test('is empty when demo mode is disabled', () {
      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(false)),
        ],
      );
      addTearDown(container.dispose);

      final schedules = container.read(recurringSchedulesProvider);
      expect(schedules, isEmpty);
    });

    test(
      'initializes with sample Sunday Morning and Midweek rules in demo mode',
      () {
        final container = ProviderContainer(
          overrides: [
            demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(true)),
          ],
        );
        addTearDown(container.dispose);

        final schedules = container.read(recurringSchedulesProvider);
        expect(schedules.length, equals(2));
        expect(schedules.any((s) => s.id == 'series-sunday-morning'), isTrue);
        expect(
          schedules.any((s) => s.id == 'series-thursday-rehearsal'),
          isTrue,
        );
      },
    );

    test('toggles active state of a recurring schedule', () {
      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(true)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(recurringSchedulesProvider)
            .firstWhere((s) => s.id == 'series-sunday-morning')
            .isActive,
        isTrue,
      );

      container
          .read(recurringSchedulesProvider.notifier)
          .toggleActive('series-sunday-morning');

      expect(
        container
            .read(recurringSchedulesProvider)
            .firstWhere((s) => s.id == 'series-sunday-morning')
            .isActive,
        isFalse,
      );
    });

    test('sets and clears cutoff disabled date', () {
      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(true)),
        ],
      );
      addTearDown(container.dispose);

      final cutoff = DateTime(2026, 12, 1);
      container
          .read(recurringSchedulesProvider.notifier)
          .setDisabledDate('series-sunday-morning', cutoff);

      expect(
        container
            .read(recurringSchedulesProvider)
            .firstWhere((s) => s.id == 'series-sunday-morning')
            .disabledAfter,
        equals(cutoff),
      );

      // Clear cutoff
      container
          .read(recurringSchedulesProvider.notifier)
          .setDisabledDate('series-sunday-morning', null);

      expect(
        container
            .read(recurringSchedulesProvider)
            .firstWhere((s) => s.id == 'series-sunday-morning')
            .disabledAfter,
        isNull,
      );
    });

    test('updates lookahead count (X number of events ahead)', () {
      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(true)),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(recurringSchedulesProvider.notifier)
          .setLookaheadCount('series-sunday-morning', 8);

      expect(
        container
            .read(recurringSchedulesProvider)
            .firstWhere((s) => s.id == 'series-sunday-morning')
            .lookaheadCount,
        equals(8),
      );
    });
  });
}
