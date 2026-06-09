/// Network module for handling API requests with Dio
///
/// This module provides:
/// - [ApiClient] - Singleton Dio client with configurable interceptors
/// - [BaseApiService] - Base class for API services with error handling
/// - [NetworkException] - Sealed class hierarchy for network errors
/// - [Result] - Type-safe result wrapper for success/failure states
/// - [ConnectivityService] - Network connectivity checker
///
/// ## Quick Start
///
/// 1. Initialize the client in main.dart:
/// ```dart
/// void main() {
///   ApiClient.initialize(
///     ApiClientConfig(
///       baseUrl: 'https://api.example.com',
///       getToken: () async => storage.getToken(),
///       onTokenExpired: () async => authService.refreshToken(),
///       onLogout: () async => authService.logout(),
///     ),
///   );
///   runApp(MyApp());
/// }
/// ```
///
/// 2. Create API services by extending [BaseApiService]:
/// ```dart
/// class UserApiService extends BaseApiService {
///   Future<Result<User>> getUser(int id) async {
///     return get('/users/$id', fromJson: User.fromJson);
///   }
///
///   Future<Result<User>> createUser(UserRequest request) async {
///     return post('/users', data: request.toJson(), fromJson: User.fromJson);
///   }
/// }
/// ```
///
/// 3. Handle responses using Result:
/// ```dart
/// final result = await userApi.getUser(1);
/// result.when(
///   success: (user) => print('Got user: ${user.name}'),
///   failure: (message, statusCode) => print('Error: $message'),
/// );
/// ```
library;

// Client
export 'client/api_client.dart';

// Exceptions
export 'exceptions/network_exceptions.dart';

// Interceptors
export 'interceptors/auth_interceptor.dart';
export 'interceptors/logging_interceptor.dart';
export 'interceptors/retry_interceptor.dart';

// Models
export 'models/api_response.dart';

// Services
export 'services/base_api_service.dart';
export 'services/connectivity_service.dart';

// Re-export commonly used Dio types
export 'package:dio/dio.dart'
    show CancelToken, Options, Response, FormData, MultipartFile;
