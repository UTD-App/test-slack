import 'package:flutter/foundation.dart';
import 'package:utd_app/shared/models/country_model.dart';
import 'package:utd_app/shared/models/my_data_model.dart';
import 'package:utd_app/shared/models/profile_room_model.dart';

class UserDataNotifier extends ChangeNotifier {
  MyDataModel _user = const MyDataModel();

  MyDataModel get user => _user;

  bool get isAuthenticated => (_user.authToken ?? '').isNotEmpty;

  void setUser(MyDataModel user) {
    _user = user;
    notifyListeners();
  }

  void update({
    int? id,
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? uuid,
    String? bio,
    String? notificationId,
    bool? isFirst,
    String? onlineTime,
    CountryModel? country,
    ProfileRoomModel? profile,
    String? authToken,
  }) {
    _user = _user.copyWith(
      id: id,
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      uuid: uuid,
      bio: bio,
      notificationId: notificationId,
      isFirst: isFirst,
      onlineTime: onlineTime,
      country: country,
      profile: profile,
      authToken: authToken,
    );
    notifyListeners();
  }

  void clear() {
    _user = const MyDataModel();
    notifyListeners();
  }
}
