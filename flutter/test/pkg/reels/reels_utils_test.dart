import 'package:flutter_test/flutter_test.dart';
import 'package:reels/src/presentation/utils/number_format.dart';
import 'package:reels/src/presentation/utils/time.dart';
import 'package:reels/core/reels_strings.dart';

void main() {
  group('compactNumber', () {
    test('< 1000 => plain', () {
      expect(compactNumber(0), '0');
      expect(compactNumber(999), '999');
    });
    test('thousands => K', () {
      expect(compactNumber(1000), '1K');
      expect(compactNumber(22500), '22.5K');
    });
    test('millions => M', () {
      expect(compactNumber(1500000), '1.5M');
    });
  });

  group('timeAgo (English)', () {
    test('empty => empty, unparseable => raw', () {
      expect(timeAgo(''), '');
      expect(timeAgo('garbage'), 'garbage');
    });

    test('seconds => "just now"', () {
      final t = DateTime.now().toUtc().subtract(const Duration(seconds: 5));
      expect(timeAgo(t.toIso8601String()), 'just now');
    });

    test('singular vs plural units', () {
      final m1 = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      expect(timeAgo(m1.toIso8601String()), '1 minute ago');
      final m5 = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      expect(timeAgo(m5.toIso8601String()), '5 minutes ago');
    });

    test('hours / days / weeks / months / years', () {
      final h = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      expect(timeAgo(h.toIso8601String()), '2 hours ago');
      final d = DateTime.now().toUtc().subtract(const Duration(days: 3));
      expect(timeAgo(d.toIso8601String()), '3 days ago');
      final w = DateTime.now().toUtc().subtract(const Duration(days: 14));
      expect(timeAgo(w.toIso8601String()), '2 weeks ago');
      final mo = DateTime.now().toUtc().subtract(const Duration(days: 70));
      expect(timeAgo(mo.toIso8601String()), '2 months ago');
      final y = DateTime.now().toUtc().subtract(const Duration(days: 800));
      expect(timeAgo(y.toIso8601String()), '2 years ago');
    });
  });

  group('timeAgo (Arabic)', () {
    test('seconds => الآن', () {
      final t = DateTime.now().toUtc().subtract(const Duration(seconds: 5));
      expect(timeAgo(t.toIso8601String(), arabic: true), 'الآن');
    });

    test('singular minute', () {
      final t = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      expect(timeAgo(t.toIso8601String(), arabic: true), 'منذ دقيقة');
    });

    test('dual minutes (2)', () {
      final t = DateTime.now().toUtc().subtract(const Duration(minutes: 2));
      expect(timeAgo(t.toIso8601String(), arabic: true), 'منذ دقيقتين');
    });

    test('few (3-10) minutes uses plural with number', () {
      final t = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      expect(timeAgo(t.toIso8601String(), arabic: true), 'منذ 5 دقائق');
    });

    test('11+ minutes uses singular with number', () {
      final t = DateTime.now().toUtc().subtract(const Duration(minutes: 15));
      expect(timeAgo(t.toIso8601String(), arabic: true), 'منذ 15 دقيقة');
    });

    test('hours dual', () {
      final t = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      expect(timeAgo(t.toIso8601String(), arabic: true), 'منذ ساعتين');
    });
  });

  group('ReelsStrings.reactionLabelKey', () {
    test('known mappings', () {
      expect(ReelsStrings.reactionLabelKey('love'), ReelsStrings.reactLove);
      expect(ReelsStrings.reactionLabelKey('haha'), ReelsStrings.reactHaha);
      expect(ReelsStrings.reactionLabelKey('wow'), ReelsStrings.reactWow);
      expect(ReelsStrings.reactionLabelKey('sad'), ReelsStrings.reactSad);
      expect(ReelsStrings.reactionLabelKey('angry'), ReelsStrings.reactAngry);
    });
    test('null/like/unknown => like key', () {
      expect(ReelsStrings.reactionLabelKey(null), ReelsStrings.like);
      expect(ReelsStrings.reactionLabelKey('like'), ReelsStrings.like);
      expect(ReelsStrings.reactionLabelKey('???'), ReelsStrings.like);
    });
  });

  group('ReelsStrings.reportTypeKey', () {
    test('known mappings + default', () {
      expect(ReelsStrings.reportTypeKey('spam'), ReelsStrings.reportSpam);
      expect(ReelsStrings.reportTypeKey('abuse'), ReelsStrings.reportAbuse);
      expect(ReelsStrings.reportTypeKey('nudity'), ReelsStrings.reportNudity);
      expect(
        ReelsStrings.reportTypeKey('violence'),
        ReelsStrings.reportViolence,
      );
      expect(ReelsStrings.reportTypeKey('mystery'), ReelsStrings.reportOther);
    });
  });

  group('ReelsStrings.translations bundle', () {
    test('en + ar with matching keys', () {
      final t = ReelsStrings.translations();
      expect(t.keys, containsAll(['en', 'ar']));
      expect(t['en']!.keys.toSet(), t['ar']!.keys.toSet());
    });
  });
}
