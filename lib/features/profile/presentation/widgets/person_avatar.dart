/// A person's avatar: their photo, or their initials when there is none (or it
/// cannot be loaded).
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Up to two initials of [name] (first letters of its first two words), or
/// `?` when there is none.
String initialsOf(String name) {
  final letters = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();
  return letters.isEmpty ? '?' : letters;
}

/// A round avatar.
///
/// * [avatarPath] is the object path in the `avatars` bucket; without it, or
///   when the image fails to load, the initials of [name] show (a person icon
///   when [name] is `null`).
/// * [ring] draws the amber ring used for the signed-in user and admins.
/// * [deactivated] greys the avatar out and never shows a photo.
class PersonAvatar extends ConsumerWidget {
  const PersonAvatar({
    this.name,
    this.avatarPath,
    this.size = 40,
    this.ring = false,
    this.deactivated = false,
    super.key,
  });

  final String? name;
  final String? avatarPath;
  final double size;
  final bool ring;
  final bool deactivated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = BattutaBrand.of(context);
    final name = this.name;
    final url = deactivated
        ? null
        : ref.watch(photoUrlBuilderProvider)(PhotoBucket.avatars, avatarPath);
    final ink = deactivated ? brand.inkMuted : brand.ink;
    final borderWidth = ring ? (size >= 48 ? 2.0 : 1.5) : 0.0;

    final placeholder = Center(
      child: name == null
          ? Icon(Icons.person_outline, size: size * 0.6, color: ink)
          : Text(
              initialsOf(name),
              maxLines: 1,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: deactivated ? brand.card : brand.cardRaised,
        border: ring
            ? Border.all(color: brand.accent, width: borderWidth)
            : (deactivated ? Border.all(color: brand.border) : null),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // A missing or unreachable image leaves the initials visible.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
