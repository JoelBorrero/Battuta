/// An organization's logo: its image, or a music-note tile when there is none
/// (or it cannot be loaded).
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A rounded-square logo. [logoPath] is the object path in the
/// `organization-logos` bucket; [ring] draws the amber ring of the active
/// organization.
class OrganizationLogo extends ConsumerWidget {
  const OrganizationLogo({
    this.logoPath,
    this.size = 48,
    this.ring = false,
    super.key,
  });

  final String? logoPath;
  final double size;
  final bool ring;

  /// The corner radius for a logo of [size] (14 at 48, 26 at 96).
  static double radiusFor(double size) => size * 0.28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = BattutaBrand.of(context);
    final url = ref.watch(photoUrlBuilderProvider)(
      PhotoBucket.organizationLogos,
      logoPath,
    );
    final radius = radiusFor(size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: brand.accentWash,
        border: ring ? Border.all(color: brand.accent, width: 2) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Icon(
                Icons.music_note,
                size: size * 0.48,
                color: brand.accentInk,
              ),
            ),
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
