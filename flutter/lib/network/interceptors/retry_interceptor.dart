import 'package:dio/dio.dart';

/// Interceptor for retrying failed requests
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;
  final Dio dio;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const [408, 500, 502, 503, 504],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] as int? ?? 0;

    // Check if we should retry
    final shouldRetry = _shouldRetry(err, retryCount);

    if (shouldRetry) {
      // Wait before retrying
      await Future.delayed(retryDelay * (retryCount + 1));

      // Update retry count
      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with error handling if retry fails
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err, int retryCount) {
    // Don't retry if max retries reached
    if (retryCount >= maxRetries) return false;

    // Don't retry if explicitly disabled
    if (err.requestOptions.extra['disableRetry'] == true) return false;

    // Retry on connection timeout
    if (err.type == DioExceptionType.connectionTimeout) return true;

    // Retry on send timeout
    if (err.type == DioExceptionType.sendTimeout) return true;

    // Retry on receive timeout
    if (err.type == DioExceptionType.receiveTimeout) return true;

    // Retry on connection error
    if (err.type == DioExceptionType.connectionError) return true;

    // Retry on specific status codes
    final statusCode = err.response?.statusCode;
    if (statusCode != null && retryStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }
}
