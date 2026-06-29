import 'package:flutter_test/flutter_test.dart';
import 'package:reels/src/domain/entities/real_entity.dart';
import 'package:reels/src/presentation/bloc/reels_feed/reels_feed_state.dart';
import 'package:reels/src/presentation/bloc/reels_comments/reels_comments_cubit.dart';
import 'package:reels/src/presentation/bloc/reels_likes/reels_likes_cubit.dart';
import 'package:reels/src/presentation/bloc/reels_profile/reels_profile_cubit.dart';

RealEntity _reel(int id) => RealEntity(
      id: id,
      userId: 1,
      description: 'd',
      url: 'u',
      subVideo: '',
      subFrame: '',
      likesCount: 0,
      commentsCount: 0,
      isLike: false,
      shareCount: 0,
      createdAt: 't',
      userName: 'n',
      userImage: 'i',
      uuid: 'u',
      gender: 0,
      age: null,
    );

void main() {
  group('ReelsFeedState', () {
    test('defaults', () {
      const s = ReelsFeedState();
      expect(s.status, FeedStatus.initial);
      expect(s.reels, isEmpty);
      expect(s.page, 1);
      expect(s.hasMore, true);
      expect(s.isLoadingMore, false);
      expect(s.isSubmitting, false);
      expect(s.error, isNull);
      expect(s.seed, 0);
    });

    test('copyWith overrides fields incl. seed', () {
      const s = ReelsFeedState();
      final u = s.copyWith(
        status: FeedStatus.success,
        reels: [_reel(1)],
        page: 2,
        hasMore: false,
        isLoadingMore: true,
        isSubmitting: true,
        seed: 7,
      );
      expect(u.status, FeedStatus.success);
      expect(u.reels, hasLength(1));
      expect(u.page, 2);
      expect(u.hasMore, false);
      expect(u.isLoadingMore, true);
      expect(u.isSubmitting, true);
      expect(u.seed, 7);
    });

    test('error resets unless re-passed', () {
      const s = ReelsFeedState(error: 'boom');
      expect(s.copyWith(page: 2).error, isNull);
      expect(s.copyWith(error: 'keep').error, 'keep');
    });

    test('seed participates in equality', () {
      expect(
        const ReelsFeedState(seed: 1),
        isNot(equals(const ReelsFeedState(seed: 2))),
      );
      expect(const ReelsFeedState(seed: 5), equals(const ReelsFeedState(seed: 5)));
    });
  });

  group('ReelsCommentsState', () {
    test('defaults + copyWith error reset', () {
      const s = ReelsCommentsState(error: 'e');
      expect(s.status, CommentsStatus.initial);
      expect(s.page, 1);
      final u = s.copyWith(status: CommentsStatus.success, page: 3);
      expect(u.status, CommentsStatus.success);
      expect(u.page, 3);
      expect(u.error, isNull);
    });
  });

  group('ReelsLikesState', () {
    test('defaults + copyWith', () {
      const s = ReelsLikesState();
      expect(s.status, LikesStatus.initial);
      expect(s.hasMore, true);
      final u = s.copyWith(status: LikesStatus.loading, page: 2, hasMore: false);
      expect(u.status, LikesStatus.loading);
      expect(u.page, 2);
      expect(u.hasMore, false);
    });
  });

  group('ReelsProfileState', () {
    test('defaults', () {
      const s = ReelsProfileState();
      expect(s.status, ReelsProfileStatus.initial);
      expect(s.reels, isEmpty);
      expect(s.error, isNull);
    });

    test('copyWith updates status/reels; error resets when omitted', () {
      const s = ReelsProfileState(error: 'x');
      final u = s.copyWith(
        status: ReelsProfileStatus.success,
        reels: [_reel(1), _reel(2)],
      );
      expect(u.status, ReelsProfileStatus.success);
      expect(u.reels, hasLength(2));
      expect(u.error, isNull);
    });

    test('equality reflects reels list + status', () {
      final a = const ReelsProfileState().copyWith(reels: [_reel(1)]);
      final b = const ReelsProfileState().copyWith(reels: [_reel(1)]);
      expect(a, equals(b));
      expect(a, isNot(equals(const ReelsProfileState().copyWith(reels: [_reel(2)]))));
    });
  });
}
