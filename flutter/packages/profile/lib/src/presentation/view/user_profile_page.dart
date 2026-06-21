import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/addons/feature_registry.dart';
import 'package:utd_app/addons/ui_contribution.dart';
import 'package:utd_app/addons/ui_slot.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/network/client/api_client.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/media/media_service.dart';
import 'package:utd_app/shared/models/profile_room_model.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import '../../domain/user_profile_model.dart';
import '../../profile_routes.dart';
import '../bloc/user_profile_bloc.dart';
import '../widgets/feature_grid.dart';
import '../widgets/profile_avatar_frame.dart';
import '../widgets/profile_badges_row.dart';
import '../widgets/profile_cover_banner.dart';
import '../widgets/profile_identity.dart';
import '../widgets/profile_top_bar.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;

  /// When true, render the read-only "visitor" view even for the current user
  /// (own-profile "preview as visitor"): no edit affordances, the visitor
  /// layout, and package sections in visitor mode.
  final bool previewAsVisitor;

  /// When true (the bottom-nav "Me" tab), render the compact landing variant of
  /// the OWN profile: the same identity + package sections but with NO cover and
  /// a camera badge on the avatar. Tapping the avatar opens the full profile
  /// (cover + data). Ignored for other users' profiles.
  final bool summaryLanding;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.previewAsVisitor = false,
    this.summaryLanding = false,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  /// True while an inline edit (bio/avatar) is being saved — shows a blocking
  /// overlay so the user can't fire a second edit mid-flight.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context
        .read<UserProfileBloc>()
        .add(LoadUserProfileEvent(userId: widget.userId));
  }

  /// Pull-to-refresh: silently refetch the profile (no full-page loader) and
  /// complete when the next state lands. A timeout guards against the bloc
  /// skipping an emit when the refreshed data is byte-identical.
  Future<void> _refresh() async {
    final bloc = context.read<UserProfileBloc>();
    bloc.add(LoadUserProfileEvent(userId: widget.userId, silent: true));
    await bloc.stream
        .firstWhere((s) => s.requestState != RequestState.loading)
        .timeout(const Duration(seconds: 8), onTimeout: () => bloc.state);
  }

  // ── Inline self-edit (own "Me" landing only) ─────────────────────────
  // Reuses the base host's `/profile/update` endpoint + MediaService, then
  // silently refetches the page and syncs the app-wide user so the new
  // bio / avatar show everywhere instantly. The full profile (reached by
  // tapping the avatar) is read-only — all other editing lives behind the
  // top-bar pencil → edit screen.

  Future<void> _editBio(String current) async {
    final value = await _editTextDialog(
      title: context.tr('app.bio'),
      initial: current,
      multiline: true,
    );
    final trimmed = value?.trim();
    if (trimmed == null || trimmed == current) return;
    await _updateProfile(bio: trimmed);
  }

  /// Change the avatar in place (the camera badge on the "Me"-tab landing):
  /// pick → upload to the `avatars` folder → save, then the silent refetch +
  /// UserDataNotifier sync in [_updateProfile] propagate the new photo app-wide.
  Future<void> _editAvatar() async {
    final picked = await MediaService.instance.pickImage(context);
    if (picked == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final uploaded =
          await MediaService.instance.uploadImage(picked, folder: 'avatars');
      if (uploaded == null) {
        _showSnack('app.error');
        return;
      }
      await _updateProfile(avatarPath: uploaded.path, manageBusy: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateProfile({
    String? name,
    String? bio,
    String? avatarPath,
    bool manageBusy = true,
  }) async {
    if (manageBusy) setState(() => _saving = true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/profile/update',
        data: {
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (avatarPath != null) 'avatar': avatarPath,
        },
      );

      // Keep the app-wide user (used by the home "Me" tab, headers…) in sync.
      ProfileRoomModel? updatedProfile;
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final profileJson = (data['data'] as Map)['profile'];
        if (profileJson is Map<String, dynamic>) {
          updatedProfile = ProfileRoomModel.fromJson(profileJson);
        }
      }
      if (!mounted) return;
      context.read<UserDataNotifier>().update(
            name: name,
            bio: bio,
            profile: updatedProfile,
          );
      // Silent refetch so the page reflects the change without a loader flash.
      context
          .read<UserProfileBloc>()
          .add(LoadUserProfileEvent(userId: widget.userId, silent: true));
      _showSnack('app.success');
    } catch (_) {
      _showSnack('app.error');
    } finally {
      if (manageBusy && mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _editTextDialog({
    required String title,
    required String initial,
    bool multiline = false,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorManager.lumiaCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ColorManager.frostedBorder),
        ),
        title: Text(
          title,
          style: const TextStyle(color: ColorManager.lumiaTextPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: multiline ? 4 : 1,
          minLines: multiline ? 3 : 1,
          style: const TextStyle(color: ColorManager.lumiaTextPrimary),
          cursorColor: ColorManager.lumiaAccentLight,
          textInputAction:
              multiline ? TextInputAction.newline : TextInputAction.done,
          onSubmitted:
              multiline ? null : (v) => Navigator.pop(ctx, v),
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorManager.frostedFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ColorManager.frostedBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ColorManager.lumiaAccentLight),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              ctx.tr('app.cancel'),
              style: const TextStyle(color: ColorManager.lumiaTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              ctx.tr('app.save'),
              style: const TextStyle(color: ColorManager.lumiaAccentLight),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(key))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ColorManager.lumiaBgGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              BlocBuilder<UserProfileBloc, UserProfileState>(
                builder: (context, state) => _buildBody(context, state),
              ),
              if (_saving)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfileState state) {
    switch (state.requestState) {
      case RequestState.loading:
        return const Center(child: CircularProgressIndicator());
      case RequestState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message ?? context.tr('profile.error'),
                style: const TextStyle(color: ColorManager.lumiaTextPrimary),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => context
                    .read<UserProfileBloc>()
                    .add(LoadUserProfileEvent(userId: widget.userId)),
                child: Text(context.tr('profile.retry')),
              ),
            ],
          ),
        );
      case RequestState.loaded:
        final profile = state.profile;
        if (profile == null) {
          return Center(
            child: Text(
              context.tr('profile.not_found'),
              style: const TextStyle(color: ColorManager.lumiaTextPrimary),
            ),
          );
        }
        return _buildProfile(context, profile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfile(BuildContext context, UserProfileModel profile) {
    final registry = context.read<FeatureRegistry>();

    // "Owner" = it's my profile AND I'm not in visitor-preview mode. Everything
    // that distinguishes the editable own-profile from the read-only visitor
    // view (layout branch, edit affordances, package isMe) keys off this.
    final isOwner = profile.isMe && !widget.previewAsVisitor;

    return MultiProvider(
      providers: [
        Provider<UserProfileModel>.value(value: profile),
        // Expose the aggregated package sections (profile.extensions) to any
        // widget contributed into UiSlot.userProfile / UiSlot.profileTab (Gifts,
        // Moments, Social…), mirroring the backend ProfileContributor seam.
        // Absent packages read nothing and render nothing.
        Provider<ProfileViewArguments>.value(
          value: ProfileViewArguments(
            sections: profile.extensions,
            userId: profile.id,
            isMe: isOwner,
          ),
        ),
      ],
      // Own profile has two faces: the compact "Me"-tab landing (summary) and
      // the full read-only profile reached by tapping the avatar there. Visiting
      // someone else (or previewing your own) gets the tabbed visitor view.
      child: isOwner
          ? (widget.summaryLanding
              ? _buildOwnLanding(context, profile, registry)
              : _buildOwnFull(context, profile, registry))
          : _buildVisitedProfile(context, profile, registry),
    );
  }

  /// The compact "Me"-tab landing: NO cover, a centered avatar with a camera
  /// badge (edits the photo in place) and the identity + package sections +
  /// Settings/feature grid. Tapping the avatar opens the full profile.
  Widget _buildOwnLanding(
      BuildContext context, UserProfileModel profile, FeatureRegistry registry) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: ColorManager.lumiaAccent,
      backgroundColor: ColorManager.lumiaCardBg,
      child: ListView(
        // Always scrollable so the pull-to-refresh gesture works even when
        // the content fits on one screen.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          Column(
            children: [
              ProfileTopBar(profile: profile, isOwner: true),
              SizedBox(height: 8.h),
              Center(
                child: ProfileAvatarFrame(
                  profile: profile,
                  onTap: () =>
                      context.push(ProfileRoutes.profilePath(widget.userId)),
                  onEdit: _editAvatar,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ProfileIdentity(
            profile: profile,
            onTap: () => context.push(ProfileRoutes.profilePath(widget.userId)),
            onEditBio: () => _editBio(profile.bio ?? ''),
          ),
          SizedBox(height: 14.h),
          ProfileBadgesRow(profile: profile),
          SizedBox(height: 18.h),
          // Feature sections contributed by installed packages (Social stats,
          // received Gifts…). Nothing is hardcoded — a section appears only when
          // its package is installed and returns data.
          _buildSlot(registry, UiSlot.userProfile),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: const FeatureGrid(),
          ),
        ],
      ),
    );
  }

  /// The full OWN profile, opened by tapping the avatar on the "Me" landing.
  /// READ-ONLY: shows the cover, the avatar on the leading side with the name /
  /// ID / levels beside it, the badge chips, bio and package sections — but NO
  /// inline edit affordances and NO Settings grid. All editing lives behind the
  /// top-bar pencil (→ edit screen).
  Widget _buildOwnFull(
      BuildContext context, UserProfileModel profile, FeatureRegistry registry) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: ColorManager.lumiaAccent,
      backgroundColor: ColorManager.lumiaCardBg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          // Cover strip ON TOP; the avatar straddles its bottom-leading edge.
          _innerCoverStrip(context, profile),
          SizedBox(height: 12.h),
          // Centered identity under the centered avatar: name + gender + flag,
          // ID, levels. Bio and the social-stats row are intentionally omitted
          // here (stats come back with the social package).
          ProfileIdentity(profile: profile, showBio: false),
          SizedBox(height: 14.h),
          ProfileBadgesRow(profile: profile),
          SizedBox(height: 18.h),
          _buildSlot(registry, UiSlot.userProfile),
        ],
      ),
    );
  }

  /// Read-only cover strip for the full own profile: the cover banner with the
  /// back / edit-pencil top bar over it and the avatar overlapping its
  /// bottom-LEADING edge — cover on top, photo below. The name / ID / levels
  /// render separately UNDER this (full width), not over the cover.
  Widget _innerCoverStrip(BuildContext context, UserProfileModel profile) {
    const bannerHeight = 158.0;
    final hasFrame = profile.avatarFrame != null;
    final avatarBox = (hasFrame ? 140.0 : 96.0).w;
    // Only a small sliver of the avatar overlaps the cover; most of it sits
    // below the banner on the gradient.
    final avatarTop = bannerHeight.h - avatarBox * 0.32;
    return SizedBox(
      height: avatarTop + avatarBox,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ProfileCoverBanner(
              covers: profile.covers,
              coverPaths: profile.coverPaths,
              height: bannerHeight,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ProfileTopBar(profile: profile, isOwner: true),
          ),
          Positioned(
            top: avatarTop,
            left: 0,
            right: 0,
            child: Center(child: ProfileAvatarFrame(profile: profile)),
          ),
        ],
      ),
    );
  }

  /// A visited user's profile — rendered in the same clean "Me landing" style
  /// (NO cover, centered read-only avatar, identity, badges, then the inline
  /// package sections). The package "tab" feeds (Moments / Reels…) are rendered
  /// INLINE as bounded sections (no TabBar), and the action buttons (Follow…)
  /// stay pinned at the bottom. Everything stays decoupled via the Ui slots.
  Widget _buildVisitedProfile(
      BuildContext context, UserProfileModel profile, FeatureRegistry registry) {
    final tabContribs = registry.getUiContributions(UiSlot.profileTab).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final actions = registry.getUiContributions(UiSlot.userProfileActions);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: ColorManager.lumiaAccent,
            backgroundColor: ColorManager.lumiaCardBg,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 24.h),
              children: [
                // Me-landing-style header: NO cover, read-only centered avatar.
                ProfileTopBar(profile: profile, isOwner: false),
                SizedBox(height: 8.h),
                Center(child: ProfileAvatarFrame(profile: profile)),
                SizedBox(height: 12.h),
                ProfileIdentity(profile: profile),
                SizedBox(height: 14.h),
                ProfileBadgesRow(profile: profile),
                SizedBox(height: 18.h),
                // Inline package sections (social stats, gifts…).
                _buildSlot(registry, UiSlot.userProfile),
                // Package feeds (Moments/Reels…) inline — no TabBar; each keeps
                // its own internal scroll inside a bounded section.
                for (final c in tabContribs) _inlineTabSection(context, c),
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  for (final c in actions)
                    Expanded(child: Builder(builder: c.builder)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// A package "tab" feed shown inline on the visited Me-landing view: a small
  /// section title + the feed in a bounded box (the feed scrolls internally so it
  /// doesn't break the outer page scroll).
  Widget _inlineTabSection(BuildContext context, UiContribution contribution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18.h),
        if (contribution.label != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              context.tr(contribution.label!),
              style: TextStyle(
                color: ColorManager.lumiaTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
          ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 480.h,
          child: Builder(builder: contribution.builder),
        ),
      ],
    );
  }

  Widget _buildSlot(FeatureRegistry registry, UiSlot slot) {
    final contributions = registry.getUiContributions(slot);
    if (contributions.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final contribution in contributions) contribution.builder(context),
      ],
    );
  }
}
