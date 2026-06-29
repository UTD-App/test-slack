import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/addons/user_data_extension.dart';

/// Pure-Dart tests for the UserDataExtension contract.
///
/// UserDataExtension is abstract, so we define a minimal concrete subclass and
/// verify the ChangeNotifier wiring + the contract methods (key, onDataReceived,
/// serializeData, onDataCleared) behave as the docs describe.
class _FakeSocialExtension extends UserDataExtension {
  int fans = 0;
  int followings = 0;

  @override
  String get key => 'social';

  @override
  void onDataReceived(Map<String, dynamic>? data) {
    fans = (data?['fans'] as num?)?.toInt() ?? 0;
    followings = (data?['followings'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  @override
  Map<String, dynamic>? serializeData() => {
        'fans': fans,
        'followings': followings,
      };

  @override
  void onDataCleared() {
    fans = 0;
    followings = 0;
    notifyListeners();
  }
}

void main() {
  group('UserDataExtension contract (via fake subclass)', () {
    late _FakeSocialExtension ext;
    late int notifyCount;

    setUp(() {
      ext = _FakeSocialExtension();
      notifyCount = 0;
      ext.addListener(() => notifyCount++);
    });

    tearDown(() => ext.dispose());

    test('key returns the namespaced section', () {
      expect(ext.key, 'social');
    });

    test('onDataReceived populates fields and notifies', () {
      ext.onDataReceived({'fans': 12, 'followings': 3});
      expect(ext.fans, 12);
      expect(ext.followings, 3);
      expect(notifyCount, 1);
    });

    test('onDataReceived with null data resets to defaults', () {
      ext.onDataReceived({'fans': 5, 'followings': 5});
      ext.onDataReceived(null);
      expect(ext.fans, 0);
      expect(ext.followings, 0);
    });

    test('onDataReceived tolerates missing keys', () {
      ext.onDataReceived({'fans': 9}); // no followings
      expect(ext.fans, 9);
      expect(ext.followings, 0);
    });

    test('serializeData round-trips current state', () {
      ext.onDataReceived({'fans': 7, 'followings': 1});
      expect(ext.serializeData(), {'fans': 7, 'followings': 1});
    });

    test('onDataCleared resets fields and notifies', () {
      ext.onDataReceived({'fans': 4, 'followings': 4});
      notifyCount = 0;
      ext.onDataCleared();
      expect(ext.fans, 0);
      expect(ext.followings, 0);
      expect(notifyCount, 1);
    });

    test('is a ChangeNotifier', () {
      expect(ext, isA<UserDataExtension>());
    });
  });
}
