import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/reels_strings.dart';
import '../bloc/reels_feed/reels_feed_bloc.dart';
import '../bloc/reels_feed/reels_feed_event.dart';
import '../bloc/reels_feed/reels_feed_state.dart';
import 'widgets/reel_player_item.dart';
import 'widgets/reels_comments_sheet.dart';
import 'widgets/reels_likes_sheet.dart';
import 'widgets/report_reel_dialog.dart';
import '../utils/media.dart';
import '../utils/reel_prefetch.dart';

/// TikTok–style reels: a full-screen vertical pager where each reel snaps into
/// view and autoplays (with sound) while it is on screen. Neighbouring reels
/// are kept alive and buffered ahead so playback starts with no loading wait.
class ReelsFeedPage extends StatefulWidget {
  const ReelsFeedPage({super.key});

  @override
  State<ReelsFeedPage> createState() => _ReelsFeedPageState();
}

class _ReelsFeedPageState extends State<ReelsFeedPage> {
  final _pageController = PageController();

  /// Active top tab: 0 = Following, 1 = For You. Visual only for now.
  int _tab = 1;

  /// Reel ids we've already counted a view for (avoid double-counting).
  final _viewed = <int>{};

  /// The reel currently centred in the pager — drives prefetch of what's next.
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default visibility polling is 500ms — that's up to half a second of black
    // frame before a reel autoplays as you flip to it. Reels are the only
    // visibility_detector user in the app, so tightening this just makes the
    // autoplay snappier (the play/pause callback is cheap).
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 120,
    );
    final bloc = context.read<ReelsFeedBloc>();
    if (bloc.state.status == FeedStatus.initial) {
      bloc.add(const FeedRefreshRequested());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recordView(int reelId) {
    if (_viewed.add(reelId)) {
      context.read<ReelsFeedBloc>().add(ReelViewed(reelId));
    }
  }

  void _onPageChanged(int index, ReelsFeedState state) {
    _currentIndex = index;
    if (index < state.reels.length) {
      _recordView(state.reels[index].id);
    }
    // Warm the cache for the next few reels so they start with no loading wait.
    _prefetchAhead(index, state);
    // Prefetch the next page as we near the end of the loaded list.
    if (index >= state.reels.length - 2) {
      context.read<ReelsFeedBloc>().add(const FeedLoadMoreRequested());
    }
  }

  /// Download upcoming reels' videos into the cache ahead of time so they play
  /// instantly when the user flips to them (TikTok-style).
  void _prefetchAhead(int index, ReelsFeedState state) {
    // Start at index+2, NOT index+1: allowImplicitScrolling already keeps the
    // immediate neighbour alive and buffering through its own player, so
    // prefetching it too would download the same bytes twice. We warm the two
    // slots BEYOND that live neighbour — enough for instant playback while
    // keeping bandwidth/contention low on mobile networks.
    final urls = <String>[];
    for (var j = index + 2; j <= index + 3 && j < state.reels.length; j++) {
      urls.add(resolveMediaUrl(state.reels[j].url));
    }
    ReelPrefetch.warm(urls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelsFeedBloc, ReelsFeedState>(
        // Rebuild the pager only when something it actually renders changes:
        // the status, the error, or the reels list itself (refresh / append /
        // optimistic like all create a NEW list reference). Skip rebuilds where
        // only `isLoadingMore`/`seed`/`isSubmitting` flipped (copyWith keeps the
        // same `reels` reference) — those used to rebuild the whole PageView
        // mid-scroll while the next page loaded, causing a visible hitch.
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.error != c.error ||
            !identical(p.reels, c.reels),
        builder: (context, state) {
          if (state.status == FeedStatus.loading && state.reels.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (state.status == FeedStatus.failure && state.reels.isEmpty) {
            return _ErrorView(
              message: state.error ?? context.tr(ReelsStrings.somethingWrong),
              onRetry: () => context.read<ReelsFeedBloc>().add(
                const FeedRefreshRequested(),
              ),
            );
          }
          if (state.reels.isEmpty) {
            return _EmptyView(
              onRefresh: () => context.read<ReelsFeedBloc>().add(
                const FeedRefreshRequested(),
              ),
            );
          }

          // Record a view for the very first reel once the feed is ready, and
          // warm the cache for the reels just ahead of the current one.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || state.reels.isEmpty) return;
            _recordView(state.reels.first.id);
            _prefetchAhead(_currentIndex, state);
          });

          return Stack(
            children: [
              RefreshIndicator(
                color: Colors.white,
                backgroundColor: Colors.black54,
                // Pull down at the top of the feed to reshuffle into a fresh
                // random order (a new seed).
                onRefresh: () async {
                  final bloc = context.read<ReelsFeedBloc>();
                  bloc.add(const FeedRefreshRequested());
                  await bloc.stream.firstWhere(
                    (s) => s.status != FeedStatus.loading,
                  );
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  // Keep the neighbouring reels alive so they buffer ahead and
                  // start instantly when scrolled into view (no loading wait).
                  allowImplicitScrolling: true,
                  itemCount: state.reels.length,
                  onPageChanged: (i) => _onPageChanged(i, state),
                  itemBuilder: (context, i) {
                    final reel = state.reels[i];
                    return ReelPlayerItem(
                      // Slot-based key (not reel.id): a reel can repeat once the
                      // feed loops, and duplicate keys would crash the pager.
                      key: ValueKey('reel-slot-$i'),
                      slotId: i,
                      reel: reel,
                      onReact: (type) => context.read<ReelsFeedBloc>().add(
                        ReelReactToggled(reel, type),
                      ),
                      onOpenLikes: () => showReelsLikes(context, reel.id),
                      onOpenComments: () => showReelsComments(
                        context,
                        reel.id,
                        reelOwnerId: reel.userId,
                        // Keep the rail's comment counter in step with the sheet.
                        onCommentAdded: () => context.read<ReelsFeedBloc>().add(
                          ReelCommentCountChanged(reel.id, 1),
                        ),
                        onCommentDeleted: (removed) => context.read<ReelsFeedBloc>().add(
                          ReelCommentCountChanged(reel.id, -removed),
                        ),
                      ),
                      onReport: () async {
                        final ok = await showReportReelDialog(context, reel.id);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(ReelsStrings.reportedThanks),
                              ),
                            ),
                          );
                        }
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(context.tr(ReelsStrings.deleteConfirm)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(context.tr(ReelsStrings.cancel)),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(context.tr(ReelsStrings.delete)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          context.read<ReelsFeedBloc>().add(
                            ReelDeleted(reel.id),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              _TopBar(
                tab: _tab,
                onTabChanged: (t) => setState(() => _tab = t),
                onAdd: () => context.push('/reels/add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top overlay: "Following | For You" tabs centered with an add button.
class _TopBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAdd;

  const _TopBar({
    required this.tab,
    required this.onTabChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 48,
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabLabel(context, context.tr(ReelsStrings.following), 0),
                  const SizedBox(width: 24),
                  _tabLabel(context, context.tr(ReelsStrings.forYou), 1),
                ],
              ),
            ),
            PositionedDirectional(
              end: 8,
              top: 4,
              child: IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                tooltip: context.tr(ReelsStrings.newReel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabLabel(BuildContext context, String text, int index) {
    final active = tab == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 22,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            context.tr(ReelsStrings.empty),
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRefresh,
            child: Text(context.tr(ReelsStrings.retry)),
          ),
        ],
      ),
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
          const Icon(Icons.cloud_off, size: 48, color: Colors.white38),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.tr(ReelsStrings.retry)),
          ),
        ],
      ),
    );
  }
}
