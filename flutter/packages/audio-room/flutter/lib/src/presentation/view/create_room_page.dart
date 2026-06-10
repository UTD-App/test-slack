import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../audio_room_routes.dart';
import '../bloc/create_room_bloc.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _nameController = TextEditingController();
  final _introController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedMode = 9;
  int? _selectedType;
  File? _coverImage;
  bool _hasPassword = false;

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
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

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
          context.pushReplacement(
            AudioRoomRoutes.roomPath(state.createdRoom!.id),
          );
        } else if (state.createState == RequestState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? 'audio_room.error')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('audio_room.create'),
          actions: [
            BlocBuilder<CreateRoomBloc, CreateRoomState>(
              buildWhen: (prev, curr) => prev.createState != curr.createState,
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
                      : const Text('audio_room.publish'),
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
                        : null,
                  ),
                  child: _coverImage == null
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
              BlocBuilder<CreateRoomBloc, CreateRoomState>(
                buildWhen: (prev, curr) => prev.types != curr.types,
                builder: (context, state) {
                  if (state.types.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'audio_room.category',
                      border: OutlineInputBorder(),
                    ),
                    items: state.types
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                  );
                },
              ),
              SizedBox(height: 12.h),
              _SeatModeSelector(
                selectedMode: _selectedMode,
                onChanged: (mode) => setState(() => _selectedMode = mode),
              ),
              SizedBox(height: 12.h),
              SwitchListTile(
                title: const Text('audio_room.password'),
                value: _hasPassword,
                onChanged: (v) => setState(() => _hasPassword = v),
              ),
              if (_hasPassword) ...[
                SizedBox(height: 8.h),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'audio_room.enter_password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatModeSelector extends StatelessWidget {
  final int selectedMode;
  final ValueChanged<int> onChanged;

  const _SeatModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  static const _modes = [
    (mode: 9, label: '9'),
    //(mode: 8, label: '8'),
    //(mode: 12, label: '12'),
    //(mode: 16, label: '16'),
    //(mode: 22, label: '22'),
    //(mode: 2, label: '2'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'audio_room.seat_mode',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _modes.map((m) {
            final isSelected = m.mode == selectedMode;
            return ChoiceChip(
              label: Text('${m.label} seats'),
              selected: isSelected,
              onSelected: (_) => onChanged(m.mode),
            );
          }).toList(),
        ),
      ],
    );
  }
}
