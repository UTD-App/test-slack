import 'package:flutter_test/flutter_test.dart';
import 'package:reels/src/domain/entities/real_entity.dart';
import 'package:reels/src/domain/entities/real_comment_entity.dart';

RealEntity _reel({
  int id = 1,
  int likesCount = 10,
  int commentsCount = 3,
  bool isLike = false,
  String description = 'd',
  String? myReaction,
  Map<String, int> reactions = const {},
}) {
  return RealEntity(
    id: id,
    userId: 5,
    description: description,
    url: 'u',
    subVideo: 'sv',
    subFrame: 'sf',
    likesCount: likesCount,
    commentsCount: commentsCount,
    viewsCount: 100,
    isLike: isLike,
    shareCount: 2,
    createdAt: 't',
    myReaction: myReaction,
    reactionsBreakdown: reactions,
    isOwner: true,
    userName: 'n',
    userImage: 'ui',
    uuid: 'uu',
    gender: 1,
    age: 22,
  );
}

void main() {
  group('RealEntity.copyWith', () {
    test('no-arg copy equals original', () {
      final r = _reel();
      expect(r.copyWith(), equals(r));
    });

    test('overrides only requested fields', () {
      final r = _reel();
      final c = r.copyWith(
        likesCount: 99,
        commentsCount: 7,
        isLike: true,
        description: 'new',
      );
      expect(c.likesCount, 99);
      expect(c.commentsCount, 7);
      expect(c.isLike, true);
      expect(c.description, 'new');
      // untouched
      expect(c.url, r.url);
      expect(c.viewsCount, r.viewsCount);
      expect(c.shareCount, r.shareCount);
    });

    test('clearMyReaction overrides myReaction argument', () {
      final r = _reel(myReaction: 'love');
      final c = r.copyWith(myReaction: 'wow', clearMyReaction: true);
      expect(c.myReaction, isNull);
    });

    test('viewsCount default is 0 when not provided', () {
      const r = RealEntity(
        id: 1,
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
      expect(r.viewsCount, 0);
    });
  });

  group('RealEntity equality (props)', () {
    test('equal when prop fields match', () {
      expect(_reel(), equals(_reel()));
    });

    test('differs when a prop field changes', () {
      expect(_reel(likesCount: 1), isNot(equals(_reel(likesCount: 2))));
      expect(_reel(description: 'a'), isNot(equals(_reel(description: 'b'))));
      expect(
        _reel(reactions: {'like': 1}),
        isNot(equals(_reel(reactions: {'like': 9}))),
      );
    });

    test('non-prop fields (url/userName) do not affect equality', () {
      final a = _reel();
      final b = RealEntity(
        id: a.id,
        userId: 999,
        description: a.description,
        url: 'DIFFERENT',
        subVideo: 'DIFFERENT',
        subFrame: 'DIFFERENT',
        likesCount: a.likesCount,
        commentsCount: a.commentsCount,
        viewsCount: 99999,
        isLike: a.isLike,
        shareCount: 99,
        createdAt: 'OTHER',
        myReaction: a.myReaction,
        reactionsBreakdown: a.reactionsBreakdown,
        isOwner: false,
        userName: 'OTHER',
        userImage: 'OTHER',
        uuid: 'OTHER',
        gender: 9,
        age: 99,
      );
      expect(a, equals(b));
    });
  });

  group('RealCommentEntity', () {
    RealCommentEntity base() => const RealCommentEntity(
          id: 1,
          realId: 2,
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
      final c = base().copyWith(likeNum: 9);
      expect(c.likeNum, 9);
      expect(c.myReaction, 'like');
    });

    test('clearMyReaction forces null', () {
      final c = base().copyWith(myReaction: 'love', clearMyReaction: true);
      expect(c.myReaction, isNull);
    });

    test('equality uses [id, replies, likeNum, myReaction]', () {
      expect(base(), equals(base().copyWith(reactionsBreakdown: {'z': 1})));
      expect(base(), isNot(equals(base().copyWith(likeNum: 100))));
    });
  });
}
