import 'package:flutter_test/flutter_test.dart';
import 'package:moment/src/domain/entities/moment_entity.dart';

MomentEntity _moment({
  int id = 1,
  int likeNum = 10,
  int commentNum = 3,
  bool isLike = false,
  int giftsCount = 0,
  double giftsCoins = 0,
  String? myReaction,
  Map<String, int> reactions = const {},
}) {
  return MomentEntity(
    id: id,
    userId: 42,
    description: 'd',
    img: 'i',
    images: const ['a', 'b'],
    commentNum: commentNum,
    likeNum: likeNum,
    giftsCount: giftsCount,
    giftsCoins: giftsCoins,
    isLike: isLike,
    myReaction: myReaction,
    reactionsBreakdown: reactions,
    createdAt: 't',
    isOwner: true,
    userName: 'n',
    userImage: 'ui',
    uuid: 'u',
    gender: 1,
    age: 22,
  );
}

void main() {
  group('MomentEntity.copyWith', () {
    test('returns identical-valued copy when nothing passed', () {
      final m = _moment();
      final c = m.copyWith();
      expect(c, equals(m));
      expect(c.likeNum, m.likeNum);
      expect(c.commentNum, m.commentNum);
    });

    test('overrides only the requested fields', () {
      final m = _moment();
      final c = m.copyWith(likeNum: 99, isLike: true, giftsCoins: 5000);
      expect(c.likeNum, 99);
      expect(c.isLike, true);
      expect(c.giftsCoins, 5000);
      // untouched
      expect(c.commentNum, m.commentNum);
      expect(c.description, m.description);
      expect(c.images, m.images);
    });

    test('myReaction passes through when provided', () {
      final c = _moment().copyWith(myReaction: 'love');
      expect(c.myReaction, 'love');
    });

    test('clearMyReaction wins over myReaction argument', () {
      final m = _moment(myReaction: 'love');
      final c = m.copyWith(myReaction: 'haha', clearMyReaction: true);
      expect(c.myReaction, isNull);
    });

    test('clearMyReaction=false keeps existing reaction', () {
      final m = _moment(myReaction: 'love');
      final c = m.copyWith(likeNum: 1);
      expect(c.myReaction, 'love');
    });
  });

  group('MomentEntity equality (Equatable props)', () {
    test('two moments with same props are equal', () {
      expect(_moment(), equals(_moment()));
    });

    test('differs when a prop field changes', () {
      expect(_moment(likeNum: 1), isNot(equals(_moment(likeNum: 2))));
      expect(_moment(giftsCoins: 1), isNot(equals(_moment(giftsCoins: 2))));
      expect(
        _moment(reactions: {'like': 1}),
        isNot(equals(_moment(reactions: {'like': 2}))),
      );
    });

    test('non-prop fields (description/userName) do not affect equality', () {
      final a = _moment();
      final b = MomentEntity(
        id: a.id,
        userId: 999,
        description: 'TOTALLY DIFFERENT',
        img: 'zzz',
        images: const ['x'],
        commentNum: a.commentNum,
        likeNum: a.likeNum,
        giftsCount: a.giftsCount,
        giftsCoins: a.giftsCoins,
        isLike: a.isLike,
        myReaction: a.myReaction,
        reactionsBreakdown: a.reactionsBreakdown,
        createdAt: 'OTHER',
        isOwner: false,
        userName: 'OTHER',
        userImage: 'OTHER',
        uuid: 'OTHER',
        gender: 9,
        age: 99,
      );
      expect(a, equals(b));
    });

    test('regression: second gift updates equality via giftsCount/giftsCoins', () {
      // The entity comment notes this used to be a bug — both must be in props.
      final first = _moment(giftsCount: 1, giftsCoins: 100);
      final second = first.copyWith(giftsCount: 2, giftsCoins: 200);
      expect(first, isNot(equals(second)));
    });
  });
}
