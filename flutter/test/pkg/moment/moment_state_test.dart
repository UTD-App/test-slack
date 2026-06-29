import 'package:flutter_test/flutter_test.dart';
import 'package:moment/src/domain/entities/moment_entity.dart';
import 'package:moment/src/presentation/bloc/moment_feed/moment_feed_state.dart';
import 'package:moment/src/presentation/bloc/moment_comments/moment_comments_cubit.dart';
import 'package:moment/src/presentation/bloc/moment_likes/moment_likes_cubit.dart';

MomentEntity _moment(int id) => MomentEntity(
      id: id,
      userId: 1,
      description: 'd',
      img: 'i',
      images: const [],
      commentNum: 0,
      likeNum: 0,
      giftsCount: 0,
      giftsCoins: 0,
      isLike: false,
      createdAt: 't',
      userName: 'n',
      userImage: 'ui',
      uuid: 'u',
      gender: 0,
      age: null,
    );

void main() {
  group('MomentFeedState', () {
    test('sensible defaults', () {
      const s = MomentFeedState();
      expect(s.status, FeedStatus.initial);
      expect(s.moments, isEmpty);
      expect(s.page, 1);
      expect(s.hasMore, true);
      expect(s.isLoadingMore, false);
      expect(s.isSubmitting, false);
      expect(s.error, isNull);
    });

    test('copyWith overrides only provided fields', () {
      const s = MomentFeedState();
      final updated = s.copyWith(
        status: FeedStatus.success,
        moments: [_moment(1)],
        page: 2,
        hasMore: false,
        isLoadingMore: true,
        isSubmitting: true,
      );
      expect(updated.status, FeedStatus.success);
      expect(updated.moments, hasLength(1));
      expect(updated.page, 2);
      expect(updated.hasMore, false);
      expect(updated.isLoadingMore, true);
      expect(updated.isSubmitting, true);
    });

    test('error is NOT carried over by copyWith (always reset)', () {
      // copyWith assigns `error: error` directly, so it resets unless re-passed.
      const s = MomentFeedState(error: 'boom');
      final cleared = s.copyWith(status: FeedStatus.loading);
      expect(cleared.error, isNull);
      final kept = s.copyWith(error: 'still');
      expect(kept.error, 'still');
    });

    test('equality reflects prop fields', () {
      const a = MomentFeedState(page: 1);
      const b = MomentFeedState(page: 2);
      expect(a, isNot(equals(b)));
      expect(const MomentFeedState(), equals(const MomentFeedState()));
    });

    test('two states with same moment list are equal', () {
      final a = const MomentFeedState().copyWith(moments: [_moment(1)]);
      final b = const MomentFeedState().copyWith(moments: [_moment(1)]);
      expect(a, equals(b));
    });
  });

  group('MomentCommentsState', () {
    test('defaults', () {
      const s = MomentCommentsState();
      expect(s.status, CommentsStatus.initial);
      expect(s.comments, isEmpty);
      expect(s.isSubmitting, false);
      expect(s.isLoadingMore, false);
      expect(s.hasMore, true);
      expect(s.page, 1);
      expect(s.error, isNull);
    });

    test('copyWith and error-reset behaviour', () {
      const s = MomentCommentsState(error: 'x');
      final u = s.copyWith(status: CommentsStatus.success, page: 3);
      expect(u.status, CommentsStatus.success);
      expect(u.page, 3);
      expect(u.error, isNull); // not re-passed -> reset
    });

    test('equality', () {
      expect(
        const MomentCommentsState(page: 1),
        equals(const MomentCommentsState(page: 1)),
      );
      expect(
        const MomentCommentsState(page: 1),
        isNot(equals(const MomentCommentsState(page: 2))),
      );
    });
  });

  group('MomentLikesState', () {
    test('defaults', () {
      const s = MomentLikesState();
      expect(s.status, LikesStatus.initial);
      expect(s.likes, isEmpty);
      expect(s.isLoadingMore, false);
      expect(s.hasMore, true);
      expect(s.page, 1);
      expect(s.error, isNull);
    });

    test('copyWith updates fields; error resets when omitted', () {
      const s = MomentLikesState(error: 'e');
      final u = s.copyWith(status: LikesStatus.loading, page: 4, hasMore: false);
      expect(u.status, LikesStatus.loading);
      expect(u.page, 4);
      expect(u.hasMore, false);
      expect(u.error, isNull);
    });
  });
}
