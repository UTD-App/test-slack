import 'package:equatable/equatable.dart';
import 'package:utd_app/shared/entities/country_entity.dart';
import 'package:utd_app/shared/entities/profile_room_entity.dart';

class MyDataEntity extends Equatable {
  final int? id;
  final String? uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? uuid;
  final String? bio;
  final String? notificationId;
  final bool? isFirst;
  final String? onlineTime;
  final CountryEntity? country;
  final ProfileRoomEntity? profile;
  final String? authToken;

  const MyDataEntity({
    this.id,
    this.uid,
    this.name,
    this.email,
    this.phone,
    this.uuid,
    this.bio,
    this.notificationId,
    this.isFirst,
    this.onlineTime,
    this.country,
    this.profile,
    this.authToken,
  });

  @override
  List<Object?> get props => [
        id,
        uid,
        name,
        email,
        phone,
        uuid,
        bio,
        notificationId,
        isFirst,
        onlineTime,
        country,
        profile,
        authToken,
      ];
}
