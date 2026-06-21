part of 'blacklist_bloc.dart';

class BlacklistState extends Equatable {
  final List<BlacklistEntryModel> blacklist;
  final RequestState blacklistState;
  final String? message;

  const BlacklistState({
    this.blacklist = const [],
    this.blacklistState = RequestState.idle,
    this.message,
  });

  BlacklistState copyWith({
    List<BlacklistEntryModel>? blacklist,
    RequestState? blacklistState,
    String? message,
  }) {
    return BlacklistState(
      blacklist: blacklist ?? this.blacklist,
      blacklistState: blacklistState ?? this.blacklistState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [blacklist, blacklistState, message];
}
