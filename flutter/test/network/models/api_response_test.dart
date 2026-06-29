import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/network/models/api_response.dart';

/// Pure-Dart unit tests for the network response wrappers + Result type.
void main() {
  group('ApiResponse', () {
    test('success / error factories', () {
      final ok = ApiResponse<int>.success(data: 7, message: 'done');
      expect(ok.success, isTrue);
      expect(ok.isError, isFalse);
      expect(ok.hasData, isTrue);
      expect(ok.data, 7);

      final err = ApiResponse<int>.error(message: 'boom', statusCode: 500);
      expect(err.success, isFalse);
      expect(err.isError, isTrue);
      expect(err.hasData, isFalse);
      expect(err.statusCode, 500);
    });

    test('fromJson reads success/message/status_code and parses data', () {
      final r = ApiResponse<String>.fromJson(
        {'success': true, 'message': 'hi', 'status_code': 200, 'data': 'payload'},
        fromJsonT: (d) => d as String,
      );
      expect(r.success, isTrue);
      expect(r.message, 'hi');
      expect(r.statusCode, 200);
      expect(r.data, 'payload');
    });

    test('fromJson defaults success to true when the key is missing', () {
      final r = ApiResponse<dynamic>.fromJson({'message': 'no success key'});
      expect(r.success, isTrue);
      expect(r.hasData, isFalse);
    });

    test('fromJson surfaces an error envelope', () {
      final r = ApiResponse<dynamic>.fromJson({'success': false, 'message': 'nope'});
      expect(r.isError, isTrue);
      expect(r.message, 'nope');
    });
  });

  group('PaginatedResponse', () {
    Map<String, dynamic> page(int current, int last) => {
          'data': [
            {'id': 1},
            {'id': 2},
          ],
          'current_page': current,
          'last_page': last,
          'per_page': 2,
          'total': 4,
        };

    test('parses items and computes paging flags', () {
      final p = PaginatedResponse<Map<String, dynamic>>.fromJson(
        page(1, 2),
        (m) => m,
      );
      expect(p.items.length, 2);
      expect(p.currentPage, 1);
      expect(p.lastPage, 2);
      expect(p.hasMorePages, isTrue);
      expect(p.isFirstPage, isTrue);
      expect(p.isLastPage, isFalse);
      expect(p.nextPage, 2);
      expect(p.previousPage, isNull);
    });

    test('last page reports no more pages', () {
      final p = PaginatedResponse<Map<String, dynamic>>.fromJson(page(2, 2), (m) => m);
      expect(p.hasMorePages, isFalse);
      expect(p.isLastPage, isTrue);
      expect(p.nextPage, isNull);
      expect(p.previousPage, 1);
    });

    test('missing data list yields empty items', () {
      final p = PaginatedResponse<Map<String, dynamic>>.fromJson({}, (m) => m);
      expect(p.items, isEmpty);
      expect(p.currentPage, 1);
    });
  });

  group('Result', () {
    test('success path', () {
      final Result<int> r = Result.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.dataOrNull, 42);
      expect(r.dataOrThrow, 42);
      expect(r.map((v) => v + 1).dataOrNull, 43);
      expect(r.when(success: (d) => 'ok:$d', failure: (m, _) => 'err:$m'), 'ok:42');
      expect(r.fold((m) => -1, (d) => d), 42);
    });

    test('failure path', () {
      final Result<int> r = Result.failure('bad', statusCode: 404);
      expect(r.isFailure, isTrue);
      expect(r.dataOrNull, isNull);
      expect(() => r.dataOrThrow, throwsA(isA<Exception>()));
      expect(r.when(success: (d) => 'ok', failure: (m, c) => 'err:$m:$c'), 'err:bad:404');
      // map on a failure preserves the failure (and its message).
      expect(r.map((v) => v + 1).isFailure, isTrue);
    });
  });
}
