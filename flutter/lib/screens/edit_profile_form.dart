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
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// The full "edit profile" page (avatar + name + bio + covers + Save).
///
/// It is SELF-CONTAINED: it seeds name/bio from the signed-in user and fetches
/// the current covers itself (`GET /users/{id}/profile`) — so it works the same
/// whether it's pushed as a route OR rendered as a node inside the server-driven
/// `edit_profile` Studio screen (via [EditProfileFormParser]). It depends on no
/// route arguments, which an embedded Stac node can't receive.
///
/// This screen is "too rich for Stac primitives" (image pick + upload, multi
/// cover management, save-with-state), so — exactly like the self-profile
/// landing — it stays a native widget that UTD Studio simply places on the
/// `edit_profile` screen; the screen wrapper is server-driven, the form native.
class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isSaving = false;

  /// The values the name/bio fields were last seeded with (from the session,
  /// then refreshed from the server). Used so a late server refresh only
  /// overwrites a field the user hasn't started editing — it never clobbers
  /// typed input.
  String _seedName = '';
  String _seedBio = '';

  /// Locally-picked avatar, not yet uploaded. Previews over the network avatar
  /// and is uploaded (then sent as a path) on save.
  XFile? _pickedImage;

  /// Covers being edited — raw stored paths (the save payload) parallel to their
  /// display URLs. Fetched in [initState] from the user's profile. `_coversKnown`
  /// gates the whole feature so a save that never managed to load the current
  /// covers (offline) leaves the stored covers untouched.
  final List<String> _coverPaths = [];
  final List<String> _coverUrls = [];
  bool _coversKnown = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserDataNotifier>().user;
    // Seed instantly from the in-memory session for a no-flicker first paint…
    _seedName = user.name ?? '';
    _seedBio = user.bio ?? '';
    _nameController = TextEditingController(text: _seedName);
    _bioController = TextEditingController(text: _seedBio);
    // …then self-source the live profile so the fields are correct even when the
    // session model is empty/stale (e.g. login returns only id+token and the
    // follow-up /my-data hadn't populated name/bio/covers yet).
    _loadProfile();
  }

  /// Fetches the signed-in user's profile and seeds the whole form (name, bio,
  /// avatar, covers) from the live server data, so the screen always shows
  /// something to edit regardless of how it was opened or whether the shared
  /// user model had loaded yet. The name/bio fields are only refreshed while the
  /// user hasn't started typing (so a late response never clobbers input). On
  /// failure it leaves the seeded values and `_coversKnown` false → a save won't
  /// touch the stored covers.
  Future<void> _loadProfile() async {
    // Capture the notifier before the first await so we never touch `context`
    // across an async gap (the provider reference itself is stable).
    final notifier = context.read<UserDataNotifier>();
    final id = notifier.user.id ?? 0;
    if (id <= 0) return;
    try {
      final res = await ApiClient.instance.dio.get('/users/$id/profile');
      final data = res.data;
      final inner = data is Map ? data['data'] : null;
      if (inner is! Map) return;
      final profile = inner['profile'];
      final name = inner['name']?.toString();
      final bio = inner['bio']?.toString();
      // Prefer the backend-resolved `cover_images` (absolute, correctly-bucketed
      // URLs) for display; `covers` are the raw paths sent back on save.
      final urls = profile is Map
          ? _strList(profile['cover_images'] ?? profile['covers'])
          : <String>[];
      final paths = profile is Map ? _strList(profile['covers']) : <String>[];
      if (!mounted) return;
      setState(() {
        _coversKnown = true;
        _coverPaths
          ..clear()
          ..addAll(paths);
        _coverUrls
          ..clear()
          ..addAll(urls);
        while (_coverUrls.length < _coverPaths.length) {
          _coverUrls.add('');
        }
        // Refresh the editable fields from the server unless the user already
        // changed them (text still equals what we seeded → safe to overwrite).
        if (name != null && _nameController.text == _seedName) {
          _nameController.text = name;
          _seedName = name;
        }
        if (bio != null && _bioController.text == _seedBio) {
          _bioController.text = bio;
          _seedBio = bio;
        }
      });
      // Push the fresh data into the shared user so the avatar/header (watched
      // from the notifier) render too, and the rest of the app stays in sync.
      if (profile is Map) {
        notifier.update(
          name: name,
          bio: bio,
          profile: ProfileRoomModel.fromJson(
            Map<String, dynamic>.from(profile),
          ),
        );
      }
    } catch (_) {
      // Leave the seeded values on failure (graceful) — save won't touch covers.
    }
  }

  List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => e?.toString() ?? '').toList() : <String>[];

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
    } catch (_) {
      // The upload threw (e.g. /media/upload 500 / storage failure). Surface it
      // instead of silently swallowing the exception (the cover just won't be
      // added) so the user knows the edit didn't take.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('app.error'))),
        );
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
          // Sending `covers` replaces the stored set; only send it when we
          // managed to load the current covers (otherwise leave them untouched).
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
        // Refresh the server-driven sources (core.currentUser) so the Me-landing
        // reflects the new name/bio/avatar immediately on return (no manual refresh).
        StacDataRegistry.instance.invalidate();
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        final successText = context.tr('app.success');
        // Persist the updated user so the new avatar survives an app restart.
        // Login and UserSessionService.hydrate() both write the user to the
        // cache; the profile edit must too — otherwise a restart that can't
        // reach /my-data falls back to a stale cached user with no avatar.
        await CacheManager.saveUserData(notifier.user.toJson());
        messenger.showSnackBar(SnackBar(content: Text(successText)));
        // Close the edit page after a successful save (mirrors the native flow).
        if (navigator.canPop()) navigator.pop();
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
              // Covers (up to 3) — shown once the current set has loaded.
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
