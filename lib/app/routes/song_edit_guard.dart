/// Editing routes of a song, kept pure so they can be unit tested.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';

/// Where the editor of [song] must redirect to for [accountId]: the viewer
/// when the version belongs to somebody else, `null` (stay) otherwise. An
/// unknown song is left to the page, which says it was not found.
String? songEditRedirect({required Song? song, required String? accountId}) {
  if (song == null || song.isEditableBy(accountId)) return null;
  return AppRoutes.songDetail(song.id);
}
