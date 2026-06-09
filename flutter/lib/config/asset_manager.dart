/// Asset paths used in the moments feature.
class AssetsManager {
  AssetsManager._();

  static const String _basePath = 'assets';
  // static const String _iconsPath = '$_basePath/icons';
  static const String _imagesPath = '$_basePath/images';
  static const String _lottiePath = '$_basePath/lottie';

  // lottie
  static const String error = '$_lottiePath/error.json';
  static const String noWifi = '$_lottiePath/no_wifi.json';
  static const String empty = '$_lottiePath/empty.json';
  static const String loading = '$_lottiePath/loading.json';

  // Images
  static const String ban = '$_imagesPath/ban.png';
}
