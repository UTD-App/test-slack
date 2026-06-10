import 'package:equatable/equatable.dart';

class BoomThemeModel extends Equatable {
  final List<BoomLevelThemeModel> levels;
  final List<BoomProgressAnimationModel> progressAnimations;

  const BoomThemeModel({
    this.levels = const [],
    this.progressAnimations = const [],
  });

  factory BoomThemeModel.fromJson(Map<String, dynamic> json) {
    return BoomThemeModel(
      levels: (json['levels'] as List?)
              ?.map((e) =>
                  BoomLevelThemeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      progressAnimations: (json['progress_animations'] as List?)
              ?.map((e) => BoomProgressAnimationModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [levels, progressAnimations];
}

class BoomLevelThemeModel extends Equatable {
  final int level;
  final BoomAssetModel background;
  final BoomAssetModel boom;

  const BoomLevelThemeModel({
    required this.level,
    required this.background,
    required this.boom,
  });

  factory BoomLevelThemeModel.fromJson(Map<String, dynamic> json) {
    return BoomLevelThemeModel(
      level: (json['level'] as num?)?.toInt() ?? 0,
      background: json['background'] != null
          ? BoomAssetModel.fromJson(json['background'] as Map<String, dynamic>)
          : const BoomAssetModel(type: '', url: ''),
      boom: json['boom'] != null
          ? BoomAssetModel.fromJson(json['boom'] as Map<String, dynamic>)
          : const BoomAssetModel(type: '', url: ''),
    );
  }

  @override
  List<Object?> get props => [level];
}

class BoomAssetModel extends Equatable {
  final String type;
  final String url;

  const BoomAssetModel({
    required this.type,
    required this.url,
  });

  factory BoomAssetModel.fromJson(Map<String, dynamic> json) {
    return BoomAssetModel(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [type, url];
}

class BoomProgressAnimationModel extends Equatable {
  final int percentage;
  final String image;
  final String imageType;

  const BoomProgressAnimationModel({
    required this.percentage,
    required this.image,
    required this.imageType,
  });

  factory BoomProgressAnimationModel.fromJson(Map<String, dynamic> json) {
    return BoomProgressAnimationModel(
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      image: json['image'] as String? ?? '',
      imageType: json['image_type'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [percentage];
}
