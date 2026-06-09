part of 'add_information_bloc.dart';

sealed class BaseAddInformationEvent extends Equatable {
  final DateTime? dateTime;
  final String? gender;
  final File? image;
  final String? name;
  final String? emile;

  const BaseAddInformationEvent({
    this.gender,
    this.dateTime,
    this.image,
    this.name,
    this.emile,
  });

  @override
  List<Object?> get props => [gender, dateTime, image, name];
}

final class SelectedGenderEvent extends BaseAddInformationEvent {
  const SelectedGenderEvent({required super.gender});
}

final class SelectedBirthdayEvent extends BaseAddInformationEvent {
  const SelectedBirthdayEvent({required super.dateTime});
}

final class PickImageEvent extends BaseAddInformationEvent {
  const PickImageEvent({required super.image});
}

final class AddInformationEvent extends BaseAddInformationEvent {
  final BuildContext context;
  final bool isNavLayout;
  final bool isUpdateOnlyUid;

  const AddInformationEvent({
    required this.context,
    this.isNavLayout = true,
    this.isUpdateOnlyUid = false,
  });

  @override
  List<Object?> get props => [context, isNavLayout, isUpdateOnlyUid];
}

final class UsernameEvent extends BaseAddInformationEvent {
  const UsernameEvent({required super.name});
}

final class UserImageEvent extends BaseAddInformationEvent {
  const UserImageEvent({required super.image});
}

final class EmileEvent extends BaseAddInformationEvent {
  const EmileEvent({required super.emile});
}
