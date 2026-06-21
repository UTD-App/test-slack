import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/services/user_session_service.dart';

import '../../../domain/usecases/add_info_usecase.dart';
import '../../../domain/params/information_parameter.dart';
import '../../../../core/auth_routes.dart';
import '../../../../core/auth_strings.dart';

part 'add_information_event.dart';
part 'add_information_state.dart';

class AddInformationBloc
    extends Bloc<BaseAddInformationEvent, AddInformationState> {
  final AddInfoUseCase addInfoUseCase;

  AddInformationBloc({required this.addInfoUseCase})
    : super(
        AddInformationState(
          formKey: GlobalKey<FormState>(),
          name: TextEditingController(),
          country: TextEditingController(),
          email: TextEditingController(),
        ),
      ) {
    on<UsernameEvent>(_usernameEvent);
    on<EmileEvent>(_emailEvent);
    on<SelectedGenderEvent>(_genderEvent);
    on<SelectedBirthdayEvent>(_birthdayEvent);
    on<AddInformationEvent>(_addInformation);
    on<PickImageEvent>(_pickFileEvent);
    on<UserImageEvent>(_userImageEvent);
  }

  void _usernameEvent(UsernameEvent event, Emitter<AddInformationState> emit) =>
      emit(state.copyWith(name: event.name));

  void _userImageEvent(
    UserImageEvent event,
    Emitter<AddInformationState> emit,
  ) => emit(state.copyWith(image: event.image));

  void _emailEvent(EmileEvent event, Emitter<AddInformationState> emit) =>
      emit(state.copyWith(name: event.emile));

  void _genderEvent(
    SelectedGenderEvent event,
    Emitter<AddInformationState> emit,
  ) => emit(state.copyWith(gender: event.gender));

  void _birthdayEvent(
    SelectedBirthdayEvent event,
    Emitter<AddInformationState> emit,
  ) {
    if (event.dateTime == null) return;
    final String formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(event.dateTime ?? DateTime.now());
    emit(state.copyWith(birthday: formattedDate));
  }

  Future<void> _pickFileEvent(
    PickImageEvent event,
    Emitter<AddInformationState> emit,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path!;
        final imageFile = File(path);
        emit(state.copyWith(image: imageFile));
      } else {
        emit(state.copyWith(isImageNull: true));
      }
    } catch (e) {
      emit(state.copyWith(isImageNull: true));
    }
  }

  Future<void> _addInformation(
    AddInformationEvent event,
    Emitter<AddInformationState> emit,
  ) async {
    if (state.formKey.currentState?.validate() == false) return;

    emit(state.copyWith(requestState: RequestState.loading));

    final result = await addInfoUseCase(
      InformationParameter(
        name: state.name.text,
        image: state.image,
        gender: state.gender == event.context.tr(AuthStrings.male) ? 1 : 0,
        date: state.birthday,
      ),
    );

    result.when(
      success: (data) async {
        emit(
          state.copyWith(
            requestState: RequestState.loaded,
            message: data.message,
          ),
        );
        // Registration returns no user object — load the current user from
        // /my-data so the notifier has the new account's id.
        if (event.context.mounted) {
          await UserSessionService.hydrate(
            event.context.read<UserDataNotifier>(),
          );
        }
        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: data.message);
          event.context.go(AuthRoutes.layout);
        }
      },
      failure: (message, _) {
        emit(
          state.copyWith(requestState: RequestState.error, message: message),
        );
        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: message, isError: true);
        }
      },
    );
  }

  @override
  Future<void> close() {
    state.name.dispose();
    state.country.dispose();
    state.email.dispose();
    return super.close();
  }
}
