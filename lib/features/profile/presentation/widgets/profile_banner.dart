/// The amber "level meter" banner at the top of my profile (drawn, not an
/// uploaded cover image).
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:flutter/material.dart';

class ProfileBanner extends StatelessWidget {
  const ProfileBanner({super.key});

  /// Bar heights from the design, left to right.
  static const List<double> barHeights = [
    34,
    62,
    46,
    88,
    54,
    72,
    40,
    96,
    58,
    30,
    66,
    48,
    80,
    36,
    60,
    92,
    44,
    70,
    52,
    28,
    64,
    84,
    42,
    58,
  ];

  static const double _barWidth = 6;
  static const double _gap = 6;
  static const double _inset = 18;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brand.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // As many bars as fit between the insets (narrow windows show
            // fewer instead of overflowing).
            final room = constraints.maxWidth - 2 * _inset + _gap;
            final count = (room / (_barWidth + _gap)).floor().clamp(
              0,
              barHeights.length,
            );
            return Padding(
              padding: const EdgeInsets.fromLTRB(_inset, 0, _inset, _inset),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      Container(
                        width: _barWidth,
                        height: barHeights[i],
                        decoration: BoxDecoration(
                          color: brand.accent.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
