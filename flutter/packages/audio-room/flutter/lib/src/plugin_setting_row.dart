import 'package:flutter/material.dart';

enum PluginSettingType { toggle, action }

class PluginSettingRow {
  final String title;
  final PluginSettingType type;
  final bool? currentValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final bool isLoading;

  const PluginSettingRow({
    required this.title,
    required this.type,
    this.currentValue,
    this.onToggle,
    this.onTap,
    this.isLoading = false,
  });
}
