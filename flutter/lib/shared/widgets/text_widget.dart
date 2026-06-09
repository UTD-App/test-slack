import 'package:flutter/material.dart';

/// A convenience wrapper around [Text] that supports optional padding.
class TextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final EdgeInsetsGeometry? padding;

  const TextWidget(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (padding != null) {
      return Padding(padding: padding!, child: child);
    }
    return child;
  }
}
