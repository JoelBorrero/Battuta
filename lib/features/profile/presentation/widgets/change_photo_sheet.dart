/// The "Change photo" bottom sheet shared by my profile photo and an
/// organization's logo: pick from the camera or the library, crop, preview,
/// save, or remove the current one.
library;

import 'dart:typed_data';

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/core/services/profile_image_picker.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// What the sheet did when it closed.
enum PhotoSheetResult { saved, removed }

/// Opens the sheet. [onSave] uploads the chosen JPEG, [onRemove] clears the
/// current photo; both return the failure to show, and the sheet only closes
/// (with the result) on success. [currentPath] is the stored object path in
/// [bucket], if there is a photo. Resolves to `null` when nothing changed.
Future<PhotoSheetResult?> showChangePhotoSheet(
  BuildContext context, {
  required PhotoShape shape,
  required PhotoBucket bucket,
  required String title,
  required String subtitle,
  required String? currentPath,
  required Future<Either<Failure, Unit>> Function(Uint8List jpeg) onSave,
  required Future<Either<Failure, Unit>> Function() onRemove,
}) {
  final brand = BattutaBrand.of(context);
  return showModalBottomSheet<PhotoSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: brand.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(color: brand.border),
    ),
    builder: (_) => ChangePhotoSheet(
      shape: shape,
      bucket: bucket,
      title: title,
      subtitle: subtitle,
      currentPath: currentPath,
      onSave: onSave,
      onRemove: onRemove,
    ),
  );
}

class ChangePhotoSheet extends ConsumerStatefulWidget {
  const ChangePhotoSheet({
    required this.shape,
    required this.bucket,
    required this.title,
    required this.subtitle,
    required this.currentPath,
    required this.onSave,
    required this.onRemove,
    super.key,
  });

  final PhotoShape shape;
  final PhotoBucket bucket;
  final String title;
  final String subtitle;
  final String? currentPath;
  final Future<Either<Failure, Unit>> Function(Uint8List jpeg) onSave;
  final Future<Either<Failure, Unit>> Function() onRemove;

  @override
  ConsumerState<ChangePhotoSheet> createState() => _ChangePhotoSheetState();
}

class _ChangePhotoSheetState extends ConsumerState<ChangePhotoSheet> {
  Uint8List? _picked;
  bool _picking = false;
  bool _saving = false;
  bool _removing = false;
  String? _error;

  bool get _busy => _picking || _saving || _removing;

  Future<void> _pick(PhotoSource source) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final bytes = await ref
          .read(profileImagePickerProvider)
          .pick(
            source,
            shape: widget.shape,
            cropTitle: AppLocalizations.of(context)?.photoCropTitle,
          );
      if (!mounted) return;
      setState(() {
        _picking = false;
        // A cancelled pick or crop keeps whatever was chosen before.
        if (bytes != null) _picked = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = l10n.photoPickFailed;
      });
    }
  }

  Future<void> _run(
    Future<Either<Failure, Unit>> Function() action, {
    required bool removing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = !removing;
      _removing = removing;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _removing = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) => Navigator.of(context)
          .pop(removing ? PhotoSheetResult.removed : PhotoSheetResult.saved),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final circle = widget.shape == PhotoShape.circle;
    final currentUrl = ref.watch(photoUrlBuilderProvider)(
      widget.bucket,
      widget.currentPath,
    );

    // While saving or removing, the sheet stays open so its result (or
    // error) is not lost.
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: brand.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: brand.inkMuted),
              ),
              const SizedBox(height: 20),
              Center(
                child: _CropGuide(
                  circle: circle,
                  picked: _picked,
                  currentUrl: currentUrl,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                circle ? l10n.photoSheetHintCircle : l10n.photoSheetHintSquare,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: brand.inkDim),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  key: const ValueKey('photo_sheet_error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      key: const ValueKey('photo_take_btn'),
                      icon: Icons.photo_camera_outlined,
                      label: l10n.photoTakeAction,
                      onPressed: _busy ? null : () => _pick(PhotoSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SourceButton(
                      key: const ValueKey('photo_choose_btn'),
                      icon: Icons.photo_library_outlined,
                      label: l10n.photoChooseAction,
                      onPressed: _busy
                          ? null
                          : () => _pick(PhotoSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('photo_save_btn'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _busy || _picked == null
                    ? null
                    : () =>
                          _run(() => widget.onSave(_picked!), removing: false),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(l10n.photoSaveAction),
              ),
              if (widget.currentPath != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('photo_remove_btn'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: theme.colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy
                      ? null
                      : () => _run(widget.onRemove, removing: true),
                  child: _removing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(l10n.photoRemoveAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The 236 px preview with a rule-of-thirds grid and the amber crop guide:
/// a circle for people, a rounded square for logos.
class _CropGuide extends StatelessWidget {
  const _CropGuide({
    required this.circle,
    required this.picked,
    required this.currentUrl,
  });

  final bool circle;
  final Uint8List? picked;
  final String? currentUrl;

  static const double _outer = 236;
  static const double _inner = 196;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final gridColor = Colors.white.withValues(alpha: 0.12);
    final radius = circle
        ? BorderRadius.circular(_inner / 2)
        : BorderRadius.circular(_inner * 0.28);

    final Widget? image = picked != null
        ? Image.memory(picked!, fit: BoxFit.cover, gaplessPlayback: true)
        : currentUrl != null
        ? Image.network(
            currentUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : null;

    return Container(
      key: const ValueKey('photo_preview'),
      width: _outer,
      height: _outer,
      decoration: BoxDecoration(
        color: brand.isDark ? brand.canvas : const Color(0xFF1A1C20),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(gridColor))),
          Container(
            width: _inner,
            height: _inner,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: brand.cardRaised,
              border: Border.all(color: brand.accent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Icon(
                      circle ? Icons.person_outline : Icons.music_note,
                      size: 96,
                      color: brand.inkDim,
                    ),
                  ),
                  ?image,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(88),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: brand.cardRaised,
        foregroundColor: brand.ink,
        side: BorderSide(color: brand.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
