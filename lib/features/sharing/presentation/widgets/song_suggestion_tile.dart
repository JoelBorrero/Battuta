/// One song offered while a version is created, imported, scanned or moved:
/// title, artist and how many versions it has.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class SongSuggestionTile extends StatelessWidget {
  const SongSuggestionTile({
    required this.suggestion,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final SongSuggestion suggestion;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    return BattutaPressable(
      onTap: onTap,
      semanticLabel: suggestion.title,
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: brand.cardDecoration(selected: selected, pressed: pressed),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (suggestion.artist.isNotEmpty)
                    Text(
                      suggestion.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: brand.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                l10n.songLinkVersionCount(suggestion.versionCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: brand.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
