/// Centralized asset paths for the profile package.
///
/// All paths are package-qualified (`packages/profile/...`) so they resolve
/// from the host app (`utd_app`) once the package declares them in its
/// pubspec `flutter: assets:` block. Keep every asset reference here so the
/// `packages/profile/` prefix is never forgotten or duplicated.
class ProfileAssets {
  ProfileAssets._();

  static const String _icons = 'packages/profile/assets/icons';
  static const String _images = 'packages/profile/assets/images';

  // Avatar frame overlay + SVIP banner background
  static const String avatarFrame = '$_images/avatar_frame.png';
  static const String svipBannerBg = '$_images/me_premium_entrance_bg.png';

  // Level badges
  static const String icLevel = '$_icons/ic_level.webp';
  static const String meCharm = '$_icons/me_charm.webp';

  // Wallet card backgrounds
  static const String icCoinBg = '$_icons/ic_coin_bg_v2.webp';
  static const String icCrystalBg = '$_icons/ic_crystal_bg_v2.webp';

  // Feature grid icons
  static const String icStore = '$_icons/ic_store.webp';
  static const String icFamily = '$_icons/ic_family.webp';

  // Spare icons (available for a future settings/extras section)
  static const String icDecoration = '$_icons/ic_decoration.webp';
  static const String icInviteFriends = '$_icons/ic_invite_friends.png';
  static const String icPrivacy = '$_icons/ic_privacy.webp';
  static const String icSetting = '$_icons/ic_setting.webp';
  static const String icCustomer = '$_icons/ic_costumer.webp';
}
