import 'package:dio/dio.dart';

import '../client/api_client.dart';
import '../exceptions/network_exceptions.dart';
import '../models/api_response.dart';

/// Base API service with common HTTP methods and error handling
abstract class BaseApiService {
  /// The Dio instance from ApiClient
  Dio get dio => ApiClient.instance.dio;

  /// Perform a GET request
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      () => dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a POST request
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      () => dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a PUT request
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      () => dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a PATCH request
  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      () => dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a DELETE request
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      () => dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Upload a file with progress tracking
  Future<Result<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? additionalFields,
    T Function(dynamic)? fromJson,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?additionalFields,
    });

    return _executeRequest(
      () => dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Upload multiple files with progress tracking
  Future<Result<T>> uploadFiles<T>(
    String path, {
    required Map<String, String> files, // fieldName -> filePath
    Map<String, dynamic>? additionalFields,
    T Function(dynamic)? fromJson,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final fileEntries = await Future.wait(
      files.entries.map((e) async {
        return MapEntry(e.key, await MultipartFile.fromFile(e.value));
      }),
    );

    final formData = FormData.fromMap({
      ...Map.fromEntries(fileEntries),
      ...?additionalFields,
    });

    return _executeRequest(
      () => dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Download a file with progress tracking
  Future<Result<void>> downloadFile(
    String urlPath,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      final exception = NetworkException.fromDioException(e);
      return Result.failure(
        exception.message,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Execute request with error handling
  Future<Result<T>> _executeRequest<T>(
    Future<Response> Function() request, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await request();
      final data = response.data;

      if (fromJson != null && data != null) {
        return Result.success(fromJson(data));
      }

      // If no parser provided, try to return data as T
      if (data is T) {
        return Result.success(data);
      }

      return Result.success(data as T);
    } on DioException catch (e) {
      final exception = NetworkException.fromDioException(e);
      return Result.failure(
        exception.message,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Execute request and throw on error (for cases where you want to handle exceptions manually)
  Future<T> executeOrThrow<T>(
    Future<Response> Function() request, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await request();
      final data = response.data;

      if (fromJson != null && data != null) {
        return fromJson(data);
      }

      return data as T;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }
}
