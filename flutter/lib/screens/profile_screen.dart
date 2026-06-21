import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/network/client/api_client.dart';
import 'package:utd_app/shared/core/shared.dart';
import 'package:utd_app/shared/media/media_service.dart';
import 'package:utd_app/shared/models/profile_room_model.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';

class ProfileScreen extends StatefulWidget {
  /// Optional cover data passed from the profile page's edit pencil:
  /// `{ 'coverPaths': List<String>, 'covers': List<String> }`. When present the
  /// screen shows a Covers section and sends them on save; when null (reached
  /// without cover data) the stored covers are left untouched.
  const ProfileScreen({super.key, this.coverArgs});

  final Object? coverArgs;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isSaving = false;

  /// Locally-picked avatar, not yet uploaded. Previews over the network avatar
  /// and is uploaded (then sent as a path) on save.
  XFile? _pickedImage;

  /// Covers being edited — raw stored paths (the save payload) parallel to their
  /// display URLs — seeded from [ProfileScreen.coverArgs]. `_coversKnown` gates
  /// the whole feature so a screen opened without cover data never touches the
  /// stored covers on save.
  final List<String> _coverPaths = [];
  final List<String> _coverUrls = [];
  bool _coversKnown = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserDataNotifier>().user;
    _nameController = TextEditingController(text: user.name ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');

    final args = widget.coverArgs;
    if (args is Map) {
      _coversKnown = true;
      _coverPaths.addAll(((args['coverPaths'] as List?) ?? const []).cast<String>());
      _coverUrls.addAll(((args['covers'] as List?) ?? const []).cast<String>());
      // Keep the display list at least as long as the payload list.
      while (_coverUrls.length < _coverPaths.length) {
        _coverUrls.add('');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await MediaService.instance.pickImage(context);
    if (picked != null && mounted) {
      setState(() => _pickedImage = picked);
    }
  }

  /// Add a cover (up to 3): pick → upload to the `covers` folder → keep its
  /// path (payload) + URL (preview). Attached on [_save] (replaces the set).
  Future<void> _pickCover() async {
    if (_coverPaths.length >= 3) return;
    final picked = await MediaService.instance.pickImage(context);
    if (picked == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final uploaded =
          await MediaService.instance.uploadImage(picked, folder: 'covers');
      if (uploaded == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('app.error'))),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _coverPaths.add(uploaded.path);
          _coverUrls.add(uploaded.url);
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removeCover(int i) {
    setState(() {
      if (i < _coverPaths.length) _coverPaths.removeAt(i);
      if (i < _coverUrls.length) _coverUrls.removeAt(i);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      // Upload the new avatar first via the reusable, provider-agnostic
      // service, then send its stored path with the profile fields.
      String? avatarPath;
      if (_pickedImage != null) {
        final uploaded = await MediaService.instance
            .uploadImage(_pickedImage!, folder: 'avatars');
        if (uploaded == null) throw Exception('upload failed');
        avatarPath = uploaded.path;
      }

      final response = await ApiClient.instance.dio.post(
        '/profile/update',
        data: {
          'name': name,
          'bio': _bioController.text.trim(),
          if (avatarPath != null) 'avatar': avatarPath,
          // Sending `covers` replaces the stored set; only send it when we were
          // handed the current covers (otherwise leave them untouched).
          if (_coversKnown) 'covers': _coverPaths,
        },
      );

      // Pull the fresh `profile` (with its new image URL) back so the rest of
      // the app reflects the new avatar.
      ProfileRoomModel? updatedProfile;
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final profileJson = (data['data'] as Map)['profile'];
        if (profileJson is Map<String, dynamic>) {
          updatedProfile = ProfileRoomModel.fromJson(profileJson);
        }
      }

      if (mounted) {
        final notifier = context.read<UserDataNotifier>();
        notifier.update(
              name: name,
              bio: _bioController.text.trim(),
              profile: updatedProfile,
            );
        final messenger = ScaffoldMessenger.of(context);
        final successText = context.tr('app.success');
        // Persist the updated user so the new avatar survives an app restart.
        // Login and UserSessionService.hydrate() both write the user to the
        // cache; the profile edit must too — otherwise a restart that can't
        // reach /my-data falls back to a stale cached user with no avatar.
        await CacheManager.saveUserData(notifier.user.toJson());
        messenger.showSnackBar(SnackBar(content: Text(successText)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('app.error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(BuildContext context, String key) => TextWidget(
    context.tr(key),
    style: context.bodySmall.w500
        .colorExt(ColorManager.lumiaTextSecondary)
        .size(14),
  );

  Widget _darkField(
    BuildContext context, {
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: 14.radius,
      borderSide: const BorderSide(color: ColorManager.frostedBorder),
    );
    final focused = OutlineInputBorder(
      borderRadius: 14.radius,
      borderSide: const BorderSide(color: ColorManager.lumiaAccentLight),
    );
    return TextInputWidget(
      '',
      controller: controller,
      maxLines: maxLines,
      textColor: ColorManager.white,
      cursorColor: ColorManager.white,
      fillColor: ColorManager.frostedFill,
      contentPadding: context.paddingSymmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: focused,
      errorBorder: border,
      focusedErrorBorder: focused,
    );
  }

  Widget _coverThumb(int i) {
    const size = 84.0;
    final url = i < _coverUrls.length ? _coverUrls[i] : '';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url.isEmpty
                ? Container(
                    width: size,
                    height: size,
                    color: ColorManager.frostedFill,
                  )
                : Image.network(
                    url,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: size,
                      height: size,
                      color: ColorManager.frostedFill,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: ColorManager.lumiaTextSecondary,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: _isSaving ? null : () => _removeCover(i),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xCC000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addCoverTile() {
    const size = 84.0;
    return GestureDetector(
      onTap: _isSaving ? null : _pickCover,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ColorManager.frostedFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorManager.frostedBorder),
        ),
        child: const Icon(
          Icons.add_a_photo_outlined,
          color: ColorManager.lumiaAccentLight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDataNotifier>().user;

    return Scaffold(
      backgroundColor: ColorManager.lumiaBgDark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: ColorManager.transparent,
        elevation: 0,
        title: Text(context.tr('app.profile')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorManager.white,
                      ),
                    )
                  : Text(
                      context.tr('app.save'),
                      style: context.bodyMedium.w600.colorExt(
                        ColorManager.lumiaAccentLight,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            children: [
              // Avatar (tap to change)
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isSaving ? null : _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: ColorManager.lumiaCardBg,
                            backgroundImage: _avatarImage(user.profile?.image),
                            child: _avatarImage(user.profile?.image) == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: ColorManager.lumiaTextSecondary,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: ColorManager.pinkCtaGradient,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorManager.lumiaBgDark,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: ColorManager.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    8.hBox,
                    TextButton(
                      onPressed: _isSaving ? null : _pickImage,
                      child: Text(
                        context.tr('app.change_avatar'),
                        style: context.bodyMedium.w500.colorExt(
                          ColorManager.lumiaAccentLight,
                        ),
                      ),
                    ),
                    Text(
                      user.email ?? '',
                      style: context.bodyMedium.colorExt(
                        ColorManager.lumiaTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              24.hBox,
              // Name
              _label(context, 'app.name'),
              8.hBox,
              _darkField(context, controller: _nameController),
              16.hBox,
              // Bio
              _label(context, 'app.bio'),
              8.hBox,
              _darkField(context, controller: _bioController, maxLines: 3),
              // Covers (up to 3) — only when the screen was handed the current
              // set from the profile page's edit pencil.
              if (_coversKnown) ...[
                24.hBox,
                _label(context, 'app.covers'),
                8.hBox,
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _coverPaths.length; i++) _coverThumb(i),
                    if (_coverPaths.length < 3) _addCoverTile(),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Picked local file takes precedence; otherwise the stored network image.
  ImageProvider? _avatarImage(String? networkUrl) {
    if (_pickedImage != null) return FileImage(File(_pickedImage!.path));
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return NetworkImage(networkUrl);
    }
    return null;
  }
}
