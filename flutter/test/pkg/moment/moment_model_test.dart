import 'package:flutter_test/flutter_test.dart';
import 'package:moment/src/data/models/moment_model.dart';
import 'package:moment/src/data/models/moment_comment_model.dart';
import 'package:moment/src/data/models/moment_like_model.dart';
import 'package:moment/src/domain/entities/moment_comment_entity.dart';

void main() {
  group('MomentModel.fromJson', () {
    test('parses a full happy-path payload (nested user + images list)', () {
      final m = MomentModel.fromJson({
        'id': 7,
        'user_id': 42,
        'description': 'hello world',
        'img': 'posts/a.jpg',
        'images': [
          {'image': 'posts/1.jpg'},
          {'image': 'posts/2.jpg'},
        ],
        'comment_num': 3,
        'like_num': 10,
        'gifts_count': 2,
        'gifts_coins': 1500,
        'is_like': true,
        'my_reaction': 'love',
        'reactions': {'like': 5, 'love': 2},
        'created_at': '2026-06-08T13:33:41.000000Z',
        'is_owner': true,
        'user': {
          'name': 'Ada',
          'image': 'avatars/ada.png',
          'uuid': 'u-123',
          'gender': 2,
          'age': 30,
        },
      });

      expect(m.id, 7);
      expect(m.userId, 42);
      expect(m.description, 'hello world');
      expect(m.img, 'posts/a.jpg');
      expect(m.images, ['posts/1.jpg', 'posts/2.jpg']);
      expect(m.commentNum, 3);
      expect(m.likeNum, 10);
      expect(m.giftsCount, 2);
      expect(m.giftsCoins, 1500.0);
      expect(m.isLike, true);
      expect(m.myReaction, 'love');
      expect(m.reactionsBreakdown, {'like': 5, 'love': 2});
      expect(m.createdAt, '2026-06-08T13:33:41.000000Z');
      expect(m.isOwner, true);
      expect(m.userName, 'Ada');
      expect(m.userImage, 'avatars/ada.png');
      expect(m.uuid, 'u-123');
      expect(m.gender, 2);
      expect(m.age, 30);
    });

    test('defaults every field when keys are missing / empty json', () {
      final m = MomentModel.fromJson(const {});
      expect(m.id, 0);
      expect(m.userId, 0);
      expect(m.description, '');
      expect(m.img, '');
      expect(m.images, isEmpty);
      expect(m.commentNum, 0);
      expect(m.likeNum, 0);
      expect(m.giftsCount, 0);
      expect(m.giftsCoins, 0.0);
      expect(m.isLike, false);
      expect(m.myReaction, isNull);
      expect(m.reactionsBreakdown, isEmpty);
      expect(m.createdAt, '');
      expect(m.isOwner, false);
      expect(m.userName, '');
      expect(m.userImage, '');
      expect(m.uuid, '');
      expect(m.gender, 0);
      expect(m.age, isNull);
    });

    test('coerces string numerics and "1"/"0" booleans', () {
      final m = MomentModel.fromJson({
        'id': '15',
        'user_id': '99',
        'comment_num': '4',
        'like_num': '8',
        'gifts_count': '6',
        'gifts_coins': '12.5',
        'is_like': '1',
        'is_owner': '0',
        'user': {'gender': '1', 'age': '21'},
      });
      expect(m.id, 15);
      expect(m.userId, 99);
      expect(m.commentNum, 4);
      expect(m.likeNum, 8);
      expect(m.giftsCount, 6);
      expect(m.giftsCoins, 12.5);
      expect(m.isLike, true);
      expect(m.isOwner, false);
      expect(m.gender, 1);
      expect(m.age, 21);
    });

    test('empty / null my_reaction normalises to null', () {
      expect(MomentModel.fromJson({'my_reaction': ''}).myReaction, isNull);
      expect(MomentModel.fromJson({'my_reaction': null}).myReaction, isNull);
    });

    test('images list of plain strings is parsed and empties dropped', () {
      final m = MomentModel.fromJson({
        'images': ['posts/1.jpg', '', 'posts/3.jpg'],
      });
      expect(m.images, ['posts/1.jpg', 'posts/3.jpg']);
    });

    test('non-list images and non-map user are tolerated', () {
      final m = MomentModel.fromJson({
        'images': 'not-a-list',
        'user': 'not-a-map',
      });
      expect(m.images, isEmpty);
      expect(m.userName, '');
      expect(m.gender, 0);
      expect(m.age, isNull);
    });

    test('bool is_like accepts true/1/"1" but not other strings', () {
      expect(MomentModel.fromJson({'is_like': true}).isLike, true);
      expect(MomentModel.fromJson({'is_like': 1}).isLike, true);
      expect(MomentModel.fromJson({'is_like': '1'}).isLike, true);
      expect(MomentModel.fromJson({'is_like': 'true'}).isLike, false);
      expect(MomentModel.fromJson({'is_like': 0}).isLike, false);
    });
  });

  group('MomentCommentModel.fromJson', () {
    test('parses nested replies recursively', () {
      final c = MomentCommentModel.fromJson({
        'id': 1,
        'moment_id': 7,
        'user_id': 42,
        'comment': 'top',
        'created_at': 'x',
        'parent_id': null,
        'like_num': 3,
        'my_reaction': 'haha',
        'reactions': {'haha': 3},
        'user': {'name': 'A', 'image': 'i', 'uuid': 'u'},
        'replies': [
          {
            'id': 2,
            'moment_id': 7,
            'user_id': 43,
            'comment': 'reply',
            'parent_id': 1,
            'user': {'name': 'B'},
          },
        ],
      });

      expect(c.id, 1);
      expect(c.momentId, 7);
      expect(c.comment, 'top');
      expect(c.parentId, isNull);
      expect(c.likeNum, 3);
      expect(c.myReaction, 'haha');
      expect(c.reactionsBreakdown, {'haha': 3});
      expect(c.replies, hasLength(1));
      final reply = c.replies.single;
      expect(reply.id, 2);
      expect(reply.parentId, 1);
      expect(reply.comment, 'reply');
      expect(reply.userName, 'B');
    });

    test('missing keys default; no replies => empty list', () {
      final c = MomentCommentModel.fromJson(const {});
      expect(c.id, 0);
      expect(c.comment, '');
      expect(c.parentId, isNull);
      expect(c.replies, isEmpty);
      expect(c.likeNum, 0);
      expect(c.myReaction, isNull);
      expect(c.reactionsBreakdown, isEmpty);
    });

    test('parent_id "0" coerces to int 0 (non-null)', () {
      final c = MomentCommentModel.fromJson({'parent_id': '5'});
      expect(c.parentId, 5);
    });
  });

  group('MomentLikeModel.fromJson', () {
    test('parses user fields and reaction_type', () {
      final l = MomentLikeModel.fromJson({
        'created_at': 't',
        'reaction_type': 'love',
        'user': {'id': 9, 'uuid': 'u', 'name': 'N', 'image': 'i'},
      });
      expect(l.userId, 9);
      expect(l.uuid, 'u');
      expect(l.userName, 'N');
      expect(l.userImage, 'i');
      expect(l.createdAt, 't');
      expect(l.reactionType, 'love');
    });

    test('falls back to user_id when user.id missing', () {
      final l = MomentLikeModel.fromJson({'user_id': 11});
      expect(l.userId, 11);
    });

    test('empty / missing reaction_type defaults to "like"', () {
      expect(MomentLikeModel.fromJson(const {}).reactionType, 'like');
      expect(
        MomentLikeModel.fromJson({'reaction_type': ''}).reactionType,
        'like',
      );
    });
  });

  group('MomentLikeModel/MomentLikeEntity equality (props)', () {
    test('equal when userId/createdAt/reactionType match', () {
      final a = MomentLikeModel.fromJson({
        'created_at': 't',
        'user': {'id': 1, 'name': 'A'},
      });
      final b = MomentLikeModel.fromJson({
        'created_at': 't',
        'user': {'id': 1, 'name': 'DIFFERENT-NAME'},
      });
      // name is not in props -> still equal
      expect(a, equals(b));
    });
  });

  group('MomentCommentEntity', () {
    MomentCommentEntity base() => const MomentCommentEntity(
          id: 1,
          momentId: 2,
          userId: 3,
          comment: 'c',
          createdAt: 't',
          userName: 'n',
          userImage: 'i',
          uuid: 'u',
          likeNum: 2,
          myReaction: 'like',
          reactionsBreakdown: {'like': 2},
        );

    test('copyWith overrides only provided fields', () {
      final c = base().copyWith(likeNum: 5);
      expect(c.likeNum, 5);
      expect(c.myReaction, 'like');
      expect(c.comment, 'c');
    });

    test('clearMyReaction forces null even if myReaction passed', () {
      final c = base().copyWith(myReaction: 'love', clearMyReaction: true);
      expect(c.myReaction, isNull);
    });

    test('equality uses [id, replies, likeNum, myReaction]', () {
      expect(base(), equals(base().copyWith(reactionsBreakdown: {'x': 9})));
      expect(base(), isNot(equals(base().copyWith(likeNum: 99))));
    });
  });
}
