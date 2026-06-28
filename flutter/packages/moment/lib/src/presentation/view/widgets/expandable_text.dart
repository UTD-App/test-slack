import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/moment_strings.dart';

/// Post text that clamps to [trimLines] lines with an inline "See more" / "See
/// less" toggle when it overflows. Short text renders plainly (no toggle).
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int trimLines;

  const ExpandableText(
    this.text, {
    super.key,
    this.style,
    this.trimLines = 4,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final accent = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.trimLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        if (!tp.didExceedMaxLines) {
          return Text(widget.text, style: style);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : widget.trimLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                context.tr(_expanded ? MomentStrings.less : MomentStrings.more),
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
