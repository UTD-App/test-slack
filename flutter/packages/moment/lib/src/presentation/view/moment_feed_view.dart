import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

import '../../../core/moment_strings.dart';
import '../../domain/entities/moment_entity.dart';
import '../bloc/moment_feed/moment_feed_bloc.dart';
import '../bloc/moment_feed/moment_feed_event.dart';
import '../bloc/moment_feed/moment_feed_state.dart';
import '../utils/media.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/moment_card.dart';
import 'widgets/moment_comments_sheet.dart';
import 'widgets/moment_feed_skeleton.dart';
import 'widgets/moment_gallery_viewer.dart';
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

  /// Bumped on every completed refresh. It's woven into each item's key so the
  /// reshuffled cards re-mount and replay their staggered entrance animation —
  /// turning the random reorder into a smooth, intentional transition.
  int _generation = 0;

  /// Moment ids seen so far — used to detect genuinely new posts on refresh.
  final Set<int> _knownIds = {};

  /// Shows the floating "new moments" pill when a refresh brought new posts
  /// while the user was scrolled away from the top.
  bool _showNewPill = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MomentFeedBloc>();
    if (bloc.state.status == FeedStatus.initial) {
      // Cache-first: paint the last-seen feed instantly, then refresh.
      bloc.add(const FeedStarted());
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

  void _openGallery(List<String> images, int index) {
    MomentGalleryViewer.open(context, images: images, initialIndex: index);
  }

  /// Warm the shared on-disk cache with the first image of the next batch of
  /// cards so scrolling stays smooth (capped to avoid a download stampede).
  void _prefetch(List<MomentEntity> moments) {
    for (final m in moments.take(12)) {
      if (m.images.isEmpty) continue;
      final url = resolveMediaUrl(m.images.first);
      if (url.isNotEmpty) {
        AppCacheManager.instance.prefetch(url); // fire-and-forget
      }
    }
  }

  /// Jump to the top and reveal the freshest feed (replays the entrance
  /// cascade), dismissing the "new moments" pill.
  void _revealNew() {
    setState(() {
      _generation++;
      _showNewPill = false;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MomentFeedBloc, MomentFeedState>(
      // A refresh just landed (loading → success).
      listenWhen: (prev, curr) =>
          prev.status == FeedStatus.loading && curr.status == FeedStatus.success,
      listener: (context, state) {
        // Warm upcoming images for smooth scrolling.
        _prefetch(state.moments);

        final ids = <int>{for (final m in state.moments) m.id};
        final hasNew = ids.difference(_knownIds).isNotEmpty;
        _knownIds
          ..clear()
          ..addAll(ids);

        if (_scroll.hasClients && _scroll.offset > 300) {
          // Scrolled down: don't yank the user up — just flag fresh moments.
          if (hasNew) setState(() => _showNewPill = true);
        } else {
          // At/near the top: reveal the reshuffled feed with the entrance cascade.
          setState(() {
            _generation++;
            _showNewPill = false;
          });
          if (_scroll.hasClients) {
            _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        }
      },
      builder: (context, state) {
        if (state.status == FeedStatus.loading && state.moments.isEmpty) {
          return const MomentFeedSkeleton();
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
        return Stack(
          children: [
            RefreshIndicator(
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
              return RepaintBoundary(
                child: _FeedEntrance(
                // Re-keyed per generation → the card re-mounts and replays its
                // entrance whenever the feed is reshuffled by a refresh.
                key: ValueKey('$_generation-${moment.id}'),
                index: i,
                child: MomentCard(
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
                onTapImage: _openGallery,
                ),
              ),
              );
            },
          ),
            ),
            if (_showNewPill)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: _NewMomentsPill(
                    label: context.tr(MomentStrings.newMoments),
                    onTap: _revealNew,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One-shot fade + upward-slide entrance for a feed card, with a small
/// index-based delay so cards cascade in (capped so far-down items don't wait).
/// Re-mounting it (via a changed key) replays the animation — used to make a
/// reshuffled feed transition smoothly instead of snapping to the new order.
class _FeedEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const _FeedEntrance({super.key, required this.index, required this.child});

  @override
  State<_FeedEntrance> createState() => _FeedEntranceState();
}

class _FeedEntranceState extends State<_FeedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delayMs = widget.index.clamp(0, 8) * 55;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
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

/// Floating "new moments ↑" chip shown when a refresh brings fresh posts while
/// the user is scrolled down; tapping it jumps to the top and reveals them.
class _NewMomentsPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NewMomentsPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
