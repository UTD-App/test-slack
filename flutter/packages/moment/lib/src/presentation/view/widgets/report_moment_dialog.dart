import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/repositories/moment_repository.dart';

/// Report a moment. Returns true on success.
Future<bool> showReportMomentDialog(BuildContext context, int momentId) {
  final repo = context.read<MomentRepository>();
  return _show(
    context,
    onSubmit: (desc, type) => repo.reportMoment(momentId, description: desc, type: type).then((r) => r.isSuccess),
  );
}

/// Report a single comment (or reply). Returns true on success.
Future<bool> showReportCommentDialog(BuildContext context, int momentId, int commentId) {
  final repo = context.read<MomentRepository>();
  return _show(
    context,
    onSubmit: (desc, type) =>
        repo.reportComment(momentId, commentId, description: desc, type: type).then((r) => r.isSuccess),
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
      title: Text(context.tr(MomentStrings.reportTitle)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: context.tr(MomentStrings.reason)),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(context.tr(MomentStrings.reportTypeKey(t)))))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'spam'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.tr(MomentStrings.description), border: const OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: Text(context.tr(MomentStrings.cancel))),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  if (_desc.text.trim().isEmpty) return;
                  setState(() => _submitting = true);
                  final ok = await widget.onSubmit(_desc.text.trim(), _type);
                  if (!context.mounted) return;
                  Navigator.pop(context, ok);
                },
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr(MomentStrings.submit)),
        ),
      ],
    );
  }
}
