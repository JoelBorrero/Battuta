/// Battuta — the director's card: name the session, host it, see who joined
/// and share the address (typed or as a QR) when discovery is blocked.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/live_session/presentation/widgets/live_connect_texts.dart';
import 'package:battuta/features/sync/domain/models/live_join_address.dart';
import 'package:battuta/features/sync/domain/services/live_session_discovery.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DirectorHostCard extends StatelessWidget {
  const DirectorHostCard({
    required this.nameController,
    required this.hosting,
    required this.deviceName,
    required this.joinAddress,
    required this.followers,
    required this.issue,
    required this.onHost,
    required this.onStop,
    required this.onTestCue,
    super.key,
  });

  final TextEditingController nameController;
  final bool hosting;
  final String deviceName;
  final LiveJoinAddress? joinAddress;
  final List<String> followers;
  final LiveConnectIssue? issue;
  final VoidCallback onHost;
  final VoidCallback onStop;
  final VoidCallback onTestCue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final address = joinAddress;

    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: hosting ? brand.wash(brand.danger) : brand.accent,
      foregroundColor: hosting ? brand.danger : brand.onAccent,
      minimumSize: const Size(44, 44),
      side: hosting
          ? BorderSide(color: brand.danger.withValues(alpha: 0.6))
          : null,
    );

    return StageCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (l10n?.liveHostTitle ?? 'Host a session').toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: brand.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (!hosting) ...[
            Text(
              l10n?.liveHostIntro ?? 'Band members on the same Wi-Fi or hotspot will see your session in their Live tab.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('live_session_name_field'),
              controller: nameController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: liveSessionNameMaxLength,
              decoration: InputDecoration(
                counterText: '',
                labelText: l10n?.liveSessionNameLabel ?? 'Session name',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ] else ...[
            Text(
              l10n?.liveHostingAs(nameController.text, deviceName) ??
                  '${nameController.text} · $deviceName',
              key: const ValueKey('live_hosting_as'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              l10n?.liveDevicesConnected(followers.length) ??
                  '${followers.length} ${followers.length == 1 ? 'device' : 'devices'} connected',
              key: const ValueKey('live_devices_connected'),
              style: TextStyle(fontSize: 13, color: brand.inkMuted),
            ),
            if (followers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in followers)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: brand.cardRaised,
                        borderRadius: BorderRadius.circular(BattutaRadius.pill),
                        border: Border.all(color: brand.border),
                      ),
                      child: Text(
                        name.isEmpty
                            ? (l10n?.liveUnnamedDevice ?? 'Unnamed device')
                            : name,
                        style: TextStyle(fontSize: 12, color: brand.ink),
                      ),
                    ),
                ],
              ),
            ],
          ],
          if (issue != null) ...[
            const SizedBox(height: 12),
            Text(
              liveIssueText(l10n, issue!),
              key: const ValueKey('live_issue'),
              style: TextStyle(fontSize: 13, color: brand.danger),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('live_host_toggle'),
                style: primaryStyle,
                icon: Icon(hosting ? Icons.stop : Icons.play_arrow),
                label: Text(
                  hosting
                      ? (l10n?.liveStopHosting ?? 'Stop hosting')
                      : (l10n?.liveHostAction ?? 'Host session'),
                ),
                onPressed: hosting ? onStop : onHost,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(l10n?.triggerTestCue ?? 'Trigger Test Cue'),
                onPressed: onTestCue,
              ),
            ],
          ),
          if (hosting && address != null) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: brand.border),
            const SizedBox(height: 14),
            Text(
              (l10n?.liveCantSeeIt ?? 'Can’t see it? Join by address')
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: brand.inkMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    address.display,
                    key: const ValueKey('live_join_address'),
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      fontFamilyFallback: AppTheme.monoFontFallbacks,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: brand.accentInk,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('live_copy_address'),
                  tooltip: l10n?.liveAddressCopy ?? 'Copy address',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: address.display),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.liveAddressCopied ?? 'Address copied',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              // A QR code always needs dark modules on a light ground.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.pureWhiteSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  key: const ValueKey('live_join_qr'),
                  data: address.link,
                  size: 160,
                  padding: const EdgeInsets.all(12),
                  backgroundColor: AppTheme.pureWhiteSurface,
                  semanticsLabel:
                      l10n?.liveQrSemantics ?? 'QR code to join this session',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.liveQrHint ??
                  'Scan it with the phone camera to open Battuta and join.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: brand.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
