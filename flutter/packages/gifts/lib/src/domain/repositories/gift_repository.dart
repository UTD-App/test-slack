import 'package:utd_app/network/models/api_response.dart';

import '../entities/gift.dart';
import '../entities/gift_category.dart';
import '../entities/gift_history_item.dart';

abstract class GiftRepository {
  Future<Result<List<GiftCategory>>> fetchCategories();

  Future<Result<List<Gift>>> fetchGifts({int? categoryId});

  Future<Result<List<GiftHistoryItem>>> fetchHistory({String type = 'received', int page = 1});

  /// Send a gift in a host context (e.g. moment). Posts to the host feature's
  /// gift endpoint resolved from [contextType].
  Future<Result<bool>> sendInContext({
    required String contextType,
    required int contextId,
    required int giftId,
    required int quantity,
  });
}
