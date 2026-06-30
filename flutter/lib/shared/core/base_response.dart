import 'package:equatable/equatable.dart';

class BaseResponse<T> extends Equatable {
  final bool? success;
  final String message;
  final PaginatesModel? paginates;
  final T? data;

  const BaseResponse({
    required this.success,
    required this.message,
    this.paginates,
    required this.data,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromJsonT,
  }) {
    dynamic data() {
      if (json['data'] == null) {
        return null;
      } else {
        final finalT = json['data'];
        return json.containsKey('data')
            ? (finalT is String || finalT is int)
                  ? finalT
                  : fromJsonT == null
                  ? null
                  : _parse(json['data'], fromJsonT)
            : null;
      }
    }

    return BaseResponse(
      // Coerce defensively: `status` may arrive as a real bool OR as 1/0
      // (some endpoints), and `message` may be absent/non-string. A raw cast
      // here turned an otherwise-good 200 into a parse failure.
      success: _asBool(json['status']) ?? _asBool(json['success']),
      message: json['message']?.toString() ?? '',
      paginates: json['paginates'] == null
          ? null
          : PaginatesModel.fromJson(json['paginates']),
      data: data(),
    );
  }

  /// Tolerant truthiness: accepts a real bool, 1/0, or "true"/"false"/"1"/"0".
  /// Returns null when the value is absent so callers can fall through.
  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return null;
  }

  static T _parse<T>(dynamic json, T Function(dynamic) fromJsonT) {
    if (json == null) {
      return null as T;
    } else if (json is T ||
        json is Map<String, dynamic> ||
        json is List<dynamic>) {
      return fromJsonT(json);
    } else {
      throw ArgumentError.value(json, 'json', 'Invalid data type');
    }
  }

  @override
  List<Object?> get props => [success, message, data];
}

class PaginatesModel extends Equatable {
  final int currentPage;
  final int lastPage;

  const PaginatesModel({this.currentPage = 0, this.lastPage = 0});

  factory PaginatesModel.fromJson(Map<String, dynamic> json) => PaginatesModel(
    currentPage: json['meta']?['current_page'] ?? 0,
    lastPage: json['meta']?['last_page'] ?? 0,
  );

  @override
  List<Object?> get props => [currentPage, lastPage];
}
