/// A bordered tile with a big number and a label (My profile stats).
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:flutter/material.dart';

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          // Long translations shrink instead of overflowing the tile.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 13, color: brand.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
