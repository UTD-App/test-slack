class RoomVisitorModel {
  final int id;
  final String name;
  final String? avatar;
  final String? countryFlag;
  final DateTime? joinedAt;

  const RoomVisitorModel({
    required this.id,
    required this.name,
    this.avatar,
    this.countryFlag,
    this.joinedAt,
  });

  factory RoomVisitorModel.fromJson(Map<String, dynamic> json) {
    return RoomVisitorModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      countryFlag: json['country_flag'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString())
          : null,
    );
  }
}
