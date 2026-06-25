import 'package:utd_app/network/models/api_response.dart';

import '../../domain/entities/gift.dart';
import '../../domain/entities/gift_category.dart';
import '../../domain/entities/gift_history_item.dart';
import '../../domain/repositories/gift_repository.dart';
import '../datasources/gift_api_service.dart';

class GiftRepositoryImpl implements GiftRepository {
  final GiftApiService api;

  GiftRepositoryImpl(this.api);

  @override
  Future<Result<List<GiftCategory>>> fetchCategories() async {
    final res = await api.fetchCategories();
    return res.map((list) => list.cast<GiftCategory>());
  }

  @override
  Future<Result<List<Gift>>> fetchGifts({int? categoryId}) async {
    final res = await api.fetchGifts(categoryId: categoryId);
    return res.map((list) => list.cast<Gift>());
  }

  @override
  Future<Result<List<GiftHistoryItem>>> fetchHistory({String type = 'received', int page = 1}) async {
    final res = await api.fetchHistory(type: type, page: page);
    return res.map((list) => list.cast<GiftHistoryItem>());
  }

  @override
  Future<Result<bool>> sendInContext({
    required String contextType,
    required int contextId,
    required int giftId,
    required int quantity,
  }) {
    return api.sendInContext(
      contextType: contextType,
      contextId: contextId,
      giftId: giftId,
      quantity: quantity,
    );
  }
}
