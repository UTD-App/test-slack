import '../../network/models/api_response.dart';
import '../../network/services/base_api_service.dart';

/// Base repository that wraps a [BaseApiService] and provides
/// a clean data-access layer for use cases.
///
/// Each feature should create its own API service (extending [BaseApiService])
/// and a repository (extending [BaseRepository]) that delegates to it.
///
/// Example:
/// ```dart
/// class AuthRepository extends BaseRepository<AuthApiService> {
///   AuthRepository(super.apiService);
///
///   Future<Result<User>> login(String email, String password) {
///     return apiService.post<User>(
///       '/auth/login',
///       data: {'email': email, 'password': password},
///       fromJson: (json) => User.fromJson(json),
///     );
///   }
/// }
/// ```
abstract class BaseRepository<T extends BaseApiService> {
  final T apiService;

  const BaseRepository(this.apiService);

  /// Helper to handle a [Result] and transform its success data.
  Future<Result<R>> handleResult<S, R>(
    Future<Result<S>> call,
    R Function(S data) transform,
  ) async {
    final result = await call;
    return result.map(transform);
  }
}
