/// Switches the Repertoire page between my library and the repertoire of each
/// organization I belong to.
///
/// Shown as a pill button (logo tile, name, chevron) that opens a sheet with
/// every repertoire I can show.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/profile/presentation/widgets/organization_logo.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RepertoireScopeBar extends ConsumerWidget {
  const RepertoireScopeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
    // Without an organization there is only my library: nothing to switch.
    if (organizations.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final selected = ref.watch(scopeOrganizationProvider);
    final name = selected == null
        ? l10n.repertoireScopeMyLibrary
        : l10n.repertoireScopeOrganization(selected.name);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: BattutaPressable(
          key: const ValueKey('scope_picker'),
          semanticLabel: '${l10n.repertoireScopeLabel}: $name',
          onTap: () => _openSheet(context, organizations),
          builder: (context, pressed) => AnimatedContainer(
            duration: BattutaMotion.resolve(context, BattutaMotion.tick),
            curve: BattutaMotion.downbeat,
            height: 40,
            padding: const EdgeInsetsDirectional.only(
              start: 6,
              end: BattutaSpace.md,
            ),
            decoration: ShapeDecoration(
              color: pressed ? brand.cardRaised : brand.card,
              shape: StadiumBorder(side: BorderSide(color: brand.border)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScopeLogo(organization: selected, size: 28),
                const SizedBox(width: BattutaSpace.sm),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: brand.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: BattutaSpace.xs),
                Icon(Icons.expand_more, size: 18, color: brand.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, List<Organization> organizations) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context)!;
          final brand = BattutaBrand.of(context);
          final selectedId = ref.watch(scopeOrganizationProvider)?.id;
          final notifier = ref.read(repertoireScopeProvider.notifier);

          void pick(String? organizationId) {
            notifier.select(organizationId);
            Navigator.of(sheetContext).pop();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                BattutaSpace.lg,
                BattutaSpace.md,
                BattutaSpace.lg,
                BattutaSpace.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StageSectionHeader(title: l10n.repertoireScopeLabel),
                  StageCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ScopeOption(
                          key: const ValueKey('scope_mine'),
                          label: l10n.repertoireScopeMyLibrary,
                          organization: null,
                          selected: selectedId == null,
                          onTap: () => pick(null),
                        ),
                        for (final organization in organizations) ...[
                          Divider(height: 1, color: brand.border),
                          _ScopeOption(
                            key: ValueKey('scope_org_${organization.id}'),
                            label: l10n.repertoireScopeOrganization(
                              organization.name,
                            ),
                            organization: organization,
                            selected: selectedId == organization.id,
                            onTap: () => pick(organization.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The tile in front of a scope: the organization's logo, or a library icon
/// for my own songs.
class _ScopeLogo extends StatelessWidget {
  const _ScopeLogo({required this.organization, required this.size});

  final Organization? organization;
  final double size;

  @override
  Widget build(BuildContext context) {
    final org = organization;
    if (org != null) {
      return OrganizationLogo(logoPath: org.logoPath, size: size);
    }
    final brand = BattutaBrand.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brand.accentWash,
        borderRadius: BorderRadius.circular(OrganizationLogo.radiusFor(size)),
      ),
      child: Icon(
        Icons.library_music_outlined,
        size: size * 0.55,
        color: brand.accentInk,
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.organization,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Organization? organization;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Semantics(
      selected: selected,
      child: BattutaPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BattutaSpace.md,
              vertical: BattutaSpace.sm,
            ),
            child: Row(
              children: [
                _ScopeLogo(organization: organization, size: 36),
                const SizedBox(width: BattutaSpace.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: brand.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check, size: 20, color: brand.accentInk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
