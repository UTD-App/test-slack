import 'package:flutter_test/flutter_test.dart';
import 'package:moment/src/presentation/utils/number_format.dart';
import 'package:moment/src/presentation/utils/time.dart';
import 'package:moment/src/presentation/utils/reactions.dart';
import 'package:moment/core/moment_strings.dart';

void main() {
  group('compactNumber', () {
    test('values below 1000 render as plain integers', () {
      expect(compactNumber(0), '0');
      expect(compactNumber(7), '7');
      expect(compactNumber(500), '500');
      expect(compactNumber(999), '999');
    });

    test('thousands use K with trailing .0 trimmed', () {
      expect(compactNumber(1000), '1K');
      expect(compactNumber(3000), '3K');
      expect(compactNumber(22500), '22.5K');
      expect(compactNumber(999999), '1000K');
    });

    test('millions use M', () {
      expect(compactNumber(1000000), '1M');
      expect(compactNumber(1500000), '1.5M');
    });

    test('truncates fractional input under 1000 via toInt', () {
      expect(compactNumber(12.9), '12');
    });
  });

  group('timeAgo', () {
    test('empty string returns empty', () {
      expect(timeAgo(''), '');
    });

    test('unparseable string falls back to the raw input', () {
      expect(timeAgo('not-a-date'), 'not-a-date');
    });

    test('future / clock-skew timestamps clamp to "now"', () {
      final future = DateTime.now().add(const Duration(hours: 5)).toUtc();
      expect(timeAgo(future.toIso8601String()), 'now');
    });

    test('seconds-old => "now"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(seconds: 10));
      expect(timeAgo(t.toIso8601String()), 'now');
    });

    test('minutes => "Nm"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      expect(timeAgo(t.toIso8601String()), '5m');
    });

    test('hours => "Nh"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(hours: 3));
      expect(timeAgo(t.toIso8601String()), '3h');
    });

    test('days => "Nd"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(days: 2));
      expect(timeAgo(t.toIso8601String()), '2d');
    });

    test('weeks => "Nw"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(days: 10));
      expect(timeAgo(t.toIso8601String()), '1w');
    });

    test('months => "Nmo"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(days: 70));
      expect(timeAgo(t.toIso8601String()), '2mo');
    });

    test('years => "Ny"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(days: 800));
      expect(timeAgo(t.toIso8601String()), '2y');
    });
  });

  group('momentReactions / reactionByType', () {
    test('exposes the 6 reactions in order, "like" first', () {
      expect(momentReactions, hasLength(6));
      expect(momentReactions.first.type, 'like');
      expect(
        momentReactions.map((r) => r.type).toList(),
        ['like', 'love', 'haha', 'wow', 'sad', 'angry'],
      );
    });

    test('reactionByType resolves a known type', () {
      final r = reactionByType('love');
      expect(r, isNotNull);
      expect(r!.type, 'love');
      expect(r.emoji, '❤️');
    });

    test('reactionByType returns null for null/empty/unknown', () {
      expect(reactionByType(null), isNull);
      expect(reactionByType(''), isNull);
      expect(reactionByType('nope'), isNull);
    });
  });

  group('MomentStrings.reactionLabelKey', () {
    test('maps each known reaction', () {
      expect(MomentStrings.reactionLabelKey('love'), MomentStrings.reactLove);
      expect(MomentStrings.reactionLabelKey('haha'), MomentStrings.reactHaha);
      expect(MomentStrings.reactionLabelKey('wow'), MomentStrings.reactWow);
      expect(MomentStrings.reactionLabelKey('sad'), MomentStrings.reactSad);
      expect(MomentStrings.reactionLabelKey('angry'), MomentStrings.reactAngry);
    });

    test('null / "like" / unknown all default to like key', () {
      expect(MomentStrings.reactionLabelKey(null), MomentStrings.like);
      expect(MomentStrings.reactionLabelKey('like'), MomentStrings.like);
      expect(MomentStrings.reactionLabelKey('xyz'), MomentStrings.like);
    });
  });

  group('MomentStrings.reportTypeKey', () {
    test('maps each known report slug', () {
      expect(MomentStrings.reportTypeKey('spam'), MomentStrings.reportSpam);
      expect(MomentStrings.reportTypeKey('abuse'), MomentStrings.reportAbuse);
      expect(MomentStrings.reportTypeKey('nudity'), MomentStrings.reportNudity);
      expect(
        MomentStrings.reportTypeKey('violence'),
        MomentStrings.reportViolence,
      );
    });

    test('unknown slug defaults to "other"', () {
      expect(MomentStrings.reportTypeKey('weird'), MomentStrings.reportOther);
      expect(MomentStrings.reportTypeKey('other'), MomentStrings.reportOther);
    });
  });

  group('MomentStrings.translations bundle', () {
    test('ships en + ar with matching key sets', () {
      final t = MomentStrings.translations();
      expect(t.keys, containsAll(['en', 'ar']));
      expect(t['en']!.keys.toSet(), t['ar']!.keys.toSet());
    });
  });
}
