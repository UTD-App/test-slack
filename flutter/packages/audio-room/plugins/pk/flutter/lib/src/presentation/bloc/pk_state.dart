part of 'pk_bloc.dart';

class PkState extends Equatable {
  final RequestState showState;
  final RequestState startState;
  final RequestState closeState;
  final RequestState hideState;
  final RequestState historyState;
  final int? pkId;
  final Map<String, dynamic>? closeData;
  final List<PkHistoryModel> history;
  final String? message;

  const PkState({
    this.showState = RequestState.idle,
    this.startState = RequestState.idle,
    this.closeState = RequestState.idle,
    this.hideState = RequestState.idle,
    this.historyState = RequestState.idle,
    this.pkId,
    this.closeData,
    this.history = const [],
    this.message,
  });

  PkState copyWith({
    RequestState? showState,
    RequestState? startState,
    RequestState? closeState,
    RequestState? hideState,
    RequestState? historyState,
    int? pkId,
    Map<String, dynamic>? closeData,
    List<PkHistoryModel>? history,
    String? message,
  }) {
    return PkState(
      showState: showState ?? this.showState,
      startState: startState ?? this.startState,
      closeState: closeState ?? this.closeState,
      hideState: hideState ?? this.hideState,
      historyState: historyState ?? this.historyState,
      pkId: pkId ?? this.pkId,
      closeData: closeData ?? this.closeData,
      history: history ?? this.history,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        showState,
        startState,
        closeState,
        hideState,
        historyState,
        pkId,
        closeData,
        history,
        message,
      ];
}
