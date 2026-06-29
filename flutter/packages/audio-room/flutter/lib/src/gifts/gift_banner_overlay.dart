import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/media/dynamic_image.dart';
import 'package:video_player/video_player.dart';

import 'gift_event_bus.dart';

class GiftBannerOverlay extends StatefulWidget {
  final UTDRoomController? controller;

  const GiftBannerOverlay({super.key, this.controller});

  @override
  State<GiftBannerOverlay> createState() => _GiftBannerOverlayState();
}

class _GiftBannerOverlayState extends State<GiftBannerOverlay> {
  static const _maxVisible = 2;
  static const _displayDuration = Duration(seconds: 4);

  final _queue = Queue<GiftDisplayEvent>();
  final _visible = <_BannerEntry>[];
  StreamSubscription<GiftDisplayEvent>? _subscription;

  GiftDisplayEvent? _fullScreenGift;

  @override
  void initState() {
    super.initState();
    _subscription = GiftEventBus.instance.stream.listen(_onEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final entry in _visible) {
      entry.timer.cancel();
    }
    super.dispose();
  }

  void _onEvent(GiftDisplayEvent event) {
    if (_visible.length < _maxVisible) {
      _showBanner(event);
    } else {
      _queue.add(event);
    }

    if (event.isPlay) {
      final currentUserId =
          CacheManager.getUserData()?['id']?.toString() ?? '';
      final isSender = event.senderId == currentUserId;
      final isReceiver = event.receiverIds.contains(currentUserId);
      if (isSender || isReceiver) {
        final animSrc = event.giftShowImg.isNotEmpty
            ? event.giftShowImg
            : event.giftImg;
        if (animSrc.isNotEmpty && animSrc.startsWith('http')) {
          _playFullScreen(event);
        }
      }
    }
  }

  void _playFullScreen(GiftDisplayEvent event) {
    if (mounted) {
      setState(() => _fullScreenGift = event);
    }
  }

  void _onFullScreenDone() {
    if (mounted) {
      setState(() => _fullScreenGift = null);
    }
  }

  void _showBanner(GiftDisplayEvent event) {
    final key = UniqueKey();
    final timer = Timer(_displayDuration, () => _removeBanner(key));
    final entry = _BannerEntry(key: key, event: event, timer: timer);
    if (mounted) {
      setState(() => _visible.add(entry));
    }
  }

  void _removeBanner(Key key) {
    if (!mounted) return;
    setState(() {
      _visible.removeWhere((e) => e.key == key);
    });
    if (_queue.isNotEmpty && _visible.length < _maxVisible) {
      _showBanner(_queue.removeFirst());
    }
  }

  String _resolveReceiverNames(List<String> receiverIds) {
    if (widget.controller == null) return receiverIds.join(', ');
    final names = <String>[];
    for (final id in receiverIds) {
      final name = _findUserName(id);
      names.add(name ?? id);
    }
    return names.join(', ');
  }

  String? _findUserName(String userId) {
    final controller = widget.controller;
    if (controller == null) return null;

    for (final p in controller.participants) {
      if (p.id == userId) return p.name;
    }
    for (final seat in controller.seatController.seats.value) {
      if (seat.occupantUserId == userId) {
        return seat.attributes['name']?.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_visible.isEmpty && _fullScreenGift == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (_fullScreenGift != null)
          _GiftFullScreenPlay(
            key: ValueKey(
              'fs_${_fullScreenGift!.senderId}_${_fullScreenGift!.giftName}',
            ),
            source: _fullScreenGift!.giftShowImg.isNotEmpty
                ? _fullScreenGift!.giftShowImg
                : _fullScreenGift!.giftImg,
            imageType: _fullScreenGift!.giftImageType,
            onDone: _onFullScreenDone,
          ),
        if (_visible.isNotEmpty)
          Positioned(
            top: 80,
            left: 8,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _visible.map((entry) {
                final e = entry.event;
                final receiverNames = _resolveReceiverNames(e.receiverIds);
                final totalCoins = e.giftPrice * e.giftNum;

                return _GiftBannerTile(
                  key: entry.key,
                  senderName: e.senderName,
                  senderAvatar: e.senderAvatar,
                  receiverNames: receiverNames,
                  giftName: e.giftName,
                  giftImg: e.giftImg,
                  giftNum: e.giftNum,
                  totalCoins: totalCoins,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _BannerEntry {
  final Key key;
  final GiftDisplayEvent event;
  final Timer timer;

  _BannerEntry({required this.key, required this.event, required this.timer});
}

class _GiftFullScreenPlay extends StatefulWidget {
  final String source;
  final String imageType;
  final VoidCallback onDone;

  const _GiftFullScreenPlay({
    super.key,
    required this.source,
    this.imageType = '',
    required this.onDone,
  });

  @override
  State<_GiftFullScreenPlay> createState() => _GiftFullScreenPlayState();
}

class _GiftFullScreenPlayState extends State<_GiftFullScreenPlay> {
  Timer? _fallback;
  var _done = false;

  bool get _isVideo {
    final ext = widget.source.split('.').last.split('?').first.toLowerCase();
    return ext == 'mp4' || ext == 'mov' || ext == 'webm';
  }

  @override
  void initState() {
    super.initState();
    _fallback = Timer(Duration(seconds: _isVideo ? 8 : 4), _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _fallback?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final Widget child;
    if (_isVideo) {
      child = SizedBox(
        width: size.width,
        height: size.height,
        child: _GiftVideoPlayer(url: widget.source, onDone: _finish),
      );
    } else {
      final imgSize = size.width * 0.6;
      child = SizedBox(
        width: imgSize,
        height: imgSize,
        child: DynamicImage(
          source: widget.source,
          fit: BoxFit.contain,
          errorWidget: const SizedBox.shrink(),
        ),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(child: Center(child: child)),
    );
  }
}

class _GiftVideoPlayer extends StatefulWidget {
  final String url;
  final VoidCallback onDone;

  const _GiftVideoPlayer({
    required this.url,
    required this.onDone,
  });

  @override
  State<_GiftVideoPlayer> createState() => _GiftVideoPlayerState();
}

class _GiftVideoPlayerState extends State<_GiftVideoPlayer> {
  VideoPlayerController? _vpc;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vpc = controller;
    controller.setVolume(0);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      controller.play();
    }).catchError((_) {
      if (mounted) widget.onDone();
    });
    controller.addListener(_onStatus);
  }

  void _onStatus() {
    final c = _vpc;
    if (c == null) return;
    if (c.value.hasError) {
      widget.onDone();
      return;
    }
    if (c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero) {
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _vpc?.removeListener(_onStatus);
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _vpc;
    if (!_ready || c == null) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _GiftBannerTile extends StatefulWidget {
  final String senderName;
  final String? senderAvatar;
  final String receiverNames;
  final String giftName;
  final String giftImg;
  final int giftNum;
  final int totalCoins;

  const _GiftBannerTile({
    super.key,
    required this.senderName,
    this.senderAvatar,
    required this.receiverNames,
    required this.giftName,
    required this.giftImg,
    required this.giftNum,
    required this.totalCoins,
  });

  @override
  State<_GiftBannerTile> createState() => _GiftBannerTileState();
}

class _GiftBannerTileState extends State<_GiftBannerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_anim);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.85),
                Colors.deepPurple.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.senderAvatar != null &&
                  widget.senderAvatar!.isNotEmpty)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.senderAvatar!,
                  ),
                )
              else
                const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 14),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.senderName,
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const TextSpan(
                        text: '  →  ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      TextSpan(
                        text: widget.receiverNames,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              CachedNetworkImage(
                imageUrl: widget.giftImg,
                width: 28,
                height: 28,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '×${widget.giftNum}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
