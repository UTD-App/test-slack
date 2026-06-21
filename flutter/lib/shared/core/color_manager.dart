import 'package:flutter/material.dart';

/// Centralized color definitions used across the app.
///
/// Uses semantic naming for maintainability and theming consistency.
class ColorManager {
  ColorManager._();

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color appBarTitlegrey = Color(0xFF4D4D4D);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color black = Color(0xFF000000);
  static const Color blackColor = Color(0xFF0F172A);
  static const Color black2 = Color(0xFF1E293B);

  // Greys
  static const Color grey = Color(0xFF9CA3AF);
  static const Color lightGray = Color(0xFFD1D5DB);
  static const Color lightGray2 = Color(0xFF94A3B8);
  static const Color greyTextColor = Color(0xFF6B7280);
  static const Color inactiveColor = Color(0xFFB0BEC5);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // Accent
  static const Color bColor = Color(0xFFEF4444);
  static const Color bgLevel = Color(0xFF3B82F6);
  static const Color textTabBar = Color(0xFF1E293B);
  static const Color buleShadw = Color(0x332563EB);
  static const Color redAccount = Color(0xFFB71C1C);

  // Transparent
  static const Color transparent = Colors.transparent;

  // Gender gradients
  static const List<Color> maleContainer = [
    Color(0xFF42A5F5),
    Color(0xFF1E88E5),
  ];
  static const List<Color> femaleContainer = [
    Color(0xFFEC407A),
    Color(0xFFD81B60),
  ];

  // ── Lumia dark-purple theme (live-app aesthetic) ──────────────
  // Shared design tokens for the dark-purple app theme + profile page.
  // Defined in base so packages (which import package:utd_app/...) reuse them.
  // Bright violet–magenta palette sampled from the NEXO/Realmatch mockup: a
  // magenta-tinted purple easing to a blue-violet, with translucent-looking
  // (frosted) lighter cards. Brighter & more saturated than pure indigo.
  static const Color lumiaBgDark = Color(0xFF463394); // scaffold / surface base
  static const Color lumiaBgMedium = Color(0xFF463680); // nav bar / sheets
  static const Color lumiaCardBg = Color(0xFF6750AE); // frosted-look cards
  static const Color lumiaCardBorder = Color(0xFF8E72D2);
  static const Color lumiaAccent = Color(0xFFBE4AFF);
  static const Color lumiaAccentLight = Color(0xFFD9A0FF);
  static const Color lumiaGold = Color(0xFFFFD700);
  static const Color lumiaTextPrimary = Color(0xFFFFFFFF);
  static const Color lumiaTextSecondary = Color(0xFFD0C0EE);
  static const Color walletGreen = Color(0xFF2ED9B0); // diamond card
  static const Color walletRed = Color(0xFFFF5A6E); // coin card

  // Page gradient: magenta-purple at the top easing to a blue-violet at the
  // bottom (matches the mockup's live/chat/profile/messages backgrounds).
  static const List<Color> lumiaBgGradient = [
    Color(0xFF7E3E97),
    Color(0xFF583C9E),
    Color(0xFF3D2D86),
  ];
  static const List<Color> lumiaCardGradient = [
    Color(0xFF6E50B2),
    Color(0xFF513B98),
  ];
  static const List<Color> lumiaAccentGradient = [
    Color(0xFFB44AFF),
    Color(0xFF8B2FC9),
  ];
  // Selected bottom-nav item gradient (purple → pink).
  static const List<Color> navSelectedGradient = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  // ── Auth / onboarding aesthetic (brighter violet) ─────────────
  // Onboarding & picker screens in the mockup use a brighter violet
  // gradient than the dark in-app screens (lumiaBgGradient).
  static const List<Color> authBgGradient = [
    Color(0xFF6A4AE0),
    Color(0xFF4226A6),
    Color(0xFF2A1556),
  ];

  // Bright pink CTA gradient ("Done" / "Submit" buttons in the mockup).
  static const List<Color> pinkCtaGradient = [
    Color(0xFFF22A8C),
    Color(0xFFFF5BA6),
  ];

  // Frosted overlay tints used on top of the gradient backgrounds.
  static const Color frostedFill = Color(0x1AFFFFFF); // 10% white
  static const Color frostedBorder = Color(0x33FFFFFF); // 20% white
}
