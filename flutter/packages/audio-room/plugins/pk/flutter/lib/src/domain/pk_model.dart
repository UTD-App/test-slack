import 'package:equatable/equatable.dart';

class PkRtmModel extends Equatable {
  final int? timeMinutes;
  final int? timeSeconds;
  final int team1Score;
  final int team2Score;
  final double percentageTeam1;
  final double percentageTeam2;
  final int pkId;

  const PkRtmModel({
    this.timeMinutes,
    this.timeSeconds,
    this.team1Score = 0,
    this.team2Score = 0,
    this.percentageTeam1 = 0.5,
    this.percentageTeam2 = 0.5,
    this.pkId = 0,
  });

  factory PkRtmModel.fromJson(Map<String, dynamic> json) {
    return PkRtmModel(
      timeMinutes: (json['m'] as num?)?.toInt(),
      timeSeconds: (json['s'] as num?)?.toInt(),
      team1Score: (json['team1_score'] as num?)?.toInt() ?? 0,
      team2Score: (json['team2_score'] as num?)?.toInt() ?? 0,
      percentageTeam1: (json['t1_scale'] as num?)?.toDouble() ?? 0.5,
      percentageTeam2: (json['t2_scale'] as num?)?.toDouble() ?? 0.5,
      pkId: (json['id'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        team1Score,
        team2Score,
        percentageTeam1,
        percentageTeam2,
        pkId,
      ];
}

class PkTeamMemberModel extends Equatable {
  final int id;
  final String name;
  final String? uuid;

  const PkTeamMemberModel({
    required this.id,
    required this.name,
    this.uuid,
  });

  factory PkTeamMemberModel.fromJson(Map<String, dynamic> json) {
    return PkTeamMemberModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      uuid: json['uuid'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

class PkHistoryModel extends Equatable {
  final int id;
  final double t1Score;
  final double t2Score;
  final String? winner;
  final String? startAt;
  final String? endAt;
  final List<PkTeamMemberModel> team1;
  final List<PkTeamMemberModel> team2;

  const PkHistoryModel({
    required this.id,
    this.t1Score = 0,
    this.t2Score = 0,
    this.winner,
    this.startAt,
    this.endAt,
    this.team1 = const [],
    this.team2 = const [],
  });

  factory PkHistoryModel.fromJson(Map<String, dynamic> json) {
    return PkHistoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      t1Score: (json['t1_score'] as num?)?.toDouble() ?? 0,
      t2Score: (json['t2_score'] as num?)?.toDouble() ?? 0,
      winner: json['winner']?.toString(),
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      team1: (json['team_1'] as List?)
              ?.map(
                  (e) => PkTeamMemberModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      team2: (json['team_2'] as List?)
              ?.map(
                  (e) => PkTeamMemberModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id];
}
