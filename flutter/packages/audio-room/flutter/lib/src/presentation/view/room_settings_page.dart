import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/room_model.dart';
import '../bloc/room_management_bloc.dart';

class RoomSettingsPage extends StatefulWidget {
  final RoomModel room;

  const RoomSettingsPage({super.key, required this.room});

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _introController;
  late final TextEditingController _ruleController;
  late final TextEditingController _passwordController;
  late int _selectedMode;
  late bool _isCommentsClosed;
  late bool _freeMic;
  File? _coverImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room.roomName);
    _introController = TextEditingController(text: widget.room.roomIntro ?? '');
    _ruleController = TextEditingController(text: widget.room.roomRule ?? '');
    _passwordController = TextEditingController();
    _selectedMode = widget.room.mode;
    _isCommentsClosed = widget.room.isCommentsClosed;
    _freeMic = widget.room.freeMic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _ruleController.dispose();
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

  void _save() {
    context.read<RoomManagementBloc>().add(UpdateRoomEvent(
          roomId: widget.room.id,
          name: _nameController.text.trim(),
          intro: _introController.text.trim().isNotEmpty
              ? _introController.text.trim()
              : null,
          rule: _ruleController.text.trim().isNotEmpty
              ? _ruleController.text.trim()
              : null,
          mode: _selectedMode != widget.room.mode ? _selectedMode : null,
          isCommentsClosed: _isCommentsClosed != widget.room.isCommentsClosed
              ? _isCommentsClosed
              : null,
          freeMic: _freeMic != widget.room.freeMic ? _freeMic : null,
          cover: _coverImage,
        ));
  }

  void _removePassword() {
    context.read<RoomManagementBloc>().add(
          RemovePasswordEvent(roomId: widget.room.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomManagementBloc, RoomManagementState>(
      listenWhen: (prev, curr) => prev.updateState != curr.updateState,
      listener: (context, state) {
        if (state.updateState == RequestState.loaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('audio_room.settings_saved')),
          );
          Navigator.of(context).pop(state.updatedRoom);
        } else if (state.updateState == RequestState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? 'audio_room.error')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('audio_room.settings'),
          actions: [
            BlocBuilder<RoomManagementBloc, RoomManagementState>(
              buildWhen: (prev, curr) =>
                  prev.updateState != curr.updateState,
              builder: (context, state) {
                return TextButton(
                  onPressed: state.updateState == RequestState.loading
                      ? null
                      : _save,
                  child: state.updateState == RequestState.loading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('audio_room.save'),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
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
                        : widget.room.roomCover != null
                            ? DecorationImage(
                                image: NetworkImage(widget.room.roomCover!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: _coverImage == null && widget.room.roomCover == null
                      ? const Center(child: Icon(Icons.camera_alt, size: 40))
                      : null,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'audio_room.room_name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _introController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'audio_room.room_intro',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _ruleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'audio_room.room_rule',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'audio_room.seat_mode',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [9, 8, 12, 16, 22, 2].map((mode) {
                  return ChoiceChip(
                    label: Text('$mode seats'),
                    selected: _selectedMode == mode,
                    onSelected: (_) =>
                        setState(() => _selectedMode = mode),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),
              SwitchListTile(
                title: const Text('audio_room.close_comments'),
                value: _isCommentsClosed,
                onChanged: (v) => setState(() => _isCommentsClosed = v),
              ),
              SwitchListTile(
                title: const Text('audio_room.free_mic'),
                value: _freeMic,
                onChanged: (v) => setState(() => _freeMic = v),
              ),
              if (widget.room.hasPassword)
                Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: OutlinedButton.icon(
                    onPressed: _removePassword,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('audio_room.remove_password'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
