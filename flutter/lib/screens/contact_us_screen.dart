import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../localization/localization.dart';
import '../services/launch_gate_service.dart';
import '../shared/core/color_manager.dart';
import '../shared/widgets/app_logo.dart';
import '../shared/widgets/gradient_background.dart';
import '../shared/widgets/gradient_card.dart';
import 'launch_gate_screen.dart' show openStoreUrl;

/// "Contact Us" — shows every contact/social channel an admin filled in under
/// Admin → App Settings (support phone/email + the social links). Each row opens
/// the matching app/link (tel:/mailto:/wa.me/https). Only configured channels
/// are shown; if none are set, a friendly empty state appears. All data comes
/// from [AppInfoProvider] (the launch bootstrap), so it stays in sync with the
/// dashboard without any extra network call.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final info = AppInfoProvider.current;
    final entries = <_ContactEntry>[];

    // Direct contact (support phone/email live outside the social-links list).
    final phone = info.supportPhone?.trim() ?? '';
    if (phone.isNotEmpty) {
      entries.add(_ContactEntry(
        icon: Icons.phone,
        tint: const Color(0xFF34A853),
        label: context.tr('app.phone'),
        url: 'tel:$phone',
      ));
    }
    final email = info.supportEmail?.trim() ?? '';
    if (email.isNotEmpty) {
      entries.add(_ContactEntry(
        icon: Icons.email_outlined,
        tint: const Color(0xFFEA4335),
        label: context.tr('app.email'),
        url: 'mailto:$email',
      ));
    }

    // The admin-managed contact links (dynamic CRUD list), in admin order.
    // Falls back to the legacy flat `social` map for older backends.
    final links = info.socialLinks.isNotEmpty
        ? info.socialLinks
        : _legacyLinks(info.social);
    for (final link in links) {
      final entry = _entryFor(context, link);
      if (entry != null) entries.add(entry);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          context.tr('app.contact_us'),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: entries.isEmpty
              ? _empty(context)
              : ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  children: [
                    GradientCard(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Column(
                        children: [
                          for (var i = 0; i < entries.length; i++) ...[
                            if (i > 0) _divider(),
                            _tile(context, entries[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.support_agent,
                  size: 48.sp, color: ColorManager.lumiaTextSecondary),
              SizedBox(height: 12.h),
              Text(
                context.tr('app.contact_us_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.lumiaTextSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: ColorManager.frostedBorder,
        ),
      );

  Widget _tile(BuildContext context, _ContactEntry e) {
    return InkWell(
      onTap: () => openStoreUrl(e.url),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: e.tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              // A custom link ships an uploaded icon image; known platforms use
              // the built-in brand icon. Any image load failure falls back to it.
              child: e.iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        e.iconUrl!,
                        width: 20.w,
                        height: 20.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(e.icon, color: e.tint, size: 19.sp),
                      ),
                    )
                  : Icon(e.icon, color: e.tint, size: 19.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                e.label,
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

class _ContactEntry {
  final IconData icon;

  /// Resolved URL of an uploaded custom icon; when null the built-in [icon] is
  /// drawn instead (known platforms).
  final String? iconUrl;
  final Color tint;
  final String label;
  final String url;

  const _ContactEntry({
    required this.icon,
    required this.tint,
    required this.label,
    required this.url,
    this.iconUrl,
  });
}

/// A known contact platform's built-in appearance. Its keys MUST match the
/// backend `SocialPlatforms::KNOWN` registry (same key -> same platform), so a
/// platform the admin picks renders with the right brand icon and color without
/// shipping an image.
class _Platform {
  final IconData icon;
  final Color color;
  final String label;
  final bool whatsapp; // true => value is a phone, open as a wa.me deep link

  const _Platform(this.icon, this.color, this.label, {this.whatsapp = false});
}

const _platformRegistry = <String, _Platform>{
  'whatsapp': _Platform(Icons.chat, Color(0xFF25D366), 'WhatsApp', whatsapp: true),
  'website': _Platform(Icons.public, Color(0xFF42A5F5), 'Website'),
  'facebook': _Platform(Icons.facebook, Color(0xFF1877F2), 'Facebook'),
  'instagram': _Platform(Icons.camera_alt_outlined, Color(0xFFE4405F), 'Instagram'),
  'twitter': _Platform(Icons.alternate_email, Color(0xFF1DA1F2), 'Twitter / X'),
  'youtube': _Platform(Icons.smart_display, Color(0xFFFF0000), 'YouTube'),
  'tiktok': _Platform(Icons.music_note, Color(0xFF69C9D0), 'TikTok'),
  'snapchat': _Platform(Icons.chat_bubble, Color(0xFFFFC400), 'Snapchat'),
  'telegram': _Platform(Icons.send, Color(0xFF29A9EB), 'Telegram'),
};

/// Tint for a custom link that didn't specify a color.
const _kCustomTint = Color(0xFF7E8AA2);

/// Turn one admin-managed link into a renderable tile, or null when it has no
/// usable value. Known platforms get their brand icon/color from the registry;
/// a custom link uses its uploaded icon image + chosen color.
_ContactEntry? _entryFor(BuildContext context, SocialLink link) {
  final value = link.value.trim();
  if (value.isEmpty) return null;

  final known = _platformRegistry[link.platform];
  final tint = _parseHex(link.color) ?? known?.color ?? _kCustomTint;

  // Prefer a locale-aware label for the generic "Website"; brand names are the
  // same in every language, so the registry/admin label is fine for the rest.
  final String label;
  if (link.platform == 'website') {
    label = context.tr('app.website');
  } else if (known != null) {
    label = known.label;
  } else {
    label = link.label.isNotEmpty ? link.label : link.platform;
  }

  final url =
      (known?.whatsapp ?? false) ? _whatsAppUrl(value) : _httpUrl(value);

  return _ContactEntry(
    icon: known?.icon ?? Icons.link,
    iconUrl: known == null ? AppLogo.resolveUrl(link.icon) : null,
    tint: tint,
    label: label,
    url: url,
  );
}

/// Adapt the legacy flat {platform: url} map (older backends) to the new list,
/// so the same rendering path covers both.
List<SocialLink> _legacyLinks(Map<String, String> social) {
  final out = <SocialLink>[];
  for (final key in _platformRegistry.keys) {
    final v = social[key]?.trim() ?? '';
    if (v.isNotEmpty) {
      out.add(SocialLink(
        platform: key,
        label: _platformRegistry[key]!.label,
        value: v,
      ));
    }
  }
  return out;
}

/// Parse a `#RRGGBB` (or `#AARRGGBB`) hex string into a [Color]; null if absent
/// or malformed (caller falls back to a default tint).
Color? _parseHex(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Ensure a tappable web URL — admins may paste a bare domain/handle.
String _httpUrl(String v) {
  final t = v.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  return 'https://$t';
}

/// WhatsApp accepts either a full link or a phone number; turn a number into a
/// wa.me deep link (digits only, keeps a leading country code).
String _whatsAppUrl(String v) {
  final t = v.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  return 'https://wa.me/$digits';
}
