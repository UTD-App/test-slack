import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/src/parsers/stac_list_parser.dart';
import 'package:utd_studio_sdk/src/parsers/stac_loading_parser.dart';
import 'package:utd_studio_sdk/src/parsers/stac_object_parser.dart';
import 'package:utd_studio_sdk/src/parsers/stac_scroll_parser.dart';
import 'package:utd_studio_sdk/src/parsers/utd_sized_parser.dart';
import 'package:utd_studio_sdk/src/parsers/utd_tabs_parser.dart';
import 'package:utd_studio_sdk/src/parsers/utd_text_field_parser.dart';

void main() {
  group('StacUtdSized.fromJson', () {
    test('parses width/height percent and child', () {
      final m = StacUtdSized.fromJson(const {
        'widthPercent': 80,
        'heightPercent': 50,
        'child': {'type': 'text'},
      });
      expect(m.widthPercent, 80.0);
      expect(m.heightPercent, 50.0);
      expect(m.child, {'type': 'text'});
    });

    test('absent fields are null', () {
      final m = StacUtdSized.fromJson(const {});
      expect(m.widthPercent, isNull);
      expect(m.heightPercent, isNull);
      expect(m.child, isNull);
    });

    test('parser type', () {
      expect(const StacUtdSizedParser().type, 'utdSized');
    });
  });

  group('StacUtdTabs.fromJson', () {
    test('parses tabs and core fields', () {
      final m = StacUtdTabs.fromJson(const {
        'length': 2,
        'initialIndex': 1,
        'position': 'bottom',
        'swipe': false,
        'distribution': 'scroll',
        'alignment': 'center',
        'barBackground': '#112233',
        'barPadding': 8,
        'barSize': 56,
        'barGap': 4,
        'tabs': [
          {'data': {'text': 'A'}},
          {'data': {'text': 'B'}},
        ],
      });
      expect(m.length, 2);
      expect(m.initialIndex, 1);
      expect(m.position, 'bottom');
      expect(m.swipe, false);
      expect(m.distribution, 'scroll');
      expect(m.alignment, 'center');
      expect(m.barBackground, '#112233');
      expect(m.barPadding, 8.0);
      expect(m.barSize, 56.0);
      expect(m.barGap, 4.0);
      expect(m.tabs, hasLength(2));
    });

    test('length defaults to the tab count when omitted', () {
      final m = StacUtdTabs.fromJson(const {
        'tabs': [
          {'data': {'text': 'A'}},
          {'data': {'text': 'B'}},
          {'data': {'text': 'C'}},
        ],
      });
      expect(m.length, 3);
    });

    test('length is floored at 1 even if 0/negative is given', () {
      final m = StacUtdTabs.fromJson(const {'length': 0, 'tabs': []});
      expect(m.length, 1);
    });

    test('initialIndex is clamped into [0, length-1]', () {
      final m = StacUtdTabs.fromJson(const {
        'length': 2,
        'initialIndex': 9,
        'tabs': [],
      });
      expect(m.initialIndex, 1);
    });

    test('defaults: top / swipe / fill / start', () {
      final m = StacUtdTabs.fromJson(const {'tabs': []});
      expect(m.position, 'top');
      expect(m.swipe, true);
      expect(m.distribution, 'fill');
      expect(m.alignment, 'start');
    });

    test('isVertical is true only for left/right', () {
      expect(StacUtdTabs.fromJson(const {'position': 'left', 'tabs': []}).isVertical,
          isTrue);
      expect(StacUtdTabs.fromJson(const {'position': 'right', 'tabs': []}).isVertical,
          isTrue);
      expect(StacUtdTabs.fromJson(const {'position': 'top', 'tabs': []}).isVertical,
          isFalse);
      expect(
          StacUtdTabs.fromJson(const {'position': 'bottom', 'tabs': []}).isVertical,
          isFalse);
    });

    test('non-map entries in the tabs list are skipped', () {
      final m = StacUtdTabs.fromJson(const {
        'tabs': [
          {'data': {'text': 'A'}},
          'garbage',
          42,
        ],
      });
      expect(m.tabs, hasLength(1));
    });

    test('parser type', () {
      expect(const StacUtdTabsParser().type, 'utdTabs');
    });
  });

  group('StacUtdTab.fromJson', () {
    test('parses all optional sub-maps', () {
      final t = StacUtdTab.fromJson(const {
        'data': {'text': 'Home', 'icon': 'home'},
        'active': {'type': 'a'},
        'inactive': {'type': 'i'},
        'page': {'type': 'p'},
        'onTab': {'actionType': 'core.navigate'},
      });
      expect(t.data, {'text': 'Home', 'icon': 'home'});
      expect(t.active, {'type': 'a'});
      expect(t.inactive, {'type': 'i'});
      expect(t.page, {'type': 'p'});
      expect(t.onTab, {'actionType': 'core.navigate'});
    });

    test('all fields null when absent', () {
      final t = StacUtdTab.fromJson(const {});
      expect(t.data, isNull);
      expect(t.active, isNull);
      expect(t.inactive, isNull);
      expect(t.page, isNull);
      expect(t.onTab, isNull);
    });
  });

  group('StacUtdTextField.fromJson', () {
    test('parses id + flags + colors', () {
      final m = StacUtdTextField.fromJson(const {
        'id': 'email',
        'label': 'Email',
        'hint': 'you@x.com',
        'initialValue': 'a@b.com',
        'obscureText': true,
        'keyboardType': 'emailAddress',
        'fillColor': '#1affffff',
        'radius': 24,
        'textColor': '#ffffff',
        'prefixIcon': 'alternate_email',
      });
      expect(m.id, 'email');
      expect(m.label, 'Email');
      expect(m.hint, 'you@x.com');
      expect(m.initialValue, 'a@b.com');
      expect(m.obscureText, true);
      expect(m.keyboardType, 'emailAddress');
      expect(m.fillColor, '#1affffff');
      expect(m.radius, 24.0);
      expect(m.textColor, '#ffffff');
      expect(m.prefixIcon, 'alternate_email');
    });

    test('missing id defaults to "field"', () {
      expect(StacUtdTextField.fromJson(const {}).id, 'field');
    });

    test('non-string id is stringified', () {
      expect(StacUtdTextField.fromJson(const {'id': 7}).id, '7');
    });

    test('blank/whitespace string props become null (trim + empty guard)', () {
      final m = StacUtdTextField.fromJson(const {
        'id': 'x',
        'label': '   ',
        'hint': '',
        'textColor': '  ',
      });
      expect(m.label, isNull);
      expect(m.hint, isNull);
      expect(m.textColor, isNull);
    });

    test('string props are trimmed', () {
      final m = StacUtdTextField.fromJson(const {'id': 'x', 'label': '  Name  '});
      expect(m.label, 'Name');
    });

    test('obscureText is true only for an explicit true', () {
      expect(StacUtdTextField.fromJson(const {'id': 'x'}).obscureText, false);
      expect(
          StacUtdTextField.fromJson(const {'id': 'x', 'obscureText': 'true'})
              .obscureText,
          false);
      expect(
          StacUtdTextField.fromJson(const {'id': 'x', 'obscureText': true})
              .obscureText,
          true);
    });

    test('non-num radius is null', () {
      expect(StacUtdTextField.fromJson(const {'id': 'x', 'radius': 'big'}).radius,
          isNull);
    });

    test('parser type', () {
      expect(const StacUtdTextFieldParser().type, 'utdTextField');
    });
  });

  group('StacUtdList.fromJson', () {
    test('parses source, template, flags, padding, onItemTap', () {
      final m = StacUtdList.fromJson(const {
        'source': 'chat.conversations',
        'itemTemplate': {'type': 'text'},
        'shrinkWrap': true,
        'reverse': true,
        'padding': 12,
        'onItemTap': {'actionType': 'open'},
      });
      expect(m.source, 'chat.conversations');
      expect(m.itemTemplate, {'type': 'text'});
      expect(m.shrinkWrap, true);
      expect(m.reverse, true);
      expect(m.padding, 12.0);
      expect(m.onItemTap, {'actionType': 'open'});
    });

    test('defaults: not shrinkWrap, not reversed, null source/template', () {
      final m = StacUtdList.fromJson(const {});
      expect(m.source, isNull);
      expect(m.itemTemplate, isNull);
      expect(m.shrinkWrap, false);
      expect(m.reverse, false);
      expect(m.padding, isNull);
      expect(m.onItemTap, isNull);
    });

    test('parser type', () {
      expect(const StacUtdListParser().type, 'utdList');
    });
  });

  group('StacUtdScroll.fromJson', () {
    test('parses child + padding + flags', () {
      final m = StacUtdScroll.fromJson(const {
        'child': {'type': 'column'},
        'padding': 8,
        'shrinkWrap': true,
        'reverse': true,
      });
      expect(m.child, {'type': 'column'});
      expect(m.padding, 8.0);
      expect(m.shrinkWrap, true);
      expect(m.reverse, true);
    });

    test('defaults', () {
      final m = StacUtdScroll.fromJson(const {});
      expect(m.child, isNull);
      expect(m.padding, isNull);
      expect(m.shrinkWrap, false);
      expect(m.reverse, false);
    });

    test('parser type', () {
      expect(const StacUtdScrollParser().type, 'utdScroll');
    });
  });

  group('StacUtdObject.fromJson', () {
    test('parses source + child', () {
      final m = StacUtdObject.fromJson(const {
        'source': 'core.currentUser',
        'child': {'type': 'text'},
      });
      expect(m.source, 'core.currentUser');
      expect(m.child, {'type': 'text'});
    });

    test('defaults to null source/child', () {
      final m = StacUtdObject.fromJson(const {});
      expect(m.source, isNull);
      expect(m.child, isNull);
    });

    test('parser type', () {
      expect(const StacUtdObjectParser().type, 'utdObject');
    });
  });

  group('StacUtdLoading.fromJson', () {
    test('parses color/size/strokeWidth', () {
      final m = StacUtdLoading.fromJson(const {
        'color': '#ffffff',
        'size': 40,
        'strokeWidth': 5,
      });
      expect(m.color, isNotNull);
      expect(m.size, 40.0);
      expect(m.strokeWidth, 5.0);
    });

    test('defaults: null color, size 28, strokeWidth 3', () {
      final m = StacUtdLoading.fromJson(const {});
      expect(m.color, isNull);
      expect(m.size, 28.0);
      expect(m.strokeWidth, 3.0);
    });

    test('invalid hex color is null', () {
      expect(StacUtdLoading.fromJson(const {'color': 'nope'}).color, isNull);
      expect(StacUtdLoading.fromJson(const {'color': '   '}).color, isNull);
    });

    test('parser type', () {
      expect(const StacUtdLoadingParser().type, 'utdLoading');
    });
  });
}
