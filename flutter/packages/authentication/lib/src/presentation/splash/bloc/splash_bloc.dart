import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  /// Returns `true` if the user has an active session.
  final bool Function() checkAuth;

  SplashBloc({required this.checkAuth}) : super(const SplashInitial()) {
    on<SplashNavigationEvent>(_navigationEvent);
  }

  void _navigationEvent(
    SplashNavigationEvent event,
    Emitter<SplashState> emit,
  ) async {
    // Reset to the initial state first so that re-entering the splash (e.g.
    // after logout) always produces a state *change*. The bloc is a singleton
    // (provided once via BlocProvider.value) and Bloc suppresses duplicate
    // consecutive states, so without this a second resolve to the same auth
    // result (e.g. unauthenticated → unauthenticated) would emit nothing, the
    // SplashPage listener would never fire, and the app would hang on splash.
    if (state is! SplashInitial) emit(const SplashInitial());
    await Future.delayed(const Duration(seconds: 3));
    if (checkAuth()) {
      emit(const SplashAuthenticated());
    } else {
      emit(const SplashUnauthenticated());
    }
  }
}
