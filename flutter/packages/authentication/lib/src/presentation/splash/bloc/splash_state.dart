part of 'splash_bloc.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

final class SplashInitial extends SplashState {
  const SplashInitial();
}

/// The splash finished and resolved which route to enter first (home / landing
/// / login), per the active [AppFlow].
final class SplashResolved extends SplashState {
  final String route;
  const SplashResolved(this.route);

  @override
  List<Object?> get props => [route];
}
