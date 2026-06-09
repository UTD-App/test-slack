/// Centralized asset path definitions.
///
/// Organizes all asset references into logical categories
/// so paths are never hardcoded in widgets.
class AssetManager {
  AssetManager._();

  // Base paths
  static const String _baseImagePath = 'packages/authentication/assets/images/';
  static const String _baseIconPath = 'packages/authentication/assets/icons/';

  // ── Images ──────────────────────────────────────────────
  static const String logo = '${_baseImagePath}logo.png';

  // Onboarding
  static const String onboarding1 = '${_baseImagePath}onboarding1.png';
  static const String onboarding2 = '${_baseImagePath}onboarding2.png';
  static const String onboarding3 = '${_baseImagePath}onboarding3.png';

  // Gender / Profile
  static const String man = '${_baseIconPath}man.png';
  static const String manInfo = '${_baseImagePath}man.png';
  static const String women = '${_baseImagePath}woman.png';
  static const String femaleIconInfo = '${_baseIconPath}female_icon.png';
  static const String userAddInfo = '${_baseIconPath}user_add_info.png';

  // ── Icons ───────────────────────────────────────────────
  static const String phone = '${_baseIconPath}phone.png';
  static const String google_ = '${_baseIconPath}google_intro.png';
  static const String apple = '${_baseIconPath}apple.png';
  static const String huawei = '${_baseIconPath}huawei.png';
  static const String mobileValidate = '${_baseIconPath}mobile_validate.png';
}
