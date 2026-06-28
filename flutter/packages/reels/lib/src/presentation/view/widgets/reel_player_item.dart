import 'package:audio_session/audio_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/reels_strings.dart';
import '../../../domain/entities/real_entity.dart';
import '../../utils/media.dart';
import '../../utils/number_format.dart';
import '../../utils/reactions.dart';
import '../../utils/reel_prefetch.dart';

/// A full-screen, TikTok–style reel:
///  - the video fills the screen (`BoxFit.cover`) and autoplays with sound when
///    the page scrolls into view; tap toggles play/pause, double-tap likes,
///  - a vertical action rail (author + follow badge, like, comment, share, more)
///    on the trailing edge (left in RTL, right in LTR),
///  - the author name + description over a bottom scrim,
///  - a thin progress bar pinned to the bottom.
class ReelPlayerItem extends StatefulWidget {
  /// Unique position in the pager. Used for the widget/visibility keys so a reel
  /// that repeats after the feed loops doesn't collide with its earlier copy.
  final int slotId;
  final RealEntity reel;

  /// Set a Facebook-style reaction (tap = 'like', long-press picks one of the 6).
  /// Same type again toggles it off.
  final void Function(String reactionType) onReact;
  final VoidCallback onOpenLikes;
  final VoidCallback onOpenComments;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  /// Optional caption editor (owner-only). When null the "edit" entry is hidden
  /// — the main feed omits it; the My-Reels view supplies it.
  final VoidCallback? onEdit;

  const ReelPlayerItem({
    super.key,
    required this.slotId,
    required this.reel,
    required this.onReact,
    required this.onOpenLikes,
    required this.onOpenComments,
    required this.onReport,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _started = false;
  // Shared across reels so the user's mute choice sticks while scrolling.
  // Default: sound ON — the viewer mutes manually whenever they want.
  static bool _muted = false;
  bool _userPaused = false;
  // True while the video is fetching more data (shows a spinner so the reel
  // doesn't just look frozen on a frame while it loads).
  bool _buffering = false;
  // Last visibility reported for this reel. Used to win the race where init
  // finishes *after* the visibility callback already fired.
  double _lastVisibleFraction = 0;
  // The URL this player is streaming directly from the network (cache miss).
  // Registered with ReelPrefetch so the prefetcher won't pull the same bytes a
  // second time; cleared on teardown.
  String? _streamingUrl;

  static const _shadows = <Shadow>[
    Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1)),
  ];

  @override
  void initState() {
    super.initState();
    // Preload right away so the reel is ready to play the instant it scrolls
    // into view. PageView keeps the neighbouring pages alive
    // (allowImplicitScrolling), so the next/previous reels buffer ahead and
    // playback starts with no loading wait.
    _ensureController();
  }

  @override
  void didUpdateWidget(ReelPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Slot-based keys mean this State is reused when the feed reshuffles
    // (pull-to-refresh / loop) and a new reel lands in this slot. Tear the old
    // player down and load the new video — otherwise the slot keeps showing
    // (and looping) the previous clip. _lastVisibleFraction is intentionally
    // kept so the replacement autoplays if this slot is still on screen.
    if (oldWidget.reel.url != widget.reel.url) {
      _controller?.removeListener(_onControllerValue);
      _controller?.dispose();
      _controller = null;
      if (_streamingUrl != null) {
        ReelPrefetch.clearStreaming(_streamingUrl!);
        _streamingUrl = null;
      }
      _ready = false;
      _failed = false;
      _started = false;
      _userPaused = false;
      _buffering = false;
      _ensureController();
    }
  }

  // Configure the audio session for media playback exactly once. Cached as a
  // Future so the several ReelPlayerItems that init together (PageView keeps
  // neighbours alive) all await the same configuration instead of racing to
  // set it.
  static Future<void>? _audioSession;
  static Future<void> _ensureAudioSession() {
    return _audioSession ??= () async {
      try {
        final session = await AudioSession.instance;
        await session.configure(AudioSessionConfiguration.music());
      } catch (_) {
        // best-effort: playback still works; on iOS it may just respect the
        // silent switch if the session couldn't be configured.
      }
    }();
  }

  Future<void> _ensureController() async {
    if (_started) return;
    _started = true;
    // Route audio through the media/playback session so reels play WITH sound
    // even when the device's silent/ringer switch is on (the iOS default
    // ambient category mutes them otherwise). Shared across all reels.
    await _ensureAudioSession();
    if (!mounted) return;
    final url = resolveMediaUrl(widget.reel.url);
    if (url.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    try {
      // Play from the prefetched local file when available (instant start);
      // otherwise stream from the network and let the prefetcher cache ahead.
      final cached = await ReelPrefetch.cachedFile(url);
      if (!mounted) return;
      final VideoPlayerController controller;
      if (cached != null) {
        controller = VideoPlayerController.file(cached);
      } else {
        // Cache miss: stream from the network and tell the prefetcher to leave
        // this URL alone so the same bytes aren't downloaded a second time.
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
        _streamingUrl = url;
        ReelPrefetch.markStreaming(url);
      }
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(
        _muted ? 0 : 1,
      ); // honour mute choice (default: sound on)
      controller.addListener(_onControllerValue);
      if (!mounted) return;
      setState(() => _ready = true);
      // If this reel is already the one on screen, start playing now — the
      // visibility callback may have fired before init finished, which would
      // otherwise leave it frozen on the first frame until the next scroll.
      if (_lastVisibleFraction > 0.6 && !_userPaused) {
        controller.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  /// Reflects buffering state into the UI (only rebuilds when it flips, so we
  /// don't setState on every position tick).
  void _onControllerValue() {
    final c = _controller;
    if (c == null || !mounted) return;
    final buffering = c.value.isBuffering;
    if (buffering != _buffering) {
      setState(() => _buffering = buffering);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final fraction = info.visibleFraction;
    _lastVisibleFraction = fraction;
    if (fraction > 0 && !_started) {
      _ensureController();
    }
    final c = _controller;
    if (c == null || !_ready) return;

    if (fraction > 0.6 && !_userPaused) {
      if (!c.value.isPlaying) c.play();
    } else {
      if (c.value.isPlaying) c.pause();
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_ready) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _userPaused = true;
      } else {
        c.play();
        _userPaused = false;
      }
    });
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null || !_ready) return;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  void _shareReel() {
    final reel = widget.reel;
    final url = resolveMediaUrl(reel.url);
    final desc = reel.description.trim();
    final text = desc.isNotEmpty ? '$desc\n$url' : url;
    if (text.trim().isEmpty) return;
    Share.share(text);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerValue);
    _controller?.dispose();
    if (_streamingUrl != null) {
      ReelPrefetch.clearStreaming(_streamingUrl!);
      _streamingUrl = null;
    }
    super.dispose();
  }

  /// The like rail entry as a Facebook-style reaction control:
  ///  - tap          → react with 'like' (toggles off if already 'like'),
  ///  - long-press   → open the 6-reaction picker,
  ///  - tap the count → open the "who reacted" sheet.
  /// The icon shows the user's current reaction emoji, or a heart outline.
  Widget _reactionButton(BuildContext context, RealEntity reel) {
    final reaction = reactionByType(reel.myReaction);
    final reacted = reaction != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tap = like toggle; long-press pops the reaction bar anchored right
        // above this button — drag onto an emoji and release to pick it.
        ReactionPicker(
          onTapDefault: () => widget.onReact('like'),
          onSelected: (type) => widget.onReact(type),
          child: reacted
              ? Text(reaction.emoji, style: const TextStyle(fontSize: 32, shadows: _shadows))
              : const Icon(Icons.favorite_border, color: Colors.white, size: 34, shadows: _shadows),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: widget.onOpenLikes,
          behavior: HitTestBehavior.opaque,
          child: Text(
            compactNumber(reel.likesCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: _shadows,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final c = _controller;
    final topInset = MediaQuery.of(context).padding.top;

    return VisibilityDetector(
      key: ValueKey('reel-vis-${widget.slotId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlay,
        onDoubleTap: () => widget.onReact('like'),
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── video (fills the screen) ──────────────────────────
              _videoLayer(reel, c),

              // ── bottom scrim for text legibility ──────────────────
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // ── loading / buffering spinner ───────────────────────
              if (!_failed && !_userPaused && (!_ready || _buffering))
                const Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

              // ── center play icon: only when the viewer paused manually ──
              if (_ready && c != null && _userPaused)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white70,
                    size: 84,
                    shadows: _shadows,
                  ),
                ),

              // ── mute / unmute (top, trailing — sits below the add button) ─
              if (_ready && c != null)
                PositionedDirectional(
                  end: 8,
                  top: topInset + 56,
                  child: _circleButton(
                    icon: _muted ? Icons.volume_off : Icons.volume_up,
                    onTap: _toggleMute,
                  ),
                ),

              // ── action rail (trailing edge) ───────────────────────
              PositionedDirectional(
                end: 8,
                bottom: 28,
                child: _actionRail(context),
              ),

              // ── author + description (bottom, leading) ────────────
              PositionedDirectional(
                start: 12,
                end: 84,
                bottom: 28,
                child: _info(context),
              ),

              // ── progress bar (pinned bottom) ──────────────────────
              if (_ready && c != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoLayer(RealEntity reel, VideoPlayerController? c) {
    if (_ready && c != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      );
    }
    // Show the poster while the video loads (the spinner overlay sits on top).
    final poster = resolveMediaUrl(reel.subFrame);
    if (poster.isNotEmpty && !_failed) {
      return CachedNetworkImage(
        imageUrl: poster,
        fit: BoxFit.cover,
        // Decode at a sane width (full-screen never needs >720px of pixels) to
        // cut memory + decode cost; cached so scroll-back doesn't re-fetch.
        memCacheWidth: 720,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder(
      icon: _failed ? Icons.videocam_off : Icons.movie_outlined,
    );
  }

  Widget _placeholder({IconData icon = Icons.movie_outlined}) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(child: Icon(icon, color: Colors.white24, size: 48)),
    );
  }

  // ── action rail ──────────────────────────────────────────────────
  Widget _actionRail(BuildContext context) {
    final reel = widget.reel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _authorAvatar(reel),
        const SizedBox(height: 20),
        // Reaction button: tap = like toggle, long-press = pick one of the 6
        // reactions, tapping the count = "who reacted" sheet. The icon shows the
        // current reaction emoji (or a heart outline when none).
        _reactionButton(context, reel),
        const SizedBox(height: 18),
        _railButton(
          icon: Icons.mode_comment_outlined,
          label: compactNumber(reel.commentsCount),
          onTap: widget.onOpenComments,
        ),
        const SizedBox(height: 18),
        _railButton(
          icon: Icons.reply,
          label: compactNumber(reel.shareCount),
          onTap: _shareReel,
        ),
        // Gift button — only when the Gifts package is installed (it registers
        // GiftBridge at startup). Opens the gift picker, which posts to
        // /reals/{id}/gift via the gifts package's `contextType: 'reel'` route.
        if (GiftBridge.instance.isAvailable) ...[
          const SizedBox(height: 18),
          _railButton(
            icon: Icons.card_giftcard,
            color: Colors.amberAccent,
            onTap: () => GiftBridge.instance.open(
              context,
              contextType: 'reel',
              contextId: reel.id,
              receiverName: reel.userName,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _railButton(icon: Icons.more_horiz, onTap: () => _showMore(context)),
      ],
    );
  }

  Widget _authorAvatar(RealEntity reel) {
    return SizedBox(
      width: 54,
      height: 66,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              backgroundImage: CachedNetworkImageProvider(
                avatarUrl(reel.userImage, reel.userName),
              ),
            ),
          ),
          // decorative follow badge (not wired to a backend yet)
          Positioned(
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _railButton({
    required IconData icon,
    Color color = Colors.white,
    String? label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 34, shadows: _shadows),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: _shadows,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.black38,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: Text(
                context.tr(ReelsStrings.report),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                widget.onReport();
              },
            ),
            if (widget.reel.isOwner && widget.onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: Text(
                  context.tr(ReelsStrings.editCaption),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  widget.onEdit!.call();
                },
              ),
            if (widget.reel.isOwner)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  context.tr(ReelsStrings.delete),
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  widget.onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── author name + description ─────────────────────────────────────
  Widget _info(BuildContext context) {
    final reel = widget.reel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reel.userName.isEmpty ? context.tr(ReelsStrings.user) : reel.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            shadows: _shadows,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (reel.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            reel.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: _shadows,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
