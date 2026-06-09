import 'dart:io';

import 'package:equatable/equatable.dart';

class InformationParameter extends Equatable {
  final String? name;
  final String? bio;
  final String? date;
  final int? gender;
  final File? image;
  final List<File>? multiImages;
  final List<String>? oldMultiImages;
  final String? uuid;
  final bool? isUpdateOnlyUid;

  const InformationParameter({
    this.name,
    this.bio,
    this.date,
    this.gender,
    this.image,
    this.multiImages,
    this.oldMultiImages,
    this.uuid,
    this.isUpdateOnlyUid,
  });

  @override
  List<Object?> get props => [
        name,
        bio,
        date,
        gender,
        image,
        multiImages,
        oldMultiImages,
        uuid,
        isUpdateOnlyUid,
      ];
}
