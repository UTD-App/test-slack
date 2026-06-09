import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  /// Resolves the first route to enter (home / landing / login). The decision
  /// (session? first run?) lives at the call site so this bloc stays dumb.
  final String Function() resolveStart;

  SplashBloc({required this.resolveStart}) : super(const SplashInitial()) {
    on<SplashNavigationEvent>(_navigationEvent);
  }

  void _navigationEvent(
    SplashNavigationEvent event,
    Emitter<SplashState> emit,
  ) async {
    await Future.delayed(const Duration(seconds: 3));
    emit(SplashResolved(resolveStart()));
  }
}
