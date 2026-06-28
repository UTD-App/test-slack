import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

import '../../utils/media.dart';

/// Opens the native share sheet for a moment: its text plus the first image
/// (pulled from the shared on-disk cache, so it's instant when already seen).
/// Falls back to text-only if the image can't be fetched (e.g. offline).
Future<void> shareMoment(
  BuildContext context, {
  required String text,
  required List<String> imagePaths,
}) async {
  final caption = text.trim();

  Future<void> shareTextOnly() async {
    if (caption.isEmpty) return; // Share.share asserts non-empty text
    await Share.share(caption);
  }

  try {
    if (imagePaths.isNotEmpty) {
      final url = resolveMediaUrl(imagePaths.first);
      if (url.isNotEmpty) {
        final file = await AppCacheManager.instance.getFile(url);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: caption.isEmpty ? null : caption,
        );
        return;
      }
    }
    await shareTextOnly();
  } catch (_) {
    // Network/file failure → still let the user share the caption.
    await shareTextOnly();
  }
}
