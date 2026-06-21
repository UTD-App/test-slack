import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/retry_interceptor.dart';

/// Configuration for the API client
class ApiClientConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final Map<String, String>? defaultHeaders;
  final bool enableLogging;
  final bool enableRetry;
  final int maxRetries;
  final GetTokenCallback? getToken;
  final TokenRefreshCallback? onTokenExpired;
  final LogoutCallback? onLogout;

  const ApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.defaultHeaders,
    this.enableLogging = true,
    this.enableRetry = true,
    this.maxRetries = 3,
    this.getToken,
    this.onTokenExpired,
    this.onLogout,
  });
}

/// Singleton API client using Dio
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  late final ApiClientConfig _config;

  ApiClient._internal();

  /// Initialize the API client with configuration
  static void initialize(ApiClientConfig config) {
    _instance = ApiClient._internal();
    _instance!._config = config;
    _instance!._setupDio();
  }

  /// Get the singleton instance
  static ApiClient get instance {
    if (_instance == null) {
      throw StateError(
        'ApiClient has not been initialized. Call ApiClient.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Get the Dio instance for advanced usage
  Dio get dio => _dio;

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        sendTimeout: _config.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ..._config.defaultHeaders ?? {},
        },
      ),
    );

    // Add retry interceptor first
    if (_config.enableRetry) {
      _dio.interceptors.add(
        RetryInterceptor(dio: _dio, maxRetries: _config.maxRetries),
      );
    }

    // Add auth interceptor
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        getToken: _config.getToken,
        onTokenExpired: _config.onTokenExpired,
        onLogout: _config.onLogout,
      ),
    );

    // Add logging interceptor in debug mode
    if (_config.enableLogging && kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Update base URL dynamically
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Add a custom interceptor
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Remove an interceptor
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// Clear all interceptors
  void clearInterceptors() {
    _dio.interceptors.clear();
  }

  /// Set default header
  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// Remove a header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }
}
