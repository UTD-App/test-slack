import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import '../../../core/reels_strings.dart';
import '../../domain/entities/real_entity.dart';
import '../../domain/repositories/reels_repository.dart';
import '../bloc/reels_profile/reels_profile_cubit.dart';
import '../utils/media.dart';
import 'widgets/edit_caption_dialog.dart';
import 'widgets/reel_player_item.dart';
import 'widgets/reel_thumbnail.dart';
import 'widgets/reels_comments_sheet.dart';
import 'widgets/reels_likes_sheet.dart';
import 'widgets/report_reel_dialog.dart';

/// A grid of a user's reels (poster frames). Tapping a tile opens a full-screen
/// vertical pager starting at that reel. Owners get delete + edit-caption.
///
/// [userId] null → the current user's own reels (`/reals/my-reals`); otherwise
/// that user's public reels (`/reals/user/{id}`).
class ReelsMyReelsPage extends StatelessWidget {
  final int? userId;
  final String? titleKey;

  const ReelsMyReelsPage({super.key, this.userId, this.titleKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReelsProfileCubit(context.read<ReelsRepository>(), userId: userId)
            ..load(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
          title: Text(
            context.tr(titleKey ?? ReelsStrings.myReels),
            style: const TextStyle(
              color: ColorManager.lumiaTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const GradientBackground(
          child: SafeArea(child: _MyReelsGrid()),
        ),
      ),
    );
  }
}

/// Embeddable grid of a user's reels — the same grid as [ReelsMyReelsPage] but
/// WITHOUT a Scaffold/AppBar, so it can be dropped into a profile tab.
///
/// [userId] null → the current user's reels; otherwise that user's public reels.
class ReelsUserGrid extends StatelessWidget {
  final int? userId;

  const ReelsUserGrid({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReelsProfileCubit(context.read<ReelsRepository>(), userId: userId)
            ..load(),
      child: const _MyReelsGrid(),
    );
  }
}

class _MyReelsGrid extends StatelessWidget {
  const _MyReelsGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReelsProfileCubit, ReelsProfileState>(
      builder: (context, state) {
        if (state.status == ReelsProfileStatus.loading && state.reels.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ReelsProfileStatus.failure && state.reels.isEmpty) {
          return _Centered(
            icon: Icons.cloud_off,
            text: state.error ?? context.tr(ReelsStrings.somethingWrong),
            actionLabel: context.tr(ReelsStrings.retry),
            onAction: () => context.read<ReelsProfileCubit>().load(),
          );
        }
        if (state.reels.isEmpty) {
          return _Centered(
            icon: Icons.movie_outlined,
            text: context.tr(ReelsStrings.empty),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<ReelsProfileCubit>().load(),
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.7,
            ),
            itemCount: state.reels.length,
            itemBuilder: (context, i) => _ReelTile(
              reel: state.reels[i],
              onTap: () => _openPlayer(context, i),
            ),
          ),
        );
      },
    );
  }

  void _openPlayer(BuildContext context, int index) {
    final cubit = context.read<ReelsProfileCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ReelsProfileCubit>.value(
          value: cubit,
          child: _MyReelsPlayerPage(initialIndex: index),
        ),
      ),
    );
  }
}

class _ReelTile extends StatelessWidget {
  final RealEntity reel;
  final VoidCallback onTap;

  const _ReelTile({required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: const Color(0xFF111111),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Server poster when present, else an on-device frame from the video
            // (so tiles aren't blank when no poster file exists).
            ReelThumbnail(
              videoUrl: resolveMediaUrl(reel.url),
              posterUrl: resolveMediaUrl(reel.subFrame),
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen vertical pager over the loaded grid list, starting at [initialIndex].
/// Shares the [ReelsProfileCubit] with the grid so delete/edit/like stay in sync.
class _MyReelsPlayerPage extends StatefulWidget {
  final int initialIndex;
  const _MyReelsPlayerPage({required this.initialIndex});

  @override
  State<_MyReelsPlayerPage> createState() => _MyReelsPlayerPageState();
}

class _MyReelsPlayerPageState extends State<_MyReelsPlayerPage> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<ReelsProfileCubit, ReelsProfileState>(
        listener: (context, state) {
          // Everything was deleted while viewing → back to the grid.
          if (state.reels.isEmpty) Navigator.of(context).maybePop();
        },
        builder: (context, state) {
          if (state.reels.isEmpty) {
            return const SizedBox.shrink();
          }
          final cubit = context.read<ReelsProfileCubit>();
          return PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            allowImplicitScrolling: true,
            itemCount: state.reels.length,
            itemBuilder: (context, i) {
              final reel = state.reels[i];
              return ReelPlayerItem(
                key: ValueKey('myreel-slot-$i'),
                slotId: i,
                reel: reel,
                onReact: (type) => cubit.react(reel, type),
                onOpenLikes: () => showReelsLikes(context, reel.id),
                onOpenComments: () => showReelsComments(
                  context,
                  reel.id,
                  reelOwnerId: reel.userId,
                  onCommentAdded: () => cubit.adjustCommentCount(reel.id, 1),
                  onCommentDeleted: (removed) => cubit.adjustCommentCount(reel.id, -removed),
                ),
                onReport: () async {
                  final ok = await showReportReelDialog(context, reel.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr(ReelsStrings.reportedThanks))),
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
                  if (confirm == true) cubit.deleteReel(reel.id);
                },
                // Owner-only caption editor (the more-sheet shows it only when
                // both isOwner and onEdit are set).
                onEdit: reel.isOwner
                    ? () async {
                        final next =
                            await showEditCaptionDialog(context, reel.description);
                        if (next != null) cubit.updateDescription(reel.id, next);
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Centered({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(text, textAlign: TextAlign.center),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
