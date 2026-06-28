import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/reels_strings.dart';
import '../../../domain/repositories/reels_repository.dart';

/// Report a reel. Returns true on success.
Future<bool> showReportReelDialog(BuildContext context, int reelId) {
  final repo = context.read<ReelsRepository>();
  return _show(
    context,
    onSubmit: (desc, type) => repo.reportReel(reelId, description: desc, type: type).then((r) => r.isSuccess),
  );
}

/// Report a single comment (or reply). Returns true on success.
Future<bool> showReportCommentDialog(BuildContext context, int reelId, int commentId) {
  final repo = context.read<ReelsRepository>();
  return _show(
    context,
    onSubmit: (desc, type) =>
        repo.reportComment(reelId, commentId, description: desc, type: type).then((r) => r.isSuccess),
  );
}

Future<bool> _show(BuildContext context, {required Future<bool> Function(String desc, String type) onSubmit}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ReportDialog(onSubmit: onSubmit),
  );
  return result ?? false;
}

class _ReportDialog extends StatefulWidget {
  final Future<bool> Function(String desc, String type) onSubmit;
  const _ReportDialog({required this.onSubmit});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _desc = TextEditingController();
  String _type = 'spam';
  bool _submitting = false;

  static const _types = ['spam', 'abuse', 'nudity', 'violence', 'other'];

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr(ReelsStrings.reportTitle)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: context.tr(ReelsStrings.reason)),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(context.tr(ReelsStrings.reportTypeKey(t)))))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'spam'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.tr(ReelsStrings.description), border: const OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: Text(context.tr(ReelsStrings.cancel))),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  // Description is optional in the UI; the backend requires a
                  // non-empty one, so fall back to the chosen reason's label.
                  final desc = _desc.text.trim().isEmpty
                      ? context.tr(ReelsStrings.reportTypeKey(_type))
                      : _desc.text.trim();
                  final ok = await widget.onSubmit(desc, _type);
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    // Keep the dialog open and tell the user instead of failing silently.
                    setState(() => _submitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr(ReelsStrings.somethingWrong))),
                    );
                  }
                },
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr(ReelsStrings.submit)),
        ),
      ],
    );
  }
}
