import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/base_response.dart';

/// Pure-Dart tests for the envelope parser the app actually uses (BaseResponse).
///
/// Also documents a cross-stack observation: the BACKEND envelope key is
/// `status` (see backend Common::apiResponse), but BaseResponse.fromJson reads
/// `success`. So `success` parses as null for a real backend payload — see the
/// last test. (Harmless only if call sites rely on the HTTP status, not on
/// `success`; worth verifying.)
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

    test('BACKEND envelope uses `status`, so `success` parses as null (mismatch)', () {
      // This is exactly what the backend returns: {status, message, data}.
      final r = BaseResponse<Object>.fromJson({'status': true, 'message': '', 'data': null});
      expect(r.success, isNull, reason: 'BaseResponse reads `success`, backend sends `status`');
      expect(r.message, '');
    });
  });
}
