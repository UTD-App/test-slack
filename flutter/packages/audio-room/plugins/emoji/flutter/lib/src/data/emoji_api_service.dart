import 'package:utd_app/network/services/base_api_service.dart';

class EmojiApiService extends BaseApiService {
  String categoriesPath() => '/emojis/categories';
  String emojisPath() => '/emojis';
}
