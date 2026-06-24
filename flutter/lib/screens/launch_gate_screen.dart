import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utd_app/services/launch_gate_service.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

/// Full-screen blocker shown at launch when the backend reports either
/// maintenance mode or a forced update. It replaces the whole app shell, so it
/// is intentionally self-contained (no router, no providers, inline strings).
class LaunchGateScreen extends StatelessWidget {
  final LaunchGateResult result;

  /// Active locale code ('ar' | 'en') for the inline copy.
  final String localeCode;

  const LaunchGateScreen({
    super.key,
    required this.result,
    required this.localeCode,
  });

  bool get _isAr => localeCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final maintenance = result.maintenance;

    final icon = maintenance ? Icons.build_circle_outlined : Icons.system_update;
    final title = maintenance
        ? (_isAr ? 'التطبيق تحت الصيانة' : 'Under maintenance')
        : (_isAr ? 'تحديث مطلوب' : 'Update required');

    final message = maintenance
        ? (result.maintenanceMessage?.trim().isNotEmpty == true
              ? result.maintenanceMessage!
              : (_isAr
                    ? 'نقوم ببعض التحسينات حاليًا. من فضلك حاول لاحقًا.'
                    : 'We are making some improvements. Please try again later.'))
        : (_isAr
              ? 'إصدار جديد متاح. يجب تحديث التطبيق للمتابعة.'
              : 'A new version is available. Please update the app to continue.');

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 88, color: ColorManager.lumiaTextPrimary),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ColorManager.lumiaTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ColorManager.lumiaTextSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (!maintenance && (result.storeUrl?.isNotEmpty ?? false))
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: ColorManager.pinkCtaGradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => openStoreUrl(result.storeUrl!),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(_isAr ? 'تحديث الآن' : 'Update now'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

/// Open a store/external URL (no-op on a malformed URL).
Future<void> openStoreUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Non-blocking "update available" prompt for the optional-update case. The
/// user can dismiss it ("Later") or jump to the store.
Future<void> showSoftUpdateDialog(
  BuildContext context, {
  required String? storeUrl,
  required String localeCode,
}) {
  final isAr = localeCode == 'ar';
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isAr ? 'تحديث متاح' : 'Update available'),
      content: Text(
        isAr
            ? 'يتوفّر إصدار جديد من التطبيق. ننصح بالتحديث.'
            : 'A new version of the app is available. We recommend updating.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(isAr ? 'لاحقًا' : 'Later'),
        ),
        if (storeUrl != null && storeUrl.isNotEmpty)
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openStoreUrl(storeUrl);
            },
            child: Text(isAr ? 'تحديث' : 'Update'),
          ),
      ],
    ),
  );
}
