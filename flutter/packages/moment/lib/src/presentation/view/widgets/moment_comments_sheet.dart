import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/repositories/moment_repository.dart';
import '../../bloc/moment_comments/moment_comments_cubit.dart';
import '../../utils/time.dart';
import 'moment_avatar.dart';

Future<void> showMomentComments(BuildContext context, int momentId, {VoidCallback? onCommentAdded}) {
  final repo = context.read<MomentRepository>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => MomentCommentsCubit(repo, momentId)..load(),
      child: _CommentsSheet(onCommentAdded: onCommentAdded),
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final VoidCallback? onCommentAdded;
  const _CommentsSheet({this.onCommentAdded});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _SheetHandle(title: context.tr(MomentStrings.comments)),
          Expanded(
            child: BlocBuilder<MomentCommentsCubit, MomentCommentsState>(
              builder: (context, state) {
                if (state.status == CommentsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.comments.isEmpty) {
                  return Center(child: Text(context.tr(MomentStrings.noComments), style: const TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) {
                    final c = state.comments[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MomentAvatar(image: c.userImage, name: c.userName, radius: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.userName.isEmpty ? context.tr(MomentStrings.user) : c.userName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text(c.comment, style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text(timeAgo(c.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: context.tr(MomentStrings.writeComment),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<MomentCommentsCubit, MomentCommentsState>(
                    builder: (context, state) => IconButton.filled(
                      onPressed: state.isSubmitting
                          ? null
                          : () async {
                              final ok = await context.read<MomentCommentsCubit>().add(_controller.text);
                              if (ok) {
                                _controller.clear();
                                widget.onCommentAdded?.call();
                              }
                            },
                      icon: state.isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final String title;
  const _SheetHandle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const Divider(height: 16),
      ],
    );
  }
}
