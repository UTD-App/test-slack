import 'package:flutter/material.dart';

const Color _kBase = Color(0xFF332E4A);
const Color _kHighlight = Color(0xFF463F63);

/// Sweeps a soft highlight across its child. Wrap a tree of [SkeletonBox]es in
/// it to get the classic "loading shimmer" instead of a bare spinner.
///
/// Uses a single [AnimationController] for the whole subtree (one ticker), so a
/// full skeleton screen stays cheap.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Slide a 3-stop gradient window across the bounds. Alignment values
        // can exceed [-1, 1], so this moves the highlight fully in and out.
        final t = _controller.value * 2 - 1; // -1 → 1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(t - 1, 0),
            end: Alignment(t + 1, 0),
            colors: const [_kBase, _kHighlight, _kBase],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// A single opaque rounded block — a stand-in for an avatar / line / image while
/// the real content loads. Opaque so the [Shimmer] ShaderMask (srcATop) paints
/// its moving highlight over it.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
