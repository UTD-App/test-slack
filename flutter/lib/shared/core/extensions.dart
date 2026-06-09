import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'enums.dart';

/// Dimension helpers for creating [SizedBox] spacers and border radii.
extension DimensionsExt on num {
  SizedBox get hBox => SizedBox(height: toDouble().h);
  SizedBox get wBox => SizedBox(width: toDouble().w);
  BorderRadius get radius => BorderRadius.circular(toDouble().r);
  Radius get radiusCircular => Radius.circular(toDouble().r);
}

/// Convenience getters for [RequestState] checks.
extension RequestStateExt on RequestState {
  bool get isIdle => this == RequestState.idle;
  bool get isLoading => this == RequestState.loading;
  bool get isLoaded => this == RequestState.loaded;
  bool get isError => this == RequestState.error;
  bool get isEmpty => this == RequestState.empty;
  bool get isOffline => this == RequestState.offline;
  bool get userBan => this == RequestState.banUser;
}

/// Padding helpers on [BuildContext].
extension PaddingExt on BuildContext {
  EdgeInsetsDirectional paddingOnly({
    double end = 0,
    double top = 0,
    double start = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.only(
      end: end.w,
      top: top.h,
      start: start.w,
      bottom: bottom.h,
    );
  }

  EdgeInsetsDirectional paddingSymmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsetsDirectional.symmetric(
      horizontal: horizontal.w,
      vertical: vertical.h,
    );
  }

  EdgeInsetsDirectional paddingAll(double value) {
    return EdgeInsetsDirectional.all(value.h);
  }

  EdgeInsets paddingZero() => EdgeInsets.zero;
}

/// Text style shortcuts on [BuildContext].
extension TextStyleExtensions on BuildContext {
  TextStyle get bodySmall =>
      Theme.of(this).textTheme.bodySmall ?? const TextStyle();
  TextStyle get bodyMedium =>
      Theme.of(this).textTheme.bodyMedium ?? const TextStyle();
  TextStyle get bodyLarge =>
      Theme.of(this).textTheme.bodyLarge ?? const TextStyle();
}

/// Chained text style modifiers.
extension TextStyleModifiers on TextStyle {
  TextStyle size(double s) => copyWith(fontSize: s.sp);
  TextStyle colorExt(Color c) => copyWith(color: c);

  TextStyle get w400 => copyWith(fontWeight: FontWeight.w400);
  TextStyle get w500 => copyWith(fontWeight: FontWeight.w500);
  TextStyle get w600 => copyWith(fontWeight: FontWeight.w600);
  TextStyle get w700 => copyWith(fontWeight: FontWeight.w700);
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
}

// GoRouter re-exports its own context.go / context.push extensions.
// Import 'package:go_router/go_router.dart' to use them.

/// Allows [TextEditingController.copyWith] for immutable state patterns.
extension TextEditingControllerCopyWith on TextEditingController {
  TextEditingController copyWith({String? text}) {
    final controller = TextEditingController(text: text ?? this.text);
    return controller;
  }
}

T parseValue<T>(
  dynamic value,
  T fallback, {
  T Function(dynamic)? customParser,
}) {
  if (value == null) return fallback;

  try {
    if (value is T) return value;

    if (customParser != null) {
      final parsed = customParser(value);
      return parsed;
    }

    // Primitive types
    if (T == int) {
      return (int.tryParse(value.toString()) ?? fallback) as T;
    } else if (T == double) {
      return (double.tryParse(value.toString()) ?? fallback) as T;
    } else if (T == bool) {
      final str = value.toString().toLowerCase();
      if (str == 'true') return true as T;
      if (str == 'false') return false as T;
      return fallback;
    } else if (T == String) {
      // Return fallback if value is an empty list or empty map
      if ((value is List && value.isEmpty) || (value is Map && value.isEmpty)) {
        return fallback;
      }
      return value.toString() as T;
    }

    final jsonString = value is String ? value : jsonEncode(value);
    final decoded = jsonDecode(jsonString);

    if (T.toString() == 'List<String>') {
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList() as T;
      }
    } else if (T.toString() == 'List<int>') {
      if (decoded is List) {
        return decoded.map((e) => int.tryParse(e.toString()) ?? 0).toList()
            as T;
      }
    } else if (T.toString() == 'List<double>') {
      if (decoded is List) {
        return decoded.map((e) => double.tryParse(e.toString()) ?? 0.0).toList()
            as T;
      }
    } else if (T.toString() == 'List<bool>') {
      if (decoded is List) {
        return decoded.map((e) => e.toString().toLowerCase() == 'true').toList()
            as T;
      }
    } else if (T.toString() == 'Map<String, dynamic>') {
      if (decoded is Map<String, dynamic>) return decoded as T;
      if (decoded is Map) {
        return decoded.map((key, val) => MapEntry(key.toString(), val)) as T;
      }
    } else if (T.toString() == 'List<Map<String, dynamic>>') {
      if (decoded is Map) {
        return [decoded.map((k, v) => MapEntry(k.toString(), v))] as T;
      }
      if (decoded is List) {
        return decoded
                .whereType<Map>()
                .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                .toList()
            as T;
      }
    }

    // Custom List<TModel> handling
    if (T.toString().startsWith('List<') &&
        T.toString() != 'List<String>' &&
        T.toString() != 'List<int>' &&
        T.toString() != 'List<double>' &&
        T.toString() != 'List<bool>' &&
        T.toString() != 'List<Map<String, dynamic>>') {
      // ✅ Log for List<UserChatModel>
      if (T.toString() == 'List<UserChatModel>') {
        log('parseValue<$T>: Detected List<UserChatModel>');
      }

      if (customParser != null && decoded is List) {
        final list = decoded.map((e) => customParser(e)).toList();
        return list as T;
      }
    }
  } catch (e, s) {
    log('parseValue<$T> error: $e\n$s');
  }

  log('parseValue<$T> fallback: got ${value.runtimeType}, expected $T');
  return fallback;
}
