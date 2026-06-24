import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../data/emoji_api_service.dart';
import '../../data/emoji_remote_datasource.dart';
import '../../domain/emoji_model.dart';
import '../../domain/emoji_repository.dart';
import '../bloc/emoji_bloc.dart';
import '../emoji_strings.dart';
import 'emoji_grid_page.dart';

class EmojiPickerSheet extends StatelessWidget {
  final int roomId;
  final ValueChanged<EmojiModel>? onEmojiSelected;

  const EmojiPickerSheet({
    super.key,
    required this.roomId,
    this.onEmojiSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required int roomId,
    ValueChanged<EmojiModel>? onEmojiSelected,
  }) {
    final repository = EmojiRepositoryImpl(
      remoteDataSource: EmojiRemoteDataSourceImpl(
        apiService: EmojiApiService(),
      ),
    );

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => EmojiBloc(repository: repository)
          ..add(const LoadEmojiCategoriesEvent()),
        child: EmojiPickerSheet(
          roomId: roomId,
          onEmojiSelected: onEmojiSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _buildCategoryTabs(),
          const SizedBox(height: 4),
          Expanded(child: _buildEmojiGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return BlocBuilder<EmojiBloc, EmojiState>(
      buildWhen: (prev, curr) =>
          prev.categories != curr.categories ||
          prev.categoryId != curr.categoryId,
      builder: (context, state) {
        if (state.categoriesState == RequestState.loading) {
          return const SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: state.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = state.categories[index];
              final isActive = state.categoryId == category.id;
              return GestureDetector(
                onTap: () {
                  context.read<EmojiBloc>()
                    ..add(SetEmojiCategoryIdEvent(categoryId: category.id))
                    ..add(LoadEmojisByCategoryEvent(
                        categoryId: category.id));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isActive ? Colors.blue : Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Text(
                      category.title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmojiGrid() {
    return BlocBuilder<EmojiBloc, EmojiState>(
      builder: (context, state) {
        final s = EmojiStrings.of(context);
        final categoryId = state.categoryId;
        if (categoryId == null) {
          return Center(child: Text(s.selectCategory));
        }

        final reqState =
            state.categoryReqStates[categoryId] ?? RequestState.idle;
        final emojis = state.categoryEmojis[categoryId] ?? [];

        if (reqState == RequestState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reqState == RequestState.empty || emojis.isEmpty) {
          return Center(child: Text(s.noEmojis));
        }

        if (reqState == RequestState.error) {
          return Center(child: Text(state.message ?? s.errorLoading));
        }

        return EmojiGridPage(
          emojis: emojis,
          onEmojiSelected: (emoji) {
            onEmojiSelected?.call(emoji);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
