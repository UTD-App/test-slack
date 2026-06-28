import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';

import 'package:utd_app/localization/localization.dart';

import 'package:audio_room/src/audio_room_strings.dart';
import '../bloc/create_room/create_room_bloc.dart';
import '../widgets/overlay/audio_room_app_overlay.dart';
import '../widgets/room/seats/seat_icon_picker.dart';
import '../widgets/room/seats/seat_icon_row.dart';
import '../widgets/room/seats/seat_mode_selector.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _introController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedMode = 9;
  int? _selectedType;
  File? _coverImage;
  bool _hasPassword = false;
  SeatIconChoice? _emptySeatChoice;
  SeatIconChoice? _lockedSeatChoice;

  @override
  void initState() {
    super.initState();
    context.read<CreateRoomBloc>().add(const LoadRoomTypesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _coverImage = File(image.path));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    context.read<CreateRoomBloc>().add(
      SubmitCreateRoomEvent(
        name: name,
        mode: _selectedMode,
        intro: _introController.text.trim().isNotEmpty
            ? _introController.text.trim()
            : null,
        roomType: _selectedType,
        password: _hasPassword ? _passwordController.text.trim() : null,
        cover: _coverImage,
        emptySeatIcon: _emptySeatChoice?.type == SeatIconChoiceType.custom
            ? _emptySeatChoice!.file
            : null,
        lockedSeatIcon: _lockedSeatChoice?.type == SeatIconChoiceType.custom
            ? _lockedSeatChoice!.file
            : null,
        emptySeatIconPreset: _emptySeatChoice?.type == SeatIconChoiceType.preset
            ? _emptySeatChoice!.presetName
            : _emptySeatChoice?.type == SeatIconChoiceType.defaultIcon
                ? ''
                : null,
        lockedSeatIconPreset: _lockedSeatChoice?.type == SeatIconChoiceType.preset
            ? _lockedSeatChoice!.presetName
            : _lockedSeatChoice?.type == SeatIconChoiceType.defaultIcon
                ? ''
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateRoomBloc, CreateRoomState>(
      listenWhen: (prev, curr) => prev.createState != curr.createState,
      listener: (context, state) {
        if (state.createState == RequestState.loaded &&
            state.createdRoom != null) {
          context.pop();
          AudioRoomAppOverlay.openRoom(state.createdRoom!.id);
        } else if (state.createState == RequestState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? context.tr(AudioRoomKeys.createError))),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(AudioRoomKeys.createRoom)),
          actions: [
            BlocBuilder<CreateRoomBloc, CreateRoomState>(
              buildWhen: (prev, curr) =>
                  prev.createState != curr.createState,
              builder: (context, state) {
                return TextButton(
                  onPressed: state.createState == RequestState.loading
                      ? null
                      : _submit,
                  child: state.createState == RequestState.loading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(context.tr(AudioRoomKeys.publish)),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 160.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                    image: _coverImage != null
                        ? DecorationImage(
                            image: FileImage(_coverImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImage == null
                      ? const Center(
                          child: Icon(Icons.camera_alt, size: 40))
                      : null,
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr(AudioRoomKeys.roomName),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr(AudioRoomKeys.roomNameRequired);
                  }
                  if (value.trim().length < 2) {
                    return context.tr(AudioRoomKeys.roomNameTooShort);
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _introController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.tr(AudioRoomKeys.roomIntro),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              BlocBuilder<CreateRoomBloc, CreateRoomState>(
                buildWhen: (prev, curr) => prev.types != curr.types,
                builder: (context, state) {
                  if (state.types.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: context.tr(AudioRoomKeys.category),
                      border: const OutlineInputBorder(),
                    ),
                    items: state.types
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedType = value),
                  );
                },
              ),
              SizedBox(height: 12.h),
              SeatModeSelector(
                selectedMode: _selectedMode,
                onChanged: (mode) => setState(() => _selectedMode = mode),
              ),
              SizedBox(height: 12.h),
              SeatIconRow(
                label: context.tr(AudioRoomKeys.emptySeatIcon),
                choice: _emptySeatChoice,
                iconType: SeatIconType.empty,
                onTap: () async {
                  final result = await showSeatIconPicker(context, iconType: SeatIconType.empty);
                  if (result == null || !mounted) return;
                  if (result.type == SeatIconChoiceType.pickFromGallery) {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                    );
                    if (image == null || !mounted) return;
                    setState(() => _emptySeatChoice = SeatIconChoice.custom(File(image.path)));
                  } else {
                    setState(() => _emptySeatChoice = result);
                  }
                },
              ),
              SizedBox(height: 12.h),
              SeatIconRow(
                label: context.tr(AudioRoomKeys.lockedSeatIcon),
                choice: _lockedSeatChoice,
                iconType: SeatIconType.locked,
                onTap: () async {
                  final result = await showSeatIconPicker(context, iconType: SeatIconType.locked);
                  if (result == null || !mounted) return;
                  if (result.type == SeatIconChoiceType.pickFromGallery) {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                    );
                    if (image == null || !mounted) return;
                    setState(() => _lockedSeatChoice = SeatIconChoice.custom(File(image.path)));
                  } else {
                    setState(() => _lockedSeatChoice = result);
                  }
                },
              ),
              SizedBox(height: 12.h),
              SwitchListTile(
                title: Text(context.tr(AudioRoomKeys.password)),
                value: _hasPassword,
                onChanged: (v) => setState(() => _hasPassword = v),
              ),
              if (_hasPassword) ...[
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr(AudioRoomKeys.enterPassword),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_hasPassword) return null;
                    if (value == null || value.trim().isEmpty) {
                      return context.tr(AudioRoomKeys.passwordRequired);
                    }
                    if (value.trim().length < 4) {
                      return context.tr(AudioRoomKeys.passwordTooShort);
                    }
                    return null;
                  },
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
