import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/profile/profile_navigator.dart';

import '../../../../core/reels_strings.dart';
import '../../../domain/entities/real_comment_entity.dart';
import '../../../domain/repositories/reels_repository.dart';
import '../../bloc/reels_comments/reels_comments_cubit.dart';
import '../../utils/media.dart';
import '../../utils/reactions.dart';
import '../../utils/time.dart';
import 'confirm_dialog.dart';
import 'report_reel_dialog.dart';

/// Thread geometry — kept in one place so the parent rail and the reply
/// connectors line up exactly.
const double _parentAvatarRadius = 17;
const double _replyAvatarRadius = 13;
const double _railWidth = 34; // == parent avatar diameter, so the rail centers under it
const Color _threadLineColor = Color(0xFFD3D8DF);

Future<void> showReelsComments(
  BuildContext context,
  int reelId, {
  VoidCallback? onCommentAdded,
  void Function(int removed)? onCommentDeleted,
  int? reelOwnerId,
}) {
  final repo = context.read<ReelsRepository>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => ReelsCommentsCubit(repo, reelId)..load(),
      child: _CommentsSheet(
        onCommentAdded: onCommentAdded,
        onCommentDeleted: onCommentDeleted,
        reelOwnerId: reelOwnerId,
      ),
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final VoidCallback? onCommentAdded;
  final void Function(int removed)? onCommentDeleted;
  final int? reelOwnerId;
  const _CommentsSheet({this.onCommentAdded, this.onCommentDeleted, this.reelOwnerId});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// Current signed-in user id (for delete/report permission checks).
  int _currentUserId = 0;

  /// When set, the next comment is posted as a reply to this comment/reply.
  RealCommentEntity? _replyTo;

  @override
  void initState() {
    super.initState();
    final raw = CacheManager.getUserData()?['id'];
    _currentUserId = raw is int ? raw : int.tryParse('${raw ?? ''}') ?? 0;
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<ReelsCommentsCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _startReply(RealCommentEntity c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTo = null);

  Future<void> _submit() async {
    final cubit = context.read<ReelsCommentsCubit>();
    var text = _controller.text.trim();
    if (text.isEmpty) return;

    final target = _replyTo;
    // Replies flatten under the top-level comment (server normalizes parent), so
    // for a reply-to-a-reply we keep an "@name" mention to preserve who it answers.
    if (target != null && target.parentId != null && target.userName.isNotEmpty && !text.startsWith('@')) {
      text = '@${target.userName} $text';
    }

    final ok = await cubit.add(text, parentId: target?.id);
    if (ok) {
      _controller.clear();
      _cancelReply();
      widget.onCommentAdded?.call();
    }
  }

  bool _canDelete(RealCommentEntity c) =>
      _currentUserId != 0 && (c.userId == _currentUserId || _currentUserId == widget.reelOwnerId);

  bool _canReport(RealCommentEntity c) => _currentUserId == 0 || c.userId != _currentUserId;

  void _showCommentActions(RealCommentEntity c) {
    final canDelete = _canDelete(c);
    final canReport = _canReport(c);
    if (!canDelete && !canReport) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReport)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(context.tr(ReelsStrings.report)),
                onTap: () {
                  Navigator.pop(ctx);
                  _reportComment(c);
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(context.tr(ReelsStrings.delete), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteComment(c);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportComment(RealCommentEntity c) async {
    final reelId = context.read<ReelsCommentsCubit>().reelId;
    final ok = await showReportCommentDialog(context, reelId, c.id);
    if (ok && mounted) ToastManager.showToast(context, message: context.tr(ReelsStrings.reportedThanks));
  }

  Future<void> _deleteComment(RealCommentEntity c) async {
    final confirm = await showThemedConfirm(
      context,
      title: context.tr(ReelsStrings.deleteCommentConfirm),
      confirmText: context.tr(ReelsStrings.delete),
      cancelText: context.tr(ReelsStrings.cancel),
      destructive: true,
    );
    if (!confirm || !mounted) return;
    final cubit = context.read<ReelsCommentsCubit>();
    final removed = await cubit.delete(c.id);
    if (removed > 0 && mounted) {
      widget.onCommentDeleted?.call(removed);
      ToastManager.showToast(context, message: context.tr(ReelsStrings.deleted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _SheetHandle(title: context.tr(ReelsStrings.comments)),
          Expanded(
            child: BlocBuilder<ReelsCommentsCubit, ReelsCommentsState>(
              builder: (context, state) {
                if (state.status == CommentsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == CommentsStatus.failure && state.comments.isEmpty) {
                  return _ErrorRetry(
                    message: state.error ?? context.tr(ReelsStrings.somethingWrong),
                    onRetry: () => context.read<ReelsCommentsCubit>().load(),
                  );
                }
                if (state.comments.isEmpty) {
                  return Center(
                    child: Text(context.tr(ReelsStrings.noComments), style: const TextStyle(color: Colors.grey)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<ReelsCommentsCubit>().load(),
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: state.comments.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      if (i >= state.comments.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _thread(context, state.comments[i]);
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyTo != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF0F2F5),
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 10, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${context.tr(ReelsStrings.replyingTo)} ${_replyTo!.userName.isEmpty ? context.tr(ReelsStrings.user) : _replyTo!.userName}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(Icons.close, size: 16, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: context.tr(_replyTo != null ? ReelsStrings.reply : ReelsStrings.writeComment),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<ReelsCommentsCubit, ReelsCommentsState>(
                        builder: (context, state) => IconButton.filled(
                          onPressed: state.isSubmitting ? null : _submit,
                          icon: state.isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A top-level comment and (when present) its one level of replies, connected
  /// by a Facebook-style thread line. Direction-aware (works in RTL & LTR).
  Widget _thread(BuildContext context, RealCommentEntity c) {
    if (c.replies.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(context, c, _parentAvatarRadius),
          const SizedBox(width: 8),
          Flexible(child: _commentBody(context, c, isReply: false)),
        ],
      );
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent comment with a rail running down from beneath its avatar.
        Stack(
          children: [
            PositionedDirectional(
              start: 0,
              top: _railWidth, // start just below the avatar
              bottom: 0,
              width: _railWidth,
              child: CustomPaint(
                painter: _ThreadPainter(branch: false, isLast: false, rtl: rtl),
                child: const SizedBox.expand(),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(context, c, _parentAvatarRadius),
                const SizedBox(width: 8),
                Flexible(child: _commentBody(context, c, isReply: false)),
              ],
            ),
          ],
        ),
        // Replies — each indented under the parent with a curved connector.
        for (int i = 0; i < c.replies.length; i++)
          Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: _railWidth,
                child: CustomPaint(
                  painter: _ThreadPainter(
                    branch: true,
                    isLast: i == c.replies.length - 1,
                    rtl: rtl,
                    avatarCenterY: _replyAvatarRadius,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: _railWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatar(context, c.replies[i], _replyAvatarRadius),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _commentBody(context, c.replies[i], isReply: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _avatar(BuildContext context, RealCommentEntity c, double radius) {
    void openProfile() {
      if (c.userId > 0) ProfileNavigator.open(context, userId: c.userId);
    }

    return GestureDetector(
      onTap: openProfile,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: CachedNetworkImageProvider(avatarUrl(c.userImage, c.userName)),
      ),
    );
  }

  /// The bubble (name + text) plus the time · Like · Reply action row — no
  /// avatar (the caller places it so replies/parents share this body).
  /// Long-pressing the bubble opens report/delete actions.
  Widget _commentBody(BuildContext context, RealCommentEntity c, {required bool isReply}) {
    final cubit = context.read<ReelsCommentsCubit>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    void openProfile() {
      if (c.userId > 0) ProfileNavigator.open(context, userId: c.userId);
    }

    final myReaction = reactionByType(c.myReaction);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The grey chat bubble (hugs its content). Long-press = report/delete.
        GestureDetector(
          onLongPress: () => _showCommentActions(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: openProfile,
                  child: Text(
                    c.userName.isEmpty ? context.tr(ReelsStrings.user) : c.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 2),
                Text(c.comment, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.25)),
              ],
            ),
          ),
        ),
        // time · Like(react) · Reply. The react control shows just the chosen
        // emoji once reacted (no word), or the "Like" call-to-action otherwise.
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
          child: Row(
            children: [
              Text(timeAgo(c.createdAt, arabic: isArabic), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 16),
              ReactionPicker(
                onTapDefault: () => cubit.react(c.id, 'like'),
                onSelected: (type) => cubit.react(c.id, type),
                child: myReaction != null
                    ? Text(myReaction.emoji, style: const TextStyle(fontSize: 16))
                    : Text(
                        context.tr(ReelsStrings.like),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => _startReply(c),
                child: Text(
                  context.tr(ReelsStrings.reply),
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints the Facebook-style thread line inside a [_railWidth]-wide column.
class _ThreadPainter extends CustomPainter {
  final bool branch;
  final bool isLast;
  final bool rtl;
  final double avatarCenterY;
  const _ThreadPainter({
    required this.branch,
    required this.isLast,
    required this.rtl,
    this.avatarCenterY = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _threadLineColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lineX = size.width / 2;

    if (!branch) {
      canvas.drawLine(Offset(lineX, 0), Offset(lineX, size.height), paint);
      return;
    }

    const r = 9.0;
    final endX = rtl ? 0.0 : size.width;
    final dir = rtl ? -1.0 : 1.0;

    final vBottom = isLast ? (avatarCenterY - r) : size.height;
    canvas.drawLine(Offset(lineX, 0), Offset(lineX, vBottom), paint);

    final path = Path()
      ..moveTo(lineX, avatarCenterY - r)
      ..quadraticBezierTo(lineX, avatarCenterY, lineX + dir * r, avatarCenterY)
      ..lineTo(endX, avatarCenterY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ThreadPainter old) =>
      old.branch != branch || old.isLast != isLast || old.rtl != rtl || old.avatarCenterY != avatarCenterY;
}

/// Inline error + retry shown when the first page fails to load.
class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.tr(ReelsStrings.retry))),
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
