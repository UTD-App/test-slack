import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/repositories/moment_repository.dart';

/// Shows the report dialog and submits the report. Returns true on success.
Future<bool> showReportMomentDialog(BuildContext context, int momentId) async {
  final repo = context.read<MomentRepository>();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ReportDialog(repo: repo, momentId: momentId),
  );
  return result ?? false;
}

class _ReportDialog extends StatefulWidget {
  final MomentRepository repo;
  final int momentId;
  const _ReportDialog({required this.repo, required this.momentId});

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
                  final res = await widget.repo
                      .reportMoment(widget.momentId, description: _desc.text.trim(), type: _type);
                  if (!context.mounted) return;
                  Navigator.pop(context, res.isSuccess);
                },
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr(MomentStrings.submit)),
        ),
      ],
    );
  }
}
