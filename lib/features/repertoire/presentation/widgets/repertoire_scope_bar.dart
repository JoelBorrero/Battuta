/// Switches the Repertoire page between my library and the repertoire of each
/// organization I belong to.
library;

import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
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
    final selected = ref.watch(scopeOrganizationProvider)?.id;
    final notifier = ref.read(repertoireScopeProvider.notifier);

    return Semantics(
      label: l10n.repertoireScopeLabel,
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BattutaSpace.lg,
          BattutaSpace.sm,
          BattutaSpace.lg,
          0,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: BattutaSpace.sm,
            runSpacing: BattutaSpace.sm,
            children: [
              ChoiceChip(
                key: const ValueKey('scope_mine'),
                label: Text(l10n.repertoireScopeMyLibrary),
                selected: selected == null,
                onSelected: (_) => notifier.select(null),
              ),
              for (final organization in organizations)
                ChoiceChip(
                  key: ValueKey('scope_org_${organization.id}'),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      l10n.repertoireScopeOrganization(organization.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  selected: selected == organization.id,
                  onSelected: (_) => notifier.select(organization.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
