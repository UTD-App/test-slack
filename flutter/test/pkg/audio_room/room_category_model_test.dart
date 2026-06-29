import 'package:audio_room/src/domain/room_category_entity.dart';
import 'package:audio_room/src/domain/room_category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomCategoryModel.fromJson', () {
    test('parses a flat category', () {
      final c = RoomCategoryModel.fromJson({
        'id': 3,
        'parent_id': 1,
        'name': 'موسيقى',
        'name_en': 'Music',
        'img': 'music.png',
        'enable': true,
      });

      expect(c.id, 3);
      expect(c.parentId, 1);
      expect(c.name, 'موسيقى');
      expect(c.nameEn, 'Music');
      expect(c.image, 'music.png');
      expect(c.isEnabled, true);
      expect(c.children, isEmpty);
    });

    test('applies defaults for an empty payload', () {
      final c = RoomCategoryModel.fromJson(<String, dynamic>{});
      expect(c.id, 0);
      expect(c.parentId, isNull);
      expect(c.name, '');
      expect(c.nameEn, isNull);
      expect(c.image, isNull);
      expect(c.isEnabled, true); // default
      expect(c.children, isEmpty);
    });

    test('parses nested children recursively', () {
      final c = RoomCategoryModel.fromJson({
        'id': 1,
        'name': 'Parent',
        'children': [
          {
            'id': 2,
            'name': 'Child A',
            'children': [
              {'id': 4, 'name': 'Grandchild'},
            ],
          },
          {'id': 3, 'name': 'Child B'},
        ],
      });

      expect(c.children.length, 2);
      expect(c.children[0].id, 2);
      expect(c.children[0].name, 'Child A');
      expect(c.children[0].children.single.id, 4);
      expect(c.children[1].id, 3);
      expect(c.children[1].children, isEmpty);
    });

    test('coerces numeric id from double', () {
      final c = RoomCategoryModel.fromJson({'id': 9.0, 'parent_id': 2.0});
      expect(c.id, 9);
      expect(c.parentId, 2);
    });

    test('explicit enable=false is honoured', () {
      final c = RoomCategoryModel.fromJson({'id': 1, 'name': 'x', 'enable': false});
      expect(c.isEnabled, false);
    });
  });

  group('RoomCategoryEntity equality', () {
    test('equality is keyed on id only', () {
      const a = RoomCategoryEntity(id: 1, name: 'A');
      const b = RoomCategoryEntity(id: 1, name: 'B', isEnabled: false);
      expect(a, equals(b));
    });

    test('different ids differ', () {
      const a = RoomCategoryEntity(id: 1, name: 'A');
      const b = RoomCategoryEntity(id: 2, name: 'A');
      expect(a, isNot(equals(b)));
    });
  });
}
