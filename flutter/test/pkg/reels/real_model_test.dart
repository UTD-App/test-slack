import 'package:flutter_test/flutter_test.dart';
import 'package:reels/src/data/models/real_model.dart';
import 'package:reels/src/data/models/real_comment_model.dart';
import 'package:reels/src/data/models/real_like_model.dart';

void main() {
  group('RealModel.fromJson', () {
    test('parses a full happy-path payload', () {
      final r = RealModel.fromJson({
        'id': 3,
        'user_id': 55,
        'description': 'my reel',
        'url': 'reels/v.mp4',
        'sub_video': 'reels/sv.mp4',
        'sub_frame': 'reels/poster.jpg',
        'likes_count': 12,
        'comments_count': 4,
        'views_count': 999,
        'likes_exists': true,
        'share_count': 7,
        'created_at': '2026-06-08T13:33:41.000000Z',
        'my_reaction': 'wow',
        'reactions': {'like': 8, 'wow': 4},
        'is_owner': true,
        'user': {
          'name': 'Grace',
          'image': 'avatars/g.png',
          'uuid': 'u-9',
          'gender': 1,
          'age': 28,
        },
      });

      expect(r.id, 3);
      expect(r.userId, 55);
      expect(r.description, 'my reel');
      expect(r.url, 'reels/v.mp4');
      expect(r.subVideo, 'reels/sv.mp4');
      expect(r.subFrame, 'reels/poster.jpg');
      expect(r.likesCount, 12);
      expect(r.commentsCount, 4);
      expect(r.viewsCount, 999);
      expect(r.isLike, true);
      expect(r.shareCount, 7);
      expect(r.createdAt, '2026-06-08T13:33:41.000000Z');
      expect(r.myReaction, 'wow');
      expect(r.reactionsBreakdown, {'like': 8, 'wow': 4});
      expect(r.isOwner, true);
      expect(r.userName, 'Grace');
      expect(r.userImage, 'avatars/g.png');
      expect(r.uuid, 'u-9');
      expect(r.gender, 1);
      expect(r.age, 28);
    });

    test('defaults on empty json', () {
      final r = RealModel.fromJson(const {});
      expect(r.id, 0);
      expect(r.userId, 0);
      expect(r.description, '');
      expect(r.url, '');
      expect(r.subVideo, '');
      expect(r.subFrame, '');
      expect(r.likesCount, 0);
      expect(r.commentsCount, 0);
      expect(r.viewsCount, 0);
      expect(r.isLike, false);
      expect(r.shareCount, 0);
      expect(r.createdAt, '');
      expect(r.myReaction, isNull);
      expect(r.reactionsBreakdown, isEmpty);
      expect(r.isOwner, false);
      expect(r.userName, '');
      expect(r.gender, 0);
      expect(r.age, isNull);
    });

    test('is_like is driven by likes_exists key', () {
      expect(RealModel.fromJson({'likes_exists': true}).isLike, true);
      expect(RealModel.fromJson({'likes_exists': 1}).isLike, true);
      expect(RealModel.fromJson({'likes_exists': '1'}).isLike, true);
      expect(RealModel.fromJson({'likes_exists': false}).isLike, false);
      // a plain `is_like` key is ignored (backend sends likes_exists)
      expect(RealModel.fromJson({'is_like': true}).isLike, false);
    });

    test('string numerics coerce', () {
      final r = RealModel.fromJson({
        'id': '3',
        'likes_count': '12',
        'comments_count': '4',
        'views_count': '50',
        'share_count': '2',
        'user': {'gender': '2', 'age': '40'},
      });
      expect(r.id, 3);
      expect(r.likesCount, 12);
      expect(r.commentsCount, 4);
      expect(r.viewsCount, 50);
      expect(r.shareCount, 2);
      expect(r.gender, 2);
      expect(r.age, 40);
    });

    test('empty / null my_reaction normalises to null', () {
      expect(RealModel.fromJson({'my_reaction': ''}).myReaction, isNull);
      expect(RealModel.fromJson({'my_reaction': null}).myReaction, isNull);
    });

    test('non-map user tolerated', () {
      final r = RealModel.fromJson({'user': 'nope'});
      expect(r.userName, '');
      expect(r.gender, 0);
      expect(r.age, isNull);
    });
  });

  group('RealCommentModel.fromJson', () {
    test('parses nested replies recursively', () {
      final c = RealCommentModel.fromJson({
        'id': 1,
        'real_id': 3,
        'user_id': 55,
        'comment': 'nice',
        'created_at': 't',
        'like_num': 2,
        'my_reaction': 'like',
        'reactions': {'like': 2},
        'user': {'name': 'A', 'uuid': 'u'},
        'replies': [
          {
            'id': 2,
            'real_id': 3,
            'parent_id': 1,
            'comment': 'thx',
            'user': {'name': 'B'},
          },
        ],
      });

      expect(c.id, 1);
      expect(c.realId, 3);
      expect(c.comment, 'nice');
      expect(c.likeNum, 2);
      expect(c.myReaction, 'like');
      expect(c.replies, hasLength(1));
      expect(c.replies.single.id, 2);
      expect(c.replies.single.parentId, 1);
      expect(c.replies.single.comment, 'thx');
    });

    test('defaults on empty json', () {
      final c = RealCommentModel.fromJson(const {});
      expect(c.id, 0);
      expect(c.realId, 0);
      expect(c.comment, '');
      expect(c.parentId, isNull);
      expect(c.replies, isEmpty);
      expect(c.likeNum, 0);
      expect(c.myReaction, isNull);
    });
  });

  group('RealLikeModel.fromJson', () {
    test('parses user fields + reaction_type', () {
      final l = RealLikeModel.fromJson({
        'created_at': 't',
        'reaction_type': 'sad',
        'user': {'id': 5, 'uuid': 'u', 'name': 'N', 'image': 'i'},
      });
      expect(l.userId, 5);
      expect(l.uuid, 'u');
      expect(l.userName, 'N');
      expect(l.userImage, 'i');
      expect(l.reactionType, 'sad');
    });

    test('falls back to user_id; defaults reaction to like', () {
      final l = RealLikeModel.fromJson({'user_id': 8});
      expect(l.userId, 8);
      expect(l.reactionType, 'like');
    });
  });
}
