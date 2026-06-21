import 'package:dio/dio.dart';

import '../../shared/services/app_session.dart';

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
    // Account suspended (ban): the server replies 403 with a distinguishable
    // code so we don't confuse it with other 403s (e.g. a disabled package).
    // Clear the session and bounce to login.
    if (err.response?.statusCode == 403 && _isBanResponse(err.response?.data)) {
      await onLogout?.call();
      restartApp();
      handler.reject(err);
      return;
    }

    // Another device logged in with this account: CheckLatestToken middleware
    // replies 505 once a newer token exists. This session's token is now stale,
    // so clear it and bounce to login instead of leaving the user stuck on a
    // retry screen (retrying can never succeed with the invalidated token).
    if (err.response?.statusCode == 505) {
      await onLogout?.call();
      restartApp();
      handler.reject(err);
      return;
    }

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

  /// True when a 403 body carries the account-suspended marker the backend
  /// sends (GeneralBanMiddleware → data.code == 'account_suspended').
  bool _isBanResponse(dynamic body) {
    if (body is! Map) return false;
    final data = body['data'];
    final code = data is Map ? data['code'] : body['code'];
    return code == 'account_suspended';
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
