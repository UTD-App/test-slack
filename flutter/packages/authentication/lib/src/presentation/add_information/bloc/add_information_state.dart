part of 'add_information_bloc.dart';

class AddInformationState extends Equatable {
  final TextEditingController name, country, email;
  // Gender + birthday are SELECTOR values (set via events, not typed), so they
  // are plain strings — NOT controllers. Using controllers here made copyWith
  // mutate a shared object that the Equatable props read via `.text`, so the new
  // state compared equal to the old one and BLoC skipped the emit → the gender
  // highlight / age display never rebuilt.
  final String gender;
  final String birthday;
  final File? image;
  final RequestState requestState;
  final String message;
  final GlobalKey<FormState> formKey;

  const AddInformationState({
    required this.formKey,
    required this.name,
    required this.email,
    required this.country,
    this.gender = '',
    this.birthday = '',
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
      country: country != null ? (this.country..text = country) : this.country,
      email: email != null ? (this.email..text = email) : this.email,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
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
        birthday,
        country.text,
        gender,
        email.text,
        image,
        requestState,
        message,
      ];
}
