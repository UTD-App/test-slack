import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/reels_strings.dart';

/// Small dialog to edit a reel's caption/description. Returns the new text on
/// save, or null if the user cancelled. The caller persists it via
/// `ReelsRepository.updateReel`.
Future<String?> showEditCaptionDialog(BuildContext context, String initial) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr(ReelsStrings.editCaption)),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        maxLength: 500,
        decoration: InputDecoration(hintText: ctx.tr(ReelsStrings.describeReel)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.tr(ReelsStrings.cancel)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(ctx.tr(ReelsStrings.save)),
        ),
      ],
    ),
  );
}
