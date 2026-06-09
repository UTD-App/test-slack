import 'package:utd_app/shared/entities/country_entity.dart';

class CountryModel extends CountryEntity {
  const CountryModel({
    super.id,
    super.name,
    super.photo,
    super.lang,
    super.phoneCode,
    super.iso,
    super.nameEn,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        id: (json['id'] as int?) ?? 0,
        name: (json['name'] as String?) ?? '',
        photo: (json['flag'] as String?) ?? '',
        lang: (json['lang'] as String?) ?? '',
        phoneCode: (json['phone_code'] as String?) ?? '',
        iso: (json['iso'] as String?) ?? '',
        nameEn: (json['e_name'] as String?) ?? '',
      );
}
