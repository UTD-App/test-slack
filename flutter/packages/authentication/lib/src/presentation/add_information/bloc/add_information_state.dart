part of 'add_information_bloc.dart';

class AddInformationState extends Equatable {
  final TextEditingController name, birthday, country, gender, email;
  final File? image;
  final RequestState requestState;
  final String message;
  final GlobalKey<FormState> formKey;

  const AddInformationState({
    required this.formKey,
    required this.name,
    required this.birthday,
    required this.email,
    required this.country,
    required this.gender,
    this.image,
    this.requestState = RequestState.idle,
    this.message = '',
  });

  AddInformationState copyWith({
    String? name,
    String? birthday,
    String? country,
    String? gender,
    String? email,
    RequestState? requestState,
    File? image,
    String? message,
    bool isImageNull = false,
    GlobalKey<FormState>? formKey,
  }) {
    return AddInformationState(
      name: name != null ? (this.name..text = name) : this.name,
      birthday:
          birthday != null ? (this.birthday..text = birthday) : this.birthday,
      country:
          country != null ? (this.country..text = country) : this.country,
      gender: gender != null ? (this.gender..text = gender) : this.gender,
      email: email != null ? (this.email..text = email) : this.email,
      requestState: requestState ?? this.requestState,
      message: message ?? this.message,
      image: isImageNull ? null : image ?? this.image,
      formKey: formKey ?? this.formKey,
    );
  }

  @override
  List<Object?> get props => [
        formKey,
        name.text,
        birthday.text,
        country.text,
        gender.text,
        email.text,
        image,
        requestState,
        message,
      ];
}
