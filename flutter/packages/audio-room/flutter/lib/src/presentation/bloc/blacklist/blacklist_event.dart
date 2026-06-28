part of 'blacklist_bloc.dart';

sealed class BlacklistEvent extends Equatable {
  const BlacklistEvent();

  @override
  List<Object?> get props => [];
}

class LoadBlacklistEvent extends BlacklistEvent {
  final int roomId;

  const LoadBlacklistEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class BanUserEvent extends BlacklistEvent {
  final int roomId;
  final int userId;

  /// Seconds until the ban expires; `null` = permanent.
  final int? durationSeconds;
  final String? reason;

  const BanUserEvent({
    required this.roomId,
    required this.userId,
    this.durationSeconds,
    this.reason,
  });

  @override
  List<Object?> get props => [roomId, userId, durationSeconds, reason];
}

class KickUserEvent extends BlacklistEvent {
  final int roomId;
  final int userId;
  final int minutes;

  const KickUserEvent({
    required this.roomId,
    required this.userId,
    this.minutes = 5,
  });

  @override
  List<Object?> get props => [roomId, userId, minutes];
}

class UnbanUserEvent extends BlacklistEvent {
  final int roomId;
  final int userId;

  const UnbanUserEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}

class MuteWritingEvent extends BlacklistEvent {
  final int roomId;
  final int userId;

  const MuteWritingEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}

class UnmuteWritingEvent extends BlacklistEvent {
  final int roomId;
  final int userId;

  const UnmuteWritingEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}
