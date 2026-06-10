import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'emoji_category_model.dart';
import 'emoji_model.dart';

abstract class EmojiRepository {
  Future<Result<BaseResponse<List<EmojiCategoryModel>>>> getCategories();
  Future<Result<BaseResponse<List<EmojiModel>>>> getEmojis(int categoryId);
}

abstract class EmojiRemoteDataSource {
  Future<Result<BaseResponse<List<EmojiCategoryModel>>>> getCategories();
  Future<Result<BaseResponse<List<EmojiModel>>>> getEmojis(int categoryId);
}

class EmojiRepositoryImpl implements EmojiRepository {
  final EmojiRemoteDataSource remoteDataSource;

  EmojiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<List<EmojiCategoryModel>>>> getCategories() =>
      remoteDataSource.getCategories();

  @override
  Future<Result<BaseResponse<List<EmojiModel>>>> getEmojis(int categoryId) =>
      remoteDataSource.getEmojis(categoryId);
}
