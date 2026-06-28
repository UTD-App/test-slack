import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/profile/profile_navigator.dart';

import '../../../../core/reels_strings.dart';
import '../../../domain/repositories/reels_repository.dart';
import '../../bloc/reels_likes/reels_likes_cubit.dart';
import '../../utils/media.dart';
import '../../utils/reactions.dart';
import '../../utils/time.dart';

Future<void> showReelsLikes(BuildContext context, int reelId) {
  final repo = context.read<ReelsRepository>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => ReelsLikesCubit(repo, reelId)..load(),
      child: const _LikesSheet(),
    ),
  );
}

class _LikesSheet extends StatefulWidget {
  const _LikesSheet();
  @override
  State<_LikesSheet> createState() => _LikesSheetState();
}

class _LikesSheetState extends State<_LikesSheet> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<ReelsLikesCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Text(context.tr(ReelsStrings.likes), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const Divider(height: 16),
          Expanded(
            child: BlocBuilder<ReelsLikesCubit, ReelsLikesState>(
              builder: (context, state) {
                if (state.status == LikesStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.likes.isEmpty) {
                  return Center(child: Text(context.tr(ReelsStrings.noLikes), style: const TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(8),
                  itemCount: state.likes.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= state.likes.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final l = state.likes[i];
                    void openProfile() {
                      if (l.userId > 0) ProfileNavigator.open(context, userId: l.userId);
                    }
                    return ListTile(
                      onTap: openProfile,
                      leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatarUrl(l.userImage, l.userName))),
                      title: Text(l.userName.isEmpty ? context.tr(ReelsStrings.user) : l.userName,
                          style: const TextStyle(color: Colors.black87)),
                      subtitle: Text(timeAgo(l.createdAt, arabic: isArabic),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(reactionByType(l.reactionType)?.emoji ?? '👍',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(context.tr(ReelsStrings.reactionLabelKey(l.reactionType)),
                              style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
