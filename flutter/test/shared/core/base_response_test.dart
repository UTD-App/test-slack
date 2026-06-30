import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/base_response.dart';

/// Pure-Dart tests for the envelope parser the app actually uses (BaseResponse).
///
/// Cross-stack contract: the BACKEND envelope key is `status` (see backend
/// Common::apiResponse). BaseResponse.fromJson PREFERS `status` and falls back
/// to the legacy `success` key, so a real backend payload now parses correctly —
/// see the last test.
void main() {
  group('BaseResponse.fromJson', () {
    test('parses success + message + scalar data passthrough', () {
      final r = BaseResponse<String>.fromJson(
        {'success': true, 'message': 'ok', 'data': 'hello'},
      );
      expect(r.success, isTrue);
      expect(r.message, 'ok');
      expect(r.data, 'hello'); // String is passed through without fromJsonT
    });

    test('parses object data via fromJsonT', () {
      final r = BaseResponse<int>.fromJson(
        {'success': true, 'message': '', 'data': {'n': 5}},
        fromJsonT: (d) => (d as Map<String, dynamic>)['n'] as int,
      );
      expect(r.data, 5);
    });

    test('null data yields null', () {
      final r = BaseResponse<Object>.fromJson({'success': false, 'message': 'x', 'data': null});
      expect(r.success, isFalse);
      expect(r.data, isNull);
    });

    test('reads pagination from paginates.meta', () {
      final r = BaseResponse<Object>.fromJson({
        'success': true,
        'message': '',
        'data': null,
        'paginates': {'meta': {'current_page': 2, 'last_page': 5}},
      });
      expect(r.paginates?.currentPage, 2);
      expect(r.paginates?.lastPage, 5);
    });

    test('BACKEND envelope uses `status`, which BaseResponse now reads', () {
      // This is exactly what the backend returns: {status, message, data}.
      final r = BaseResponse<Object>.fromJson({'status': true, 'message': '', 'data': null});
      expect(r.success, isTrue, reason: 'BaseResponse prefers `status` (the backend key)');
      expect(r.message, '');
    });

    test('status as 1/0 (int) is coerced, not treated as a parse failure', () {
      final ok = BaseResponse<Object>.fromJson({'status': 1, 'message': 'ok', 'data': null});
      expect(ok.success, isTrue);

      final bad = BaseResponse<Object>.fromJson({'status': 0, 'message': 'no', 'data': null});
      expect(bad.success, isFalse);
    });

    test('missing message does NOT throw (defaults to empty string)', () {
      // Previously `json['message'] as String` threw on a 200 with no message,
      // turning an otherwise-good response into a failure.
      final r = BaseResponse<Object>.fromJson({'status': true, 'data': null});
      expect(r.message, '');
      expect(r.success, isTrue);
    });

    test('non-string message is coerced via toString', () {
      final r = BaseResponse<Object>.fromJson({'status': true, 'message': 123, 'data': null});
      expect(r.message, '123');
    });
  });
}
