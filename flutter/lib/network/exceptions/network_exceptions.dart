import 'dart:io';

import 'package:dio/dio.dart';

/// Base class for all network exceptions
sealed class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const NetworkException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'NetworkException: $message (status: $statusCode)';

  /// Returns a user-friendly error message from any error object.
  static String getErrorMessage(dynamic error) {
    if (error is NetworkException) return error.message;
    if (error is String) return error;
    return 'An unexpected error occurred';
  }

  /// Factory method to create appropriate exception from DioException
  factory NetworkException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Connection timed out. Please try again.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return NoInternetException(
          message: 'No internet connection. Please check your network.',
        );

      case DioExceptionType.badCertificate:
        return ServerException(
          message: 'Invalid certificate. Connection not secure.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return RequestCancelledException(message: 'Request was cancelled.');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NoInternetException(
            message: 'No internet connection. Please check your network.',
          );
        }
        return UnknownException(
          message: error.message ?? 'An unknown error occurred.',
          data: error.error,
        );
    }
  }

  static NetworkException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case 377:
        return BadRequestException(
          message: _extractMessage(data) ?? 'Bad request.',
          statusCode: statusCode,
          data: data,
        );
      case 400:
        return BadRequestException(
          message: _extractMessage(data) ?? 'Bad request.',
          statusCode: statusCode,
          data: data,
        );
      case 401:
        return UnauthorizedException(
          message: _extractMessage(data) ?? 'Unauthorized. Please login again.',
          statusCode: statusCode,
          data: data,
        );
      case 403:
        return ForbiddenException(
          message: _extractMessage(data) ?? 'Access denied.',
          statusCode: statusCode,
          data: data,
        );
      case 404:
        return NotFoundException(
          message: _extractMessage(data) ?? 'Resource not found.',
          statusCode: statusCode,
          data: data,
        );
      case 409:
        return ConflictException(
          message: _extractMessage(data) ?? 'Conflict occurred.',
          statusCode: statusCode,
          data: data,
        );
      case 422:
        return ValidationException(
          message: _extractMessage(data) ?? 'Validation failed.',
          statusCode: statusCode,
          data: data,
          errors: _extractValidationErrors(data),
        );
      case 429:
        return TooManyRequestsException(
          message:
              _extractMessage(data) ?? 'Too many requests. Please slow down.',
          statusCode: statusCode,
          data: data,
        );
      case 500:
      case 501:
      case 502:
      case 503:
        return ServerException(
          message:
              _extractMessage(data) ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          data: data,
        );
      case 505:
        return AnotherDeviceLoggedIn(
          message:
              _extractMessage(data) ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          data: data,
        );
      default:
        return ServerException(
          message: _extractMessage(data) ?? 'Something went wrong.',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      return data['message'] ?? data['error'] ?? data['msg'];
    }
    return null;
  }

  static Map<String, List<String>>? _extractValidationErrors(dynamic data) {
    if (data == null || data is! Map) return null;
    final errors = data['errors'];
    if (errors == null || errors is! Map) return null;

    return errors.map((key, value) {
      if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((e) => e.toString()).toList(),
        );
      }
      return MapEntry(key.toString(), [value.toString()]);
    });
  }
}

/// Exception for timeout errors
final class TimeoutException extends NetworkException {
  const TimeoutException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for no internet connection
final class NoInternetException extends NetworkException {
  const NoInternetException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for bad requests (400)
final class BadRequestException extends NetworkException {
  const BadRequestException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for unauthorized requests (401)
final class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for forbidden requests (403)
final class ForbiddenException extends NetworkException {
  const ForbiddenException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for not found errors (404)
final class NotFoundException extends NetworkException {
  const NotFoundException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for conflict errors (409)
final class ConflictException extends NetworkException {
  const ConflictException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for validation errors (422)
final class ValidationException extends NetworkException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    required super.message,
    super.statusCode,
    super.data,
    this.errors,
  });

  String? getFirstError(String field) {
    return errors?[field]?.firstOrNull;
  }

  List<String> getAllErrors() {
    if (errors == null) return [];
    return errors!.values.expand((e) => e).toList();
  }
}

/// Exception for rate limiting (429)
final class TooManyRequestsException extends NetworkException {
  const TooManyRequestsException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for server errors (5xx)
final class ServerException extends NetworkException {
  const ServerException({required super.message, super.statusCode, super.data});
}

/// Exception for server errors (5xx)
final class AnotherDeviceLoggedIn extends NetworkException {
  const AnotherDeviceLoggedIn({required super.message, super.statusCode, super.data});
}


/// Exception for cancelled requests
final class RequestCancelledException extends NetworkException {
  const RequestCancelledException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Exception for unknown errors
final class UnknownException extends NetworkException {
  const UnknownException({
    required super.message,
    super.statusCode,
    super.data,
  });
}
