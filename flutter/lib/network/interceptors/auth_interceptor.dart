import 'package:dio/dio.dart';

/// Callback type for token refresh
typedef TokenRefreshCallback = Future<String?> Function();

/// Callback type for getting current token
typedef GetTokenCallback = Future<String?> Function();

/// Callback type for handling logout
typedef LogoutCallback = Future<void> Function();

/// Interceptor for handling authentication tokens
class AuthInterceptor extends Interceptor {
  final GetTokenCallback? getToken;
  final TokenRefreshCallback? onTokenExpired;
  final LogoutCallback? onLogout;
  final Dio dio;

  bool _isRefreshing = false;
  final List<(RequestOptions, ErrorInterceptorHandler)> _pendingRequests = [];

  AuthInterceptor({
    required this.dio,
    this.getToken,
    this.onTokenExpired,
    this.onLogout,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for routes that don't need it
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    // Get token and add to header
    final token = await getToken?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401 && onTokenExpired != null) {
      // If already refreshing, queue the request
      if (_isRefreshing) {
        _pendingRequests.add((err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;

      try {
        // Try to refresh the token
        final newToken = await onTokenExpired!();

        if (newToken != null) {
          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);

          // Retry pending requests
          await _retryPendingRequests(newToken);
        } else {
          // Token refresh failed, logout
          await onLogout?.call();
          handler.reject(err);
          _rejectPendingRequests(err);
        }
      } catch (e) {
        // Refresh failed, logout
        await onLogout?.call();
        handler.reject(err);
        _rejectPendingRequests(err);
      } finally {
        _isRefreshing = false;
      }

      return;
    }

    handler.next(err);
  }

  Future<void> _retryPendingRequests(String token) async {
    final requests = List<(RequestOptions, ErrorInterceptorHandler)>.from(
      _pendingRequests,
    );
    _pendingRequests.clear();

    for (final (options, handler) in requests) {
      try {
        options.headers['Authorization'] = 'Bearer $token';
        final response = await dio.fetch(options);
        handler.resolve(response);
      } catch (e) {
        handler.reject(DioException(requestOptions: options, error: e));
      }
    }
  }

  void _rejectPendingRequests(DioException error) {
    for (final (options, handler) in _pendingRequests) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error.error,
          message: error.message,
          type: error.type,
        ),
      );
    }
    _pendingRequests.clear();
  }
}
