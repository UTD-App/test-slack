class RoomAdminModel {
  final int id;
  final String name;
  final String? avatar;
  final String? countryFlag;
  final DateTime? assignedAt;

  const RoomAdminModel({
    required this.id,
    required this.name,
    this.avatar,
    this.countryFlag,
    this.assignedAt,
  });

  factory RoomAdminModel.fromJson(Map<String, dynamic> json) {
    return RoomAdminModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      countryFlag: json['country_flag'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'].toString())
          : null,
    );
  }
}
