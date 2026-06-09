import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/repositories/moment_repository.dart';
import '../../bloc/moment_likes/moment_likes_cubit.dart';
import '../../utils/time.dart';
import 'moment_avatar.dart';

Future<void> showMomentLikes(BuildContext context, int momentId) {
  final repo = context.read<MomentRepository>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => MomentLikesCubit(repo, momentId)..load(),
      child: const _LikesSheet(),
    ),
  );
}

class _LikesSheet extends StatelessWidget {
  const _LikesSheet();

  @override
  Widget build(BuildContext context) {
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
          Text(context.tr(MomentStrings.likes), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const Divider(height: 16),
          Expanded(
            child: BlocBuilder<MomentLikesCubit, MomentLikesState>(
              builder: (context, state) {
                if (state.status == LikesStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.likes.isEmpty) {
                  return Center(child: Text(context.tr(MomentStrings.noLikes), style: const TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.likes.length,
                  itemBuilder: (_, i) {
                    final l = state.likes[i];
                    return ListTile(
                      leading: MomentAvatar(image: l.userImage, name: l.userName, radius: 20),
                      title: Text(l.userName.isEmpty ? context.tr(MomentStrings.user) : l.userName,
                          style: const TextStyle(color: Colors.black87)),
                      subtitle: Text(timeAgo(l.createdAt),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                      trailing: const Icon(Icons.favorite, color: Colors.red, size: 18),
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
