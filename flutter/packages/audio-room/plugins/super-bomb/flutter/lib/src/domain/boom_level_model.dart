import 'package:equatable/equatable.dart';

class BoomLevelModel extends Equatable {
  final int id;
  final int level;
  final int minTarget;
  final int target;
  final String? video;
  final String? imageType;
  final List<RoomBoomModel> roomBooms;
  final List<BoomRewardModel> rewards;

  const BoomLevelModel({
    required this.id,
    required this.level,
    required this.minTarget,
    required this.target,
    this.video,
    this.imageType,
    this.roomBooms = const [],
    this.rewards = const [],
  });

  factory BoomLevelModel.fromJson(Map<String, dynamic> json) {
    return BoomLevelModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      minTarget: (json['min_target'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      video: json['video'] as String?,
      imageType: json['image_type'] as String?,
      roomBooms: (json['room_booms'] as List?)
              ?.map((e) => RoomBoomModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rewards: (json['rewards'] as List?)
              ?.map((e) => BoomRewardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id];
}

class BoomRewardModel extends Equatable {
  final int id;
  final int priority;
  final String type;
  final String image;
  final String giftImageType;
  final String title;
  final int count;
  final int price;

  const BoomRewardModel({
    required this.id,
    required this.priority,
    required this.type,
    required this.image,
    required this.giftImageType,
    required this.title,
    required this.count,
    required this.price,
  });

  factory BoomRewardModel.fromJson(Map<String, dynamic> json) {
    return BoomRewardModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      image: json['image'] as String? ?? '',
      giftImageType: json['gift_image_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id];
}

class RoomBoomModel extends Equatable {
  final int id;
  final String startedAt;
  final String? endedAt;
  final String totalGiftsValue;
  final int? level;
  final List<TopContributorModel> topContributors;

  const RoomBoomModel({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.totalGiftsValue,
    this.level,
    this.topContributors = const [],
  });

  factory RoomBoomModel.fromJson(Map<String, dynamic> json) {
    return RoomBoomModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      startedAt: json['started_at'] as String? ?? '',
      endedAt: json['ended_at'] as String?,
      totalGiftsValue: json['total_gifts_value']?.toString() ?? '0',
      level: (json['level'] as num?)?.toInt(),
      topContributors: (json['top_contributors'] as List?)
              ?.map((e) =>
                  TopContributorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id];
}

class TopContributorModel extends Equatable {
  final int id;
  final String name;
  final String img;
  final String totalGift;
  final String? uuid;

  const TopContributorModel({
    required this.id,
    required this.name,
    required this.img,
    required this.totalGift,
    this.uuid,
  });

  factory TopContributorModel.fromJson(Map<String, dynamic> json) {
    return TopContributorModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      img: json['img'] as String? ?? '',
      totalGift: json['total_gift']?.toString() ?? '0',
      uuid: json['uuid'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}
