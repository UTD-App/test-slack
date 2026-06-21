import 'package:authentication/core/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../cache/cache_manager.dart';
import '../localization/localization.dart';
import '../network/services/base_api_service.dart';
import '../services/launch_gate_service.dart';
import '../shared/core/color_manager.dart';
import '../shared/widgets/gradient_background.dart';
import '../shared/widgets/gradient_card.dart';
import 'launch_gate_screen.dart' show openStoreUrl;

/// App settings: a list of settings entries (account, language, privacy, VIP…)
/// plus logout, styled to the dark-purple mockup aesthetic — a frosted card of
/// rows with colorful icon badges over the app gradient. Entries whose
/// page/feature isn't built yet show a "coming soon" notice (same convention as
/// the profile feature grid). Reached from the Settings tile inside the user's
/// own profile.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    final confirmed = await _confirm(
      title: context.tr('app.are_you_sure'),
    );
    if (confirmed != true || !mounted) return;
    await CacheManager.clear();
    if (!mounted) return;
    context.go(AuthRoutes.splash);
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('app.coming_soon'))),
    );
  }

  /// Privacy/Terms: open the admin-set external URL when present, otherwise fall
  /// back to the in-app CMS page (default behaviour).
  void _openPrivacy() {
    final url = AppInfoProvider.current.privacyUrl;
    (url != null && url.isNotEmpty)
        ? openStoreUrl(url)
        : context.push('/page/privacy-policy');
  }

  void _openTerms() {
    final url = AppInfoProvider.current.termsUrl;
    (url != null && url.isNotEmpty)
        ? openStoreUrl(url)
        : context.push('/page/terms');
  }

  /// Delete the user's own account (revoke tokens + soft-delete on the backend),
  /// then clear the session and return to the splash — same exit as logout.
  Future<void> _deleteAccount() async {
    final confirmed = await _confirm(
      title: context.tr('app.delete_account'),
      message: context.tr('app.delete_account_confirm'),
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _AccountApi().deleteAccount();
    await CacheManager.clear();
    if (!mounted) return;
    context.go(AuthRoutes.splash);
  }

  /// Dark-themed confirm dialog matching the mockup (frosted card, pink/red CTA).
  Future<bool?> _confirm({
    required String title,
    String? message,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GradientCard(
          radius: 20,
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.lumiaTextPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: 10.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.lumiaTextSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        ctx.tr('app.cancel'),
                        style: const TextStyle(
                          color: ColorManager.lumiaTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: destructive
                              ? const [Color(0xFFFF5A6E), Color(0xFFD81B60)]
                              : ColorManager.pinkCtaGradient,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          ctx.tr('app.confirm'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Language is functional — pick from the supported locales.
  Future<void> _pickLanguage() async {
    final localeNotifier = context.read<LocaleNotifier>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorManager.lumiaBgMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: localeNotifier.supportedLocales.map((locale) {
            final selected =
                locale.languageCode == localeNotifier.locale.languageCode;
            // Native name from the backend's active languages (العربية, Français,
            // हिन्दी, …) so any admin-added language shows correctly.
            final label = localeNotifier.nameFor(locale.languageCode);
            return ListTile(
              title: Text(
                label,
                style: const TextStyle(color: ColorManager.lumiaTextPrimary),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: ColorManager.lumiaAccent)
                  : null,
              onTap: () {
                localeNotifier.setLocale(locale);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
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
        title: Text(
          context.tr('app.settings'),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            children: [
              GradientCard(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    _tile(
                      icon: Icons.language,
                      tint: const Color(0xFF26C6DA),
                      labelKey: 'app.language',
                      onTap: _pickLanguage,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              GradientCard(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    _tile(
                      icon: Icons.block,
                      tint: const Color(0xFFEC407A),
                      labelKey: 'app.block_list',
                      onTap: _comingSoon,
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.privacy_tip_outlined,
                      tint: const Color(0xFF66BB6A),
                      labelKey: 'app.privacy_policy',
                      onTap: _openPrivacy,
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.description_outlined,
                      tint: const Color(0xFF26A69A),
                      labelKey: 'app.terms_of_service',
                      onTap: _openTerms,
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.support_agent,
                      tint: const Color(0xFF42A5F5),
                      labelKey: 'app.contact_us',
                      onTap: () => context.push('/contact-us'),
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.info_outline,
                      tint: const Color(0xFF7C4DFF),
                      labelKey: 'app.about_us',
                      onTap: () => context.push('/page/about-us'),
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.delete_outline,
                      tint: const Color(0xFFFF5A6E),
                      labelKey: 'app.delete_account',
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              // Logout — distinct, destructive styling (matches the reference).
              GradientCard(
                onTap: _logout,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Center(
                  child: Text(
                    context.tr('app.logout'),
                    style: TextStyle(
                      color: ColorManager.walletRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _tile({
    required IconData icon,
    required Color tint,
    required String labelKey,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: tint, size: 19.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                context.tr(labelKey),
                style: TextStyle(
                  color: ColorManager.lumiaTextPrimary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13.sp,
              color: ColorManager.lumiaTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountApi extends BaseApiService {
  Future<void> deleteAccount() async {
    await post('/account/delete', fromJson: (_) => true);
  }
}
