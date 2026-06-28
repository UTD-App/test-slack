import 'package:flutter/material.dart';

import 'shimmer.dart';

/// A shimmering placeholder of a few moment cards, shown while the feed's first
/// page loads (and there's no cache to paint). Ghost content floats over the
/// app background — only the [SkeletonBox]es are opaque, so only they shimmer.
class MomentFeedSkeleton extends StatelessWidget {
  final int count;
  const MomentFeedSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, __) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              SkeletonBox(width: 42, height: 42, radius: 21),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 130, height: 12),
                    SizedBox(height: 7),
                    SkeletonBox(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 7),
          SkeletonBox(width: 220, height: 12),
          SizedBox(height: 14),
          SkeletonBox(width: double.infinity, height: 190, radius: 14),
        ],
      ),
    );
  }
}
