/// A one-shot request to open a tab of the Team page (e.g. from the inbox).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tabs of the Team page, in segment order.
enum TeamTab { roster, calendar }

class TeamTabRequest extends Notifier<TeamTab?> {
  @override
  TeamTab? build() => null;

  void request(TeamTab tab) => state = tab;

  void clear() => state = null;
}

final teamTabRequestProvider = NotifierProvider<TeamTabRequest, TeamTab?>(
  TeamTabRequest.new,
);
