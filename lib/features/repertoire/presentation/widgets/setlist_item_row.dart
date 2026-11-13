/// One song of a setlist, drawn as a slice of the bordered "Order" card.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A row of the setlist's order card: mono position number, title, meta line
/// (+ note line), key pill and, when the setlist is editable, remove button and
/// drag handle.
///
/// Rows are stacked without gaps; [isFirst] / [isLast] round the card's top and
/// bottom corners and draw its outer border, every other row only adds a
/// hairline at its top.
class SetlistItemRow extends StatelessWidget {
  const SetlistItemRow({
    required this.number,
    required this.title,
    required this.isFirst,
    required this.isLast,
    super.key,
    this.meta,
    this.note,
    this.musicalKey,
    this.onTap,
    this.onRemove,
    this.removeTooltip,
    this.dragHandle,
  });

  /// 1-based position in the setlist.
  final int number;
  final String title;

  /// Muted "artist · BPM" line.
  final String? meta;

  /// Rehearsal note of the item, shown under the meta line.
  final String? note;

  /// Performance key (the transposed key when the item overrides it).
  final String? musicalKey;
  final VoidCallback? onTap;

  /// Shown only when non-null (editable setlists).
  final VoidCallback? onRemove;
  final String? removeTooltip;

  /// Drag handle for editable setlists, already wrapped in a drag listener.
  final Widget? dragHandle;

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);

    return CustomPaint(
      painter: _SliceBorderPainter(
        fill: brand.card,
        border: brand.border,
        isFirst: isFirst,
        isLast: isLast,
        radius: BattutaRadius.md,
      ),
      child: BattutaPressable(
        onTap: onTap,
        pressedScale: 0.995,
        haptic: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: BattutaSpace.md + 2,
              end: BattutaSpace.xs,
              top: isFirst ? 1 : 0,
              bottom: isLast ? 1 : 0,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '$number',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      fontFamilyFallback: AppTheme.monoFontFallbacks,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: brand.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: BattutaSpace.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: BattutaSpace.sm + 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: brand.ink,
                          ),
                        ),
                        if (meta != null && meta!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              meta!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: brand.inkMuted,
                              ),
                            ),
                          ),
                        if (note != null && note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: brand.accentInk,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (musicalKey != null && musicalKey!.isNotEmpty) ...[
                  const SizedBox(width: BattutaSpace.sm),
                  StageKeyPill(musicalKey!),
                ],
                if (onRemove != null)
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: BattutaSpace.minTouchTarget,
                      minHeight: BattutaSpace.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      size: 20,
                      color: brand.inkMuted,
                    ),
                    tooltip: removeTooltip,
                    onPressed: onRemove,
                  ),
                ?dragHandle,
                if (dragHandle == null && onRemove == null)
                  const SizedBox(width: BattutaSpace.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a horizontal slice of a rounded, bordered card: the fill, the left /
/// right edges, the rounded top (first) or bottom (last) edge and, for every
/// row but the first, a hairline divider on top.
class _SliceBorderPainter extends CustomPainter {
  const _SliceBorderPainter({
    required this.fill,
    required this.border,
    required this.isFirst,
    required this.isLast,
    required this.radius,
  });

  final Color fill;
  final Color border;
  final bool isFirst;
  final bool isLast;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final topRadius = isFirst ? Radius.circular(radius) : Radius.zero;
    final bottomRadius = isLast ? Radius.circular(radius) : Radius.zero;

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        w,
        h,
        topLeft: topRadius,
        topRight: topRadius,
        bottomLeft: bottomRadius,
        bottomRight: bottomRadius,
      ),
      Paint()..color = fill,
    );

    final stroke = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const o = 0.5;
    final r = radius;
    final path = Path();
    // Left edge, bottom to top.
    if (isLast) {
      path.moveTo(o + r, h - o);
      path.arcToPoint(
        Offset(o, h - o - r),
        radius: Radius.circular(r),
        clockwise: true,
      );
    } else {
      path.moveTo(o, h);
    }
    if (isFirst) {
      path.lineTo(o, o + r);
      path.arcToPoint(
        Offset(o + r, o),
        radius: Radius.circular(r),
        clockwise: true,
      );
      path.lineTo(w - o - r, o);
      path.arcToPoint(
        Offset(w - o, o + r),
        radius: Radius.circular(r),
        clockwise: true,
      );
    } else {
      path.lineTo(o, 0);
      path.moveTo(w - o, 0);
    }
    // Right edge, top to bottom.
    if (isLast) {
      path.lineTo(w - o, h - o - r);
      path.arcToPoint(
        Offset(w - o - r, h - o),
        radius: Radius.circular(r),
        clockwise: true,
      );
      path.lineTo(o + r, h - o);
    } else {
      path.lineTo(w - o, h);
    }
    canvas.drawPath(path, stroke);

    if (!isFirst) {
      canvas.drawLine(const Offset(o, o), Offset(w - o, o), stroke);
    }
  }

  @override
  bool shouldRepaint(_SliceBorderPainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.radius != radius;
}
