/// Battuta — Stage surfaces: cards, groups, section headers and icon tiles.
///
/// These are the building blocks every screen uses instead of Material's
/// `Card`, `InkWell` and ad-hoc `Container` decorations, so surfaces stay
/// flush, border-delineated and consistent in both themes.
library;

import 'package:battuta/app/design_system/motion/pressable.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

/// Flush, 1px-bordered card. Pressable when [onTap] is given.
class StageCard extends StatelessWidget {
  const StageCard({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(BattutaSpace.md),
    this.selected = false,
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  /// Highlights the card with an amber border.
  final bool selected;

  /// Overrides the surface color (defaults to `brand.card`).
  final Color? color;

  /// Overrides the border color.
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);

    Widget surface(bool pressed) => AnimatedContainer(
      duration: BattutaMotion.resolve(context, BattutaMotion.tick),
      curve: BattutaMotion.downbeat,
      padding: padding,
      decoration: BoxDecoration(
        color: pressed ? brand.cardRaised : (color ?? brand.card),
        borderRadius: BattutaRadius.mdAll,
        border: Border.all(
          color: selected ? brand.accent : (borderColor ?? brand.border),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: child,
    );

    if (onTap == null && onLongPress == null) return surface(false);
    return BattutaPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => surface(pressed),
    );
  }
}

/// Section label from the Battuta Screens designs: 13pt bold, tracked,
/// uppercase, muted. Uppercasing is locale-aware (`toUpperCase` on the
/// localized string), and the semantics label keeps the original casing so
/// screen readers don't spell it out.
class StageSectionHeader extends StatelessWidget {
  const StageSectionHeader({
    required this.title,
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      BattutaSpace.lg,
      BattutaSpace.xl,
      BattutaSpace.lg,
      BattutaSpace.sm,
    ),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: title,
              excludeSemantics: true,
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: brand.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// iOS-style inset group: a [StageSectionHeader] followed by one bordered
/// card whose rows are separated by hairline dividers.
///
/// Rows are typically `ListTile`s; they keep their keys and semantics.
class StageGroup extends StatelessWidget {
  const StageGroup({
    required this.children,
    super.key,
    this.title,
    this.footer,
    this.margin = const EdgeInsets.symmetric(horizontal: BattutaSpace.lg),
  });

  final String? title;
  final List<Widget> children;

  /// Optional muted note under the card.
  final String? footer;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: 1, thickness: 1, color: brand.border));
      }
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          StageSectionHeader(
            title: title!,
            padding: const EdgeInsets.fromLTRB(
              BattutaSpace.lg,
              BattutaSpace.xl,
              BattutaSpace.lg,
              BattutaSpace.sm,
            ),
          ),
        Padding(
          padding: margin,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: brand.card,
              borderRadius: BattutaRadius.mdAll,
              border: Border.all(color: brand.border),
            ),
            child: ClipRRect(
              borderRadius: BattutaRadius.mdAll,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              ),
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BattutaSpace.xl,
              BattutaSpace.sm,
              BattutaSpace.xl,
              0,
            ),
            child: Text(
              footer!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: brand.inkMuted),
            ),
          ),
      ],
    );
  }
}

/// Rounded tinted tile holding an icon or short text (a musical key, a
/// count). The visual anchor of stage cards and list rows.
class StageIconTile extends StatelessWidget {
  const StageIconTile({
    super.key,
    this.icon,
    this.label,
    this.caption,
    this.size = 52,
    this.tone,
  }) : assert(icon != null || label != null);

  final IconData? icon;

  /// Large text (e.g. a musical key) shown instead of / under [icon].
  final String? label;

  /// Small text under the icon (e.g. a count).
  final String? caption;
  final double size;

  /// Accent color; defaults to stage amber.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final accent = tone ?? brand.accent;
    final ink = tone ?? brand.accentInk;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone == null ? brand.accentWash : brand.wash(accent),
        borderRadius: BorderRadius.circular(
          size >= 44 ? BattutaRadius.sm : BattutaRadius.xs + 2,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: BattutaSpace.xs),
      child: label != null
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label!,
                maxLines: 1,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: ink,
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: size * (caption == null ? 0.46 : 0.38),
                  color: ink,
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: textTheme.labelSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Musical key badge from the designs: amber wash, amber monospace text.
class StageKeyPill extends StatelessWidget {
  const StageKeyPill(this.musicalKey, {super.key, this.large = false});

  final String musicalKey;

  /// Larger variant used in headers.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      constraints: BoxConstraints(minWidth: large ? 44 : 36),
      height: large ? 34 : 28,
      padding: const EdgeInsets.symmetric(horizontal: BattutaSpace.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.accentWash,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        musicalKey,
        maxLines: 1,
        style: TextStyle(
          fontFamily: AppTheme.monoFontFamily,
          fontFamilyFallback: AppTheme.monoFontFallbacks,
          fontSize: large ? 17 : 14,
          fontWeight: FontWeight.w700,
          color: brand.accentInk,
        ),
      ),
    );
  }
}

/// A value + caption tile (e.g. "72 / BPM"). Lay out several with
/// [StageStatRow].
class StageStatTile extends StatelessWidget {
  const StageStatTile({
    required this.value,
    required this.label,
    super.key,
    this.unit,
    this.accent = false,
    this.mono = false,
    this.valueKey,
  });

  final String value;
  final String label;

  /// Small muted suffix after the value (e.g. "min").
  final String? unit;

  /// Renders the value in stage amber.
  final bool accent;

  /// Renders the value in the monospace face (keys, chords).
  final bool mono;

  /// Key for the value text (lets callers animate value changes).
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final valueStyle = TextStyle(
      fontFamily: mono ? AppTheme.monoFontFamily : AppTheme.primaryFontFamily,
      fontFamilyFallback: mono
          ? AppTheme.monoFontFallbacks
          : AppTheme.fontFamilyFallbacks,
      fontSize: 22,
      fontWeight: mono ? FontWeight.w700 : FontWeight.w800,
      color: accent ? brand.accentInk : brand.ink,
      height: 1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.all(BattutaSpace.md),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: BattutaMotion.resolve(context, BattutaMotion.beat),
            switchInCurve: BattutaMotion.rebound,
            switchOutCurve: BattutaMotion.upbeat,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: Text.rich(
              key: valueKey ?? ValueKey(value),
              TextSpan(
                text: value,
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: brand.inkMuted,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
          const SizedBox(height: BattutaSpace.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: brand.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Equal-width row of [StageStatTile]s with 8pt gaps.
class StageStatRow extends StatelessWidget {
  const StageStatRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: BattutaSpace.sm),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Settings-style list row: 20pt icon, 16pt label, optional muted value,
/// and a chevron when tappable. Minimum height 52pt.
class StageRow extends StatelessWidget {
  const StageRow({
    required this.label,
    super.key,
    this.icon,
    this.leading,
    this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData? icon;

  /// Custom leading widget (overrides [icon]).
  final Widget? leading;
  final String? value;
  final String? subtitle;

  /// Custom trailing widget (overrides value + chevron).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BattutaSpace.lg,
          vertical: BattutaSpace.sm,
        ),
        child: Row(
          children: [
            if (leading != null || icon != null) ...[
              leading ?? Icon(icon, size: 20, color: brand.ink),
              const SizedBox(width: BattutaSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, color: brand.ink)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: brand.inkMuted),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: BattutaSpace.sm),
                  child: Text(
                    value!,
                    style: TextStyle(fontSize: 14, color: brand.inkMuted),
                  ),
                ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: BattutaSpace.xs),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: brand.inkMuted,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return BattutaPressable(
      onTap: onTap,
      pressedScale: 0.99,
      semanticLabel: label,
      child: content,
    );
  }
}

/// Large root-screen title (28pt / 800) used as an `AppBar.title` with
/// `toolbarHeight: 60`. See [StageAppBar.large].
class StageLargeTitle extends StatelessWidget {
  const StageLargeTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppTheme.primaryFontFamily,
        fontFamilyFallback: AppTheme.fontFamilyFallbacks,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: BattutaBrand.of(context).ink,
      ),
    );
  }
}

/// App bar factories matching the designs.
abstract final class StageAppBar {
  /// Root tab header: large left-aligned title, 60pt tall.
  static AppBar large({
    required String title,
    List<Widget>? actions,
    Widget? leadingMark,
  }) {
    return AppBar(
      toolbarHeight: 60,
      titleSpacing: BattutaSpace.lg,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingMark != null) ...[
            leadingMark,
            const SizedBox(width: BattutaSpace.sm),
          ],
          Flexible(child: StageLargeTitle(title)),
        ],
      ),
      actions: [
        ...?actions,
        const SizedBox(width: BattutaSpace.xs),
      ],
    );
  }
}

/// Bottom action bar from the detail designs: top hairline, 52pt buttons.
class StageActionBar extends StatelessWidget {
  const StageActionBar({required this.children, super.key});

  /// Usually one or two `Expanded` buttons; use [StageActionBar.primary] and
  /// [StageActionBar.secondary] for the designed styles.
  final List<Widget> children;

  static ButtonStyle primary() => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(
      fontFamily: AppTheme.primaryFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );

  static ButtonStyle secondary(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: brand.card,
      foregroundColor: brand.ink,
      side: BorderSide(color: brand.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: AppTheme.primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.canvas,
        border: Border(top: BorderSide(color: brand.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BattutaSpace.lg,
            BattutaSpace.md,
            BattutaSpace.lg,
            BattutaSpace.lg,
          ),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: BattutaSpace.sm),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
