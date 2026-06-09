import '../../network/models/api_response.dart';

/// Base use case for operations that take parameters.
///
/// Each use case represents a single action in the business logic layer.
/// It takes [Params] as input and returns [Result<Type>].
///
/// Example:
/// ```dart
/// class LoginUseCase extends UseCase<User, LoginParams> { // T=User, Params=LoginParams
///   final AuthRepository _repository;
///
///   LoginUseCase(this._repository);
///
///   @override
///   Future<Result<User>> call(LoginParams params) {
///     return _repository.login(params.email, params.password);
///   }
/// }
///
/// class LoginParams {
///   final String email;
///   final String password;
///
///   const LoginParams({required this.email, required this.password});
/// }
/// ```
abstract class UseCase<T, Params> {
  const UseCase();

  Future<Result<T>> call(Params params);
}

/// Base use case for operations that take no parameters.
///
/// Example:
/// ```dart
/// class GetCurrentUserUseCase extends NoParamsUseCase<User> {
///   final AuthRepository _repository;
///
///   GetCurrentUserUseCase(this._repository);
///
///   @override
///   Future<Result<User>> call() {
///     return _repository.getCurrentUser();
///   }
/// }
/// ```
abstract class NoParamsUseCase<T> {
  const NoParamsUseCase();

  Future<Result<T>> call();
}
