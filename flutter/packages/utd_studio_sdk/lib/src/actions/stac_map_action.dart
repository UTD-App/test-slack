import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';

/// Base for "the JSON map IS the model" actions — no codegen needed.
///
/// Both the bundled generic actions and the host app's custom actions extend
/// this so they all dispatch from the raw action map emitted by UTD Studio.
abstract class StacMapActionParser extends StacActionParser<Map<String, dynamic>> {
  const StacMapActionParser();

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;
}

/// Reads a submitted form-field value. [model]\[key\] holds the field id
/// (the `textFormField` / `utdTextField` id); the value is read from the
/// enclosing [StacFormScope]. Returns `''` when the id is missing/empty.
String readFormField(
  BuildContext context,
  Map<String, dynamic> model,
  String key, {
  String fallback = '',
}) {
  final id = (model[key] as String?)?.trim();
  if (id == null || id.isEmpty) return '';
  final value = StacFormScope.of(context)?.formData[id];
  return (value ?? fallback).toString().trim();
}
