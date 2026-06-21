import 'package:utd_app/shared/entities/my_data_entity.dart';
import 'package:utd_app/shared/models/country_model.dart';
import 'package:utd_app/shared/models/profile_room_model.dart';

class MyDataModel extends MyDataEntity {
  const MyDataModel({
    super.id,
    super.uid,
    super.name,
    super.email,
    super.phone,
    super.uuid,
    super.bio,
    super.notificationId,
    super.isFirst,
    super.onlineTime,
    super.country,
    super.profile,
    super.authToken,
  });

  factory MyDataModel.fromJson(Map<String, dynamic> map) {
    return MyDataModel(
      id: (map['id'] as int?) ?? 0,
      uid: (map['firebase_uuid'] as String?) ?? '',
      notificationId: (map['notification_id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      uuid: (map['uuid'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      isFirst: (map['is_first'] as bool?) ?? false,
      onlineTime: (map['online_time'] as String?) ?? '',
      authToken: (map['auth_token'] as String?) ?? '',
      // Coerce nested maps to Map<String, dynamic>: the Hive cache round-trip
      // returns nested objects as _Map<dynamic, dynamic>, which would throw a
      // cast error when handed to the sub-model fromJson (param is
      // Map<String, dynamic>). Network (dio) maps are already typed, so .from
      // is a harmless copy there.
      profile: map['profile'] is Map
          ? ProfileRoomModel.fromJson(
              Map<String, dynamic>.from(map['profile'] as Map))
          : null,
      country: map['country'] is Map
          ? CountryModel.fromJson(
              Map<String, dynamic>.from(map['country'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uuid': uid,
      'notification_id': notificationId,
      'name': name,
      'email': email,
      'phone': phone,
      'uuid': uuid,
      'bio': bio,
      'is_first': isFirst,
      'online_time': onlineTime,
      'auth_token': authToken,
      // Persist the profile so the avatar survives a cache round-trip (read back
      // by fromJson's map['profile']). Previously omitted -> avatar lost on any
      // cache-backed load (e.g. when /my-data can't be reached on restart).
      // `profile` is typed as the entity but is always a ProfileRoomModel here.
      'profile': (profile as ProfileRoomModel?)?.toJson(),
    };
  }

  MyDataModel copyWith({
    int? id,
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? uuid,
    String? bio,
    String? notificationId,
    bool? isFirst,
    String? onlineTime,
    CountryModel? country,
    ProfileRoomModel? profile,
    String? authToken,
  }) {
    return MyDataModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      uuid: uuid ?? this.uuid,
      bio: bio ?? this.bio,
      notificationId: notificationId ?? this.notificationId,
      isFirst: isFirst ?? this.isFirst,
      onlineTime: onlineTime ?? this.onlineTime,
      country: country ?? this.country,
      profile: profile ?? this.profile,
      authToken: authToken ?? this.authToken,
    );
  }
}
