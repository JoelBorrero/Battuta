/// Streams of local rows that follow the signed-in account.
library;

import 'dart:async';

import 'package:battuta/features/organizations/domain/repositories/account_session.dart';

/// Emits [build]`(account)` for the signed-in account and switches to the new
/// account's stream whenever it changes. Without a [session] it is simply
/// [build]`(null)`.
Stream<T> watchForAccount<T>(
  AccountSession? session,
  Stream<T> Function(String? accountId) build,
) {
  if (session == null) return build(null);
  late final StreamController<T> controller;
  StreamSubscription<T>? inner;
  StreamSubscription<String?>? outer;
  var bound = false;
  String? boundId;

  Future<void> bind(String? id) async {
    if (bound && id == boundId) return;
    bound = true;
    boundId = id;
    await inner?.cancel();
    inner = build(id).listen(controller.add, onError: controller.addError);
  }

  controller = StreamController<T>(
    onListen: () {
      outer = session.userIdChanges.listen(bind);
      bind(session.userId);
    },
    onCancel: () async {
      await outer?.cancel();
      await inner?.cancel();
    },
  );
  return controller.stream;
}
