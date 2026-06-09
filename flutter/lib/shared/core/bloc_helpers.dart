import 'package:flutter/material.dart';
import 'package:utd_app/shared/core/enums.dart';

/// Returns [RequestState.loaded] if [data] is non-null and non-empty,
/// otherwise [RequestState.empty].
RequestState handleLoadedResponse<T>(T? data) {
  if (data == null) return RequestState.empty;
  if (data is List && data.isEmpty) return RequestState.empty;
  return RequestState.loaded;
}

/// Returns [RequestState.error] for any failure, or a more specific state
/// based on the error type.
RequestState handleErrorResponse(dynamic error) {
  return RequestState.error;
}

/// Merges paginated results: if [currentPage] == 1, returns [result];
/// otherwise appends [result] to [currentList].
List<T> handlePaginationResponse<T>({
  required List<T>? result,
  required List<T> currentList,
  required int currentPage,
}) {
  final newItems = result ?? [];
  if (currentPage == 1) return newItems;
  return [...currentList, ...newItems];
}

/// Triggers [fun] when the scroll controller reaches near the bottom
/// and there are more pages to load.
void handleScrollListener({
  required ScrollController controller,
  required int currentPage,
  required int lastPage,
  required VoidCallback fun,
}) {
  if (!controller.hasClients) return;
  final maxScroll = controller.position.maxScrollExtent;
  final currentScroll = controller.offset;
  if (currentScroll >= maxScroll * 0.9 && currentPage < lastPage) {
    fun();
  }
}
