import 'package:flutter/widgets.dart';

class EmojiStrings {
  final String _locale;

  EmojiStrings._(this._locale);

  factory EmojiStrings.of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return EmojiStrings._(locale);
  }

  bool get _isAr => _locale == 'ar';

  String get selectCategory =>
      _isAr ? 'اختر تصنيف' : 'Select a category';
  String get noEmojis =>
      _isAr ? 'لا توجد ايموجيز' : 'No emojis available';
  String get errorLoading =>
      _isAr ? 'خطأ في تحميل الايموجيز' : 'Error loading emojis';
}
