/// Why the welcome screen is shown again after the session ended.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountNotice { deactivated }

class AccountNoticeNotifier extends Notifier<AccountNotice?> {
  @override
  AccountNotice? build() => null;

  void show(AccountNotice notice) => state = notice;
  void clear() => state = null;
}

final accountNoticeProvider =
    NotifierProvider<AccountNoticeNotifier, AccountNotice?>(
      AccountNoticeNotifier.new,
    );
