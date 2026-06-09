import 'package:flutter/material.dart';

/// A simple text button wrapper.
class TextButtonWidget extends StatelessWidget {
  final VoidCallback onTap;
  final Widget content;

  const TextButtonWidget({
    super.key,
    required this.onTap,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: content,
    );
  }
}
