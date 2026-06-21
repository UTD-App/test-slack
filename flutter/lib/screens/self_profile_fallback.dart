import 'package:authentication/core/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../localization/localization.dart';
import '../shared/core/color_manager.dart';
import '../shared/notifiers/user_data_notifier.dart';
import '../shared/widgets/gradient_background.dart';
import '../shared/widgets/gradient_card.dart';

/// The "Me" tab shown when the Profile package is NOT installed.
///
/// Deliberately minimal: it surfaces only the account essentials (ID, email,
/// change password) in a tidy frosted card, plus a hint to install the Profile
/// package for the full profile experience. Everything else (language, logout,
/// delete account…) stays reachable via the settings gear in the app bar.
///
/// When the Profile package IS installed, the base swaps this for that package's
/// rich profile via the `kSelfProfileWidget` seam — the base never imports it.
class SelfProfileFallback extends StatelessWidget {
  const SelfProfileFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDataNotifier>().user;
    final name = (user.name ?? '').isNotEmpty
        ? user.name!
        : context.tr('app.profile');
    final uid = (user.uuid ?? '').isNotEmpty ? user.uuid! : '—';
    final email = user.email ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          context.tr('app.me'),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('app.settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            children: [
              SizedBox(height: 8.h),
              _header(context, name: name),
              SizedBox(height: 20.h),
              // Account essentials only — ID, email, password.
              GradientCard(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    _infoRow(
                      context,
                      icon: Icons.badge_outlined,
                      tint: const Color(0xFF7C4DFF),
                      label: context.tr('app.uid'),
                      value: uid,
                      onCopy: uid == '—' ? null : () => _copy(context, uid),
                    ),
                    _divider(),
                    _infoRow(
                      context,
                      icon: Icons.email_outlined,
                      tint: const Color(0xFF26C6DA),
                      label: context.tr('app.email'),
                      value: email.isNotEmpty ? email : '—',
                    ),
                    _divider(),
                    _tile(
                      context,
                      icon: Icons.lock_outline,
                      tint: const Color(0xFFEC407A),
                      label: context.tr('app.change_password'),
                      onTap: () => context.push(AuthRoutes.recoverPassword),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              _installHint(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, {required String name}) {
    // No avatar in the fallback — just the name. The full avatar/cover profile
    // is the Profile package's job; this minimal "Me" shows identity essentials
    // (name + UID + email) only.
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          name,
          style: TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// A hint card inviting the user to install the Profile package for the full
  /// profile (covers, levels, social stats, gifts…).
  Widget _installHint(BuildContext context) {
    return GradientCard(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(Icons.extension_outlined,
              color: ColorManager.lumiaAccentLight, size: 26.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              context.tr('app.install_profile_hint'),
              style: TextStyle(
                color: ColorManager.lumiaTextSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('app.copied'))),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: ColorManager.frostedBorder,
        ),
      );

  Widget _iconBadge(IconData icon, Color tint) => Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: tint, size: 19.sp),
      );

  /// A read-only info row (label + value), with an optional trailing copy icon.
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
      child: Row(
        children: [
          _iconBadge(icon, tint),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ColorManager.lumiaTextSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorManager.lumiaTextPrimary,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy,
                  size: 16.sp, color: ColorManager.lumiaTextSecondary),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  /// A tappable action row (label + chevron).
  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: Row(
          children: [
            _iconBadge(icon, tint),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: ColorManager.lumiaTextPrimary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 13.sp, color: ColorManager.lumiaTextSecondary),
          ],
        ),
      ),
    );
  }
}
