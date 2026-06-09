/// Generic API response wrapper that can handle both success and error states
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    this.data,
    this.message,
    this.success = true,
    this.statusCode,
    this.meta,
  });

  /// Create a successful response
  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse(
      data: data,
      message: message,
      success: true,
      statusCode: statusCode,
      meta: meta,
    );
  }

  /// Create an error response
  factory ApiResponse.error({
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse(
      message: message,
      success: false,
      statusCode: statusCode,
      meta: meta,
    );
  }

  /// Parse API response from JSON with a custom parser
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromJsonT,
  }) {
    final success = json['success'] as bool? ?? true;
    final message = json['message'] as String?;
    final statusCode = json['status_code'] as int?;
    final meta = json['meta'] as Map<String, dynamic>?;

    T? data;
    if (fromJsonT != null && json['data'] != null) {
      data = fromJsonT(json['data']);
    }

    return ApiResponse(
      data: data,
      message: message,
      success: success,
      statusCode: statusCode,
      meta: meta,
    );
  }

  /// Check if response has data
  bool get hasData => data != null;

  /// Check if response is an error
  bool get isError => !success;

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, hasData: $hasData)';
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMorePages;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  }) : hasMorePages = currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] as List? ?? [];
    final items = data
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse(
      items: items,
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? items.length,
      total: json['total'] as int? ?? items.length,
    );
  }

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage >= lastPage;

  /// Get the next page number
  int? get nextPage => hasMorePages ? currentPage + 1 : null;

  /// Get the previous page number
  int? get previousPage => currentPage > 1 ? currentPage - 1 : null;

  @override
  String toString() =>
      'PaginatedResponse(page: $currentPage/$lastPage, items: ${items.length}, total: $total)';
}

/// Result type for handling success/failure states
sealed class Result<T> {
  const Result();

  /// Create a success result
  factory Result.success(T data) = Success<T>;

  /// Create a failure result
  factory Result.failure(String message, {int? statusCode}) = Failure<T>;

  /// Map the result to another type
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success(data: final data) => Result.success(transform(data)),
      Failure(message: final msg, statusCode: final code) => Result.failure(
        msg,
        statusCode: code,
      ),
    };
  }

  /// Get the data or null
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  /// Get the data or throw
  T get dataOrThrow => switch (this) {
    Success(data: final data) => data,
    Failure(message: final msg) => throw Exception(msg),
  };

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Execute callback based on result type
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    return switch (this) {
      Success(data: final data) => success(data),
      Failure(message: final msg, statusCode: final code) => failure(msg, code),
    };
  }

  /// Either-style fold: [onFailure] receives the failure, [onSuccess] the data.
  R fold<R>(
    R Function(String message) onFailure,
    R Function(T data) onSuccess,
  ) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Failure(message: final msg) => onFailure(msg),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

final class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});

  @override
  String toString() => 'Failure($message, statusCode: $statusCode)';
}
