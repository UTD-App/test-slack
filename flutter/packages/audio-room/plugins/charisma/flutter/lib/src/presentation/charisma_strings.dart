import 'package:flutter/widgets.dart';

class CharismaStrings {
  final String _locale;

  CharismaStrings._(this._locale);

  factory CharismaStrings.of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return CharismaStrings._(locale);
  }

  bool get _isAr => _locale == 'ar';

  String get charisma => _isAr ? 'الكاريزما' : 'Charisma';
  String get resetCharisma => _isAr ? 'ريست الكاريزما' : 'Reset Charisma';
  String get charismaRanking =>
      _isAr ? 'ترتيب الكاريزما' : 'Charisma Ranking';
  String get noData => _isAr ? 'لا توجد بيانات' : 'No data';
  String user(int id) => _isAr ? 'مستخدم $id' : 'User $id';
}
