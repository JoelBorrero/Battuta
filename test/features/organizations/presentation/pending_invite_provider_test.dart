import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/pending_invite_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Account extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void set(String? id) => state = id;
}

final _account = NotifierProvider<_Account, String?>(_Account.new);

void main() {
  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [
        currentAccountIdProvider.overrideWith((ref) => ref.watch(_account)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('signing in keeps the token, signing out drops it', () {
    final c = make();
    c.read(pendingInviteTokenProvider.notifier).set('t');
    c.read(_account.notifier).set('a');
    expect(c.read(pendingInviteTokenProvider), 't');

    c.read(_account.notifier).set(null);
    expect(c.read(pendingInviteTokenProvider), isNull);
  });

  test('switching to another account drops the token', () {
    final c = make();
    c.read(_account.notifier).set('a');
    c.read(pendingInviteTokenProvider.notifier).set('t');

    c.read(_account.notifier).set('b');
    expect(c.read(pendingInviteTokenProvider), isNull);
  });
}
