part of 'room_cup_bloc.dart';

class RoomCupState extends Equatable {
  final dynamic myReward;
  final dynamic history;
  final dynamic cupTargets;
  final RequestState myRewardState;
  final RequestState historyState;
  final RequestState cupTargetsState;
  final String? message;

  const RoomCupState({
    this.myReward,
    this.history,
    this.cupTargets,
    this.myRewardState = RequestState.idle,
    this.historyState = RequestState.idle,
    this.cupTargetsState = RequestState.idle,
    this.message,
  });

  RoomCupState copyWith({
    dynamic myReward,
    dynamic history,
    dynamic cupTargets,
    RequestState? myRewardState,
    RequestState? historyState,
    RequestState? cupTargetsState,
    String? message,
  }) {
    return RoomCupState(
      myReward: myReward ?? this.myReward,
      history: history ?? this.history,
      cupTargets: cupTargets ?? this.cupTargets,
      myRewardState: myRewardState ?? this.myRewardState,
      historyState: historyState ?? this.historyState,
      cupTargetsState: cupTargetsState ?? this.cupTargetsState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        myReward,
        history,
        cupTargets,
        myRewardState,
        historyState,
        cupTargetsState,
        message,
      ];
}
