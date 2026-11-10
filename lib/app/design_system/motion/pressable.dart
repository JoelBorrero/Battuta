/// Battuta — Tactile press feedback.
///
/// Replaces Material ink ripples (disabled app-wide) with a physical,
/// stage-hardware feel: the surface dips slightly on touch-down and springs
/// back on release, like a well-damped footswitch.
library;

import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] with scale-on-press feedback, focus/keyboard activation and
/// button semantics.
///
/// [builder] variant receives the pressed state so the child can also tint
/// itself (e.g. swap to a raised surface color).
class BattutaPressable extends StatefulWidget {
  const BattutaPressable({
    required this.onTap,
    this.child,
    this.builder,
    this.onLongPress,
    this.pressedScale = 0.975,
    this.haptic = true,
    this.semanticLabel,
    super.key,
  }) : assert(child != null || builder != null);

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? child;
  final Widget Function(BuildContext context, bool pressed)? builder;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<BattutaPressable> createState() => _BattutaPressableState();
}

class _BattutaPressableState extends State<BattutaPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    if (widget.onTap == null) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final content = widget.builder?.call(context, _pressed) ?? widget.child!;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: enabled ? _activate : null,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _pressed ? widget.pressedScale : 1,
            duration: BattutaMotion.resolve(context, BattutaMotion.tick),
            curve: _pressed ? BattutaMotion.downbeat : BattutaMotion.rebound,
            child: content,
          ),
        ),
      ),
    );
  }
}
