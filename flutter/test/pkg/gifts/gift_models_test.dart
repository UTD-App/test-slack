import 'package:flutter_test/flutter_test.dart';
import 'package:gifts/src/data/models/gift_model.dart';
import 'package:gifts/src/data/models/gift_category_model.dart';
import 'package:gifts/src/data/models/gift_history_item_model.dart';
import 'package:gifts/src/domain/entities/gift.dart';
import 'package:gifts/src/domain/entities/gift_category.dart';
import 'package:gifts/src/domain/entities/gift_history_item.dart';

void main() {
  group('GiftModel.fromJson', () {
    test('parses a fully-populated payload', () {
      final g = GiftModel.fromJson(const {
        'id': 7,
        'name': 'Rose',
        'type': 2,
        'category_id': 3,
        'price': 100,
        'img': 'gifts/rose.png',
        'show_img': 'gifts/rose.svga',
        'image_type': 'svga',
        'vip_level': 1,
        'is_play': true,
      });

      expect(g.id, 7);
      expect(g.name, 'Rose');
      expect(g.type, 2);
      expect(g.categoryId, 3);
      expect(g.price, 100);
      expect(g.img, 'gifts/rose.png');
      expect(g.showImg, 'gifts/rose.svga');
      expect(g.imageType, 'svga');
      expect(g.vipLevel, 1);
      expect(g.isPlay, isTrue);
      expect(g, isA<Gift>());
    });

    test('applies defaults for an empty payload', () {
      final g = GiftModel.fromJson(const {});
      expect(g.id, 0);
      expect(g.name, '');
      expect(g.type, 0);
      expect(g.categoryId, isNull); // category_id absent -> null
      expect(g.price, 0);
      expect(g.img, '');
      expect(g.showImg, '');
      expect(g.imageType, '');
      expect(g.vipLevel, 0);
      expect(g.isPlay, isFalse);
    });

    test('coerces numeric fields from strings', () {
      final g = GiftModel.fromJson(const {
        'id': '12',
        'type': '4',
        'category_id': '9',
        'price': '250',
        'vip_level': '2',
      });
      expect(g.id, 12);
      expect(g.type, 4);
      expect(g.categoryId, 9);
      expect(g.price, 250);
      expect(g.vipLevel, 2);
    });

    test('unparseable numeric strings fall back to 0', () {
      final g = GiftModel.fromJson(const {'id': 'abc', 'price': 'free'});
      expect(g.id, 0);
      expect(g.price, 0);
    });

    test('explicit null category_id stays null', () {
      final g = GiftModel.fromJson(const {'id': 1, 'category_id': null});
      expect(g.categoryId, isNull);
    });

    group('is_play truthiness', () {
      test('integer 1 -> true', () {
        expect(GiftModel.fromJson(const {'is_play': 1}).isPlay, isTrue);
      });
      test('string "1" -> true', () {
        expect(GiftModel.fromJson(const {'is_play': '1'}).isPlay, isTrue);
      });
      test('bool true -> true', () {
        expect(GiftModel.fromJson(const {'is_play': true}).isPlay, isTrue);
      });
      test('integer 0 -> false', () {
        expect(GiftModel.fromJson(const {'is_play': 0}).isPlay, isFalse);
      });
      test('string "0" -> false', () {
        expect(GiftModel.fromJson(const {'is_play': '0'}).isPlay, isFalse);
      });
      test('absent -> false', () {
        expect(GiftModel.fromJson(const {}).isPlay, isFalse);
      });
    });

    test('non-string scalar names are stringified', () {
      expect(GiftModel.fromJson(const {'name': 5}).name, '5');
    });
  });

  group('Gift equality', () {
    test('is identity-by-id (props == [id])', () {
      const a = GiftModel(
        id: 1,
        name: 'A',
        type: 1,
        categoryId: 1,
        price: 10,
        img: 'a',
        showImg: 'a',
        imageType: 'png',
        vipLevel: 0,
      );
      const b = GiftModel(
        id: 1,
        name: 'TOTALLY DIFFERENT',
        type: 9,
        categoryId: 9,
        price: 999,
        img: 'z',
        showImg: 'z',
        imageType: 'svga',
        vipLevel: 5,
      );
      const c = GiftModel(
        id: 2,
        name: 'A',
        type: 1,
        categoryId: 1,
        price: 10,
        img: 'a',
        showImg: 'a',
        imageType: 'png',
        vipLevel: 0,
      );
      expect(a, equals(b)); // same id -> equal regardless of other fields
      expect(a, isNot(equals(c)));
    });
  });

  group('GiftCategoryModel.fromJson', () {
    test('parses populated payload', () {
      final c = GiftCategoryModel.fromJson(const {
        'id': 4,
        'title': 'Popular',
        'type': 'hot',
      });
      expect(c.id, 4);
      expect(c.title, 'Popular');
      expect(c.type, 'hot');
      expect(c, isA<GiftCategory>());
    });

    test('defaults: type -> "normal", title -> "", id -> 0', () {
      final c = GiftCategoryModel.fromJson(const {});
      expect(c.id, 0);
      expect(c.title, '');
      expect(c.type, 'normal');
    });

    test('coerces id from string', () {
      expect(GiftCategoryModel.fromJson(const {'id': '15'}).id, 15);
    });

    test('equality is by id', () {
      const a = GiftCategoryModel(id: 1, title: 'X', type: 'a');
      const b = GiftCategoryModel(id: 1, title: 'Y', type: 'b');
      expect(a, equals(b));
    });
  });

  group('GiftHistoryItemModel.fromJson', () {
    test('parses populated payload', () {
      final h = GiftHistoryItemModel.fromJson(const {
        'id': 99,
        'gift_name': 'Diamond',
        'gift_num': 3,
        'total_price': 300.5,
        'earned': 150.25,
        'direction': 'sent',
        'created_at': '2026-06-29T12:00:00Z',
      });
      expect(h.id, 99);
      expect(h.giftName, 'Diamond');
      expect(h.giftNum, 3);
      expect(h.totalPrice, 300.5);
      expect(h.earned, 150.25);
      expect(h.direction, 'sent');
      expect(h.createdAt, '2026-06-29T12:00:00Z');
      expect(h, isA<GiftHistoryItem>());
    });

    test('defaults for empty payload (direction -> "received")', () {
      final h = GiftHistoryItemModel.fromJson(const {});
      expect(h.id, 0);
      expect(h.giftName, '');
      expect(h.giftNum, 0);
      expect(h.totalPrice, 0.0);
      expect(h.earned, 0.0);
      expect(h.direction, 'received');
      expect(h.createdAt, '');
    });

    test('coerces doubles from int and string', () {
      final h = GiftHistoryItemModel.fromJson(const {
        'total_price': 200, // int -> double
        'earned': '99.9', // string -> double
      });
      expect(h.totalPrice, 200.0);
      expect(h.earned, 99.9);
    });

    test('unparseable double strings fall back to 0.0', () {
      final h = GiftHistoryItemModel.fromJson(const {'total_price': 'lots'});
      expect(h.totalPrice, 0.0);
    });

    test('equality is by id', () {
      const a = GiftHistoryItemModel(
        id: 5,
        giftName: 'a',
        giftNum: 1,
        totalPrice: 1,
        earned: 1,
        direction: 'sent',
        createdAt: 'x',
      );
      const b = GiftHistoryItemModel(
        id: 5,
        giftName: 'b',
        giftNum: 9,
        totalPrice: 9,
        earned: 9,
        direction: 'received',
        createdAt: 'y',
      );
      expect(a, equals(b));
    });
  });
}
