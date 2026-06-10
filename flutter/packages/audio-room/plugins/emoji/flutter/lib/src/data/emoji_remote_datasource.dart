import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/emoji_category_model.dart';
import '../domain/emoji_model.dart';
import '../domain/emoji_repository.dart';
import 'emoji_api_service.dart';

class EmojiRemoteDataSourceImpl implements EmojiRemoteDataSource {
  final EmojiApiService apiService;

  EmojiRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<List<EmojiCategoryModel>>>> getCategories() async {
    return apiService.get(
      apiService.categoriesPath(),
      fromJson: (json) => BaseResponse<List<EmojiCategoryModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) =>
                EmojiCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<List<EmojiModel>>>> getEmojis(
      int categoryId) async {
    return apiService.get(
      apiService.emojisPath(),
      queryParameters: {'category_id': categoryId},
      fromJson: (json) => BaseResponse<List<EmojiModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => EmojiModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}
