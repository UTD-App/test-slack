import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  final int? id;
  final String? name;
  final String? photo;
  final String? lang;
  final String? phoneCode;
  final String? iso;
  final String? nameEn;

  const CountryEntity({
    this.id,
    this.name,
    this.photo,
    this.lang,
    this.phoneCode,
    this.iso,
    this.nameEn,
  });

  @override
  List<Object?> get props => [id, name, photo, lang, phoneCode, iso, nameEn];
}
