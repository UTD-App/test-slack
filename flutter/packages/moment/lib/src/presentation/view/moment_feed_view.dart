import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/toast_manager.dart';

import '../../../core/moment_strings.dart';
import '../bloc/moment_feed/moment_feed_bloc.dart';
import '../bloc/moment_feed/moment_feed_event.dart';
import '../bloc/moment_feed/moment_feed_state.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/moment_card.dart';
import 'widgets/moment_comments_sheet.dart';
import 'widgets/moment_likes_sheet.dart';
import 'widgets/report_moment_dialog.dart';

/// The moments list body (no Scaffold/AppBar/FAB) — a scrollable feed of
/// [MomentCard]s wired to the ambient [MomentFeedBloc], with pull-to-refresh,
/// infinite scroll, and the full card interactions (like / comments / likes /
/// report / delete / image preview).
///
/// Used both by [MomentFeedPage] (wrapped in a Scaffold) and by the
/// server-driven `moment.feed` Stac widget so a UTD-Studio screen renders the
/// real, fully-interactive feed instead of a static layout.
class MomentFeedView extends StatefulWidget {
  const MomentFeedView({super.key});

  @override
  State<MomentFeedView> createState() => _MomentFeedViewState();
}

class _MomentFeedViewState extends State<MomentFeedView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MomentFeedBloc>();
    if (bloc.state.status == FeedStatus.initial) {
      bloc.add(const FeedRefreshRequested());
    }
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        context.read<MomentFeedBloc>().add(const FeedLoadMoreRequested());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openImage(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: InteractiveViewer(
            child: Center(child: Image.network(url, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MomentFeedBloc, MomentFeedState>(
      builder: (context, state) {
        if (state.status == FeedStatus.loading && state.moments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == FeedStatus.failure && state.moments.isEmpty) {
          return _ErrorView(
            message: state.error ?? context.tr(MomentStrings.somethingWrong),
            onRetry: () => context.read<MomentFeedBloc>().add(const FeedRefreshRequested()),
          );
        }
        if (state.moments.isEmpty) {
          return Center(child: Text(context.tr(MomentStrings.empty), style: const TextStyle(color: Colors.grey)));
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<MomentFeedBloc>().add(const FeedRefreshRequested());
            await context.read<MomentFeedBloc>().stream.firstWhere((s) => s.status != FeedStatus.loading);
          },
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: state.moments.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= state.moments.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final moment = state.moments[i];
              return MomentCard(
                moment: moment,
                onReact: (type) => context.read<MomentFeedBloc>().add(MomentReacted(moment, type)),
                onOpenLikes: () => showMomentLikes(context, moment.id),
                onOpenComments: () {
                  final feedBloc = context.read<MomentFeedBloc>();
                  showMomentComments(
                    context,
                    moment.id,
                    momentOwnerId: moment.userId,
                    onCommentAdded: () => feedBloc.add(MomentCommentAdded(moment.id)),
                    onCommentDeleted: (n) => feedBloc.add(MomentCommentRemoved(moment.id, n)),
                  );
                },
                onGiftSent: (coins) => context.read<MomentFeedBloc>().add(MomentGiftSent(moment.id, coins)),
                onReport: () async {
                  final ok = await showReportMomentDialog(context, moment.id);
                  if (ok && context.mounted) {
                    ToastManager.showToast(context, message: context.tr(MomentStrings.reportedThanks));
                  }
                },
                onDelete: () async {
                  final confirm = await showThemedConfirm(
                    context,
                    title: context.tr(MomentStrings.deleteConfirm),
                    confirmText: context.tr(MomentStrings.delete),
                    cancelText: context.tr(MomentStrings.cancel),
                    destructive: true,
                  );
                  if (confirm && context.mounted) {
                    context.read<MomentFeedBloc>().add(MomentDeleted(moment.id));
                    ToastManager.showToast(context, message: context.tr(MomentStrings.deleted));
                  }
                },
                onTapImage: _openImage,
              );
            },
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.tr(MomentStrings.retry))),
        ],
      ),
    );
  }
}
