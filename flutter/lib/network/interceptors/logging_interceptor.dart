import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor for logging network requests and responses
class LoggingInterceptor extends Interceptor {
  final bool logRequestHeaders;
  final bool logResponseHeaders;
  final bool logRequestBody;
  final bool logResponseBody;

  LoggingInterceptor({
    this.logRequestHeaders = true,
    this.logResponseHeaders = false,
    this.logRequestBody = true,
    this.logResponseBody = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln(
        '┌───────────────────────────────────────────────────────',
      );
      buffer.writeln('│ 🌐 REQUEST: ${options.method} ${options.uri}');
      buffer.writeln(
        '├───────────────────────────────────────────────────────',
      );

      if (logRequestHeaders && options.headers.isNotEmpty) {
        buffer.writeln('│ Headers:');
        options.headers.forEach((key, value) {
          if (key.toLowerCase() != 'authorization') {
            buffer.writeln('│   $key: $value');
          } else {
            buffer.writeln('│   $key: [REDACTED]');
          }
        });
      }

      if (logRequestBody && options.data != null) {
        buffer.writeln('│ Body: ${_truncateData(options.data)}');
      }

      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('│ Query: ${options.queryParameters}');
      }

      buffer.writeln(
        '└───────────────────────────────────────────────────────',
      );
      developer.log(buffer.toString(), name: 'HTTP');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln(
        '┌───────────────────────────────────────────────────────',
      );
      buffer.writeln(
        '│ ✅ RESPONSE: ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
      buffer.writeln(
        '├───────────────────────────────────────────────────────',
      );

      if (logResponseHeaders && response.headers.map.isNotEmpty) {
        buffer.writeln('│ Headers:');
        response.headers.map.forEach((key, value) {
          buffer.writeln('│   $key: ${value.join(', ')}');
        });
      }

      if (logResponseBody && response.data != null) {
        buffer.writeln('│ Body: ${_truncateData(response.data)}');
      }

      buffer.writeln(
        '└───────────────────────────────────────────────────────',
      );
      developer.log(buffer.toString(), name: 'HTTP');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln(
        '┌───────────────────────────────────────────────────────',
      );
      buffer.writeln(
        '│ ❌ ERROR: ${err.response?.statusCode ?? 'N/A'} ${err.requestOptions.method} ${err.requestOptions.uri}',
      );
      buffer.writeln(
        '├───────────────────────────────────────────────────────',
      );
      buffer.writeln('│ Type: ${err.type}');
      buffer.writeln('│ Message: ${err.message}');

      if (err.response?.data != null) {
        buffer.writeln('│ Response: ${_truncateData(err.response?.data)}');
      }

      buffer.writeln(
        '└───────────────────────────────────────────────────────',
      );
      developer.log(buffer.toString(), name: 'HTTP');
    }

    handler.next(err);
  }

  String _truncateData(dynamic data, {int maxLength = 500}) {
    final str = data.toString();
    if (str.length > maxLength) {
      return '${str.substring(0, maxLength)}... [TRUNCATED]';
    }
    return str;
  }
}
