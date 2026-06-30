import 'package:utd_app/shared/core/json_coerce.dart';
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

  // Null-aware coercion: reached from MyDataModel.fromJson on the unguarded
  // launch/cache path, so a type drift must degrade to a default, never throw.
  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        id: coerceInt(json['id']),
        name: json['name']?.toString() ?? '',
        photo: json['flag']?.toString() ?? '',
        lang: json['lang']?.toString() ?? '',
        phoneCode: json['phone_code']?.toString() ?? '',
        iso: json['iso']?.toString() ?? '',
        nameEn: json['e_name']?.toString() ?? '',
      );
}
