import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../localization/localization.dart';
import '../shared/core/color_manager.dart';
import '../shared/profile/public_user.dart';
import '../shared/profile/public_user_api.dart';
import '../shared/widgets/gradient_background.dart';
import '../shared/widgets/gradient_card.dart';

/// A basic, read-only profile for ANOTHER user, shown when the rich Profile
/// package is NOT installed.
///
/// Deliberately minimal — the SAME look as the own "Me" fallback: just the
/// identity essentials (name + UID), no avatar, no cover, no extra stats. The
/// name + UID come from the always-available `GET /users/{id}`. When the Profile
/// package IS installed, [ProfileNavigator] routes to that package's richer view
/// instead and this screen is never shown.
class VisitedProfileFallback extends StatefulWidget {
  final int userId;

  const VisitedProfileFallback({super.key, required this.userId});

  @override
  State<VisitedProfileFallback> createState() => _VisitedProfileFallbackState();
}

class _VisitedProfileFallbackState extends State<VisitedProfileFallback> {
  final PublicUserApi _api = PublicUserApi();

  bool _loading = true;
  String? _error;
  PublicUser? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.fetch(widget.userId);
    if (!mounted) return;
    result.when(
      success: (user) => setState(() {
        _user = user;
        _loading = false;
      }),
      failure: (message, _) => setState(() {
        _error = message;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
      ),
      body: GradientBackground(
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorManager.lumiaAccent),
      );
    }

    if (_error != null || _user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48.sp, color: ColorManager.lumiaTextSecondary),
            SizedBox(height: 12.h),
            Text(
              _error ?? context.tr('app.error'),
              style: const TextStyle(color: ColorManager.lumiaTextPrimary),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _load,
              child: Text(context.tr('app.retry')),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final name = user.name.isNotEmpty ? user.name : context.tr('app.profile');
    final uid = user.uuid.isNotEmpty ? user.uuid : '—';

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        SizedBox(height: 8.h),
        _header(name: name),
        SizedBox(height: 20.h),
        // Identity essentials only — name (above) + UID.
        GradientCard(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: _infoRow(
            icon: Icons.badge_outlined,
            tint: const Color(0xFF7C4DFF),
            label: context.tr('app.uid'),
            value: uid,
            onCopy: uid == '—' ? null : () => _copy(uid),
          ),
        ),
      ],
    );
  }

  Widget _header({required String name}) {
    // No avatar — just the name, matching the minimal own "Me" fallback.
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

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

  Widget _infoRow({
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

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('app.copied'))),
    );
  }
}
