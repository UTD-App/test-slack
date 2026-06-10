import 'package:flutter/widgets.dart';

class RoomStrings {
  final String _locale;

  RoomStrings._(this._locale);

  factory RoomStrings.of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return RoomStrings._(locale);
  }

  bool get _isAr => _locale == 'ar';

  // ── Seat Options ──
  String get seatReservedForOwner =>
      _isAr ? 'هذا المقعد محجوز لصاحب الغرفة' : 'This seat is reserved for the owner';
  String get seatLocked => _isAr ? 'هذا المقعد مغلق' : 'This seat is locked';
  String seat(int index) => _isAr ? 'مقعد ${index + 1}' : 'Seat ${index + 1}';
  String get unlockSeat => _isAr ? 'فتح المقعد' : 'Unlock Seat';
  String get lockSeat => _isAr ? 'قفل المقعد' : 'Lock Seat';
  String get inviteToMic => _isAr ? 'دعوة للمايك' : 'Invite to Mic';
  String get switchSeat => _isAr ? 'انتقل لهذا المقعد' : 'Switch to This Seat';
  String get takeSeat => _isAr ? 'اجلس على المقعد' : 'Take Seat';
  String get leaveSeat => _isAr ? 'مغادرة المقعد' : 'Leave Seat';
  String get myProfile => _isAr ? 'ملفي الشخصي' : 'My Profile';
  String get cancel => _isAr ? 'إلغاء' : 'Cancel';
  String get couldNotTakeSeat =>
      _isAr ? 'لا يمكن الجلوس على هذا المقعد' : 'Could not take this seat';

  // ── User Profile ──
  String get user => _isAr ? 'مستخدم' : 'User';
  String get host => _isAr ? 'مالك' : 'Host';
  String get admin => _isAr ? 'مشرف' : 'Admin';
  String get unmute => _isAr ? 'تشغيل المايك' : 'Unmute';
  String get mute => _isAr ? 'كتم المايك' : 'Mute';
  String get userUnmuted => _isAr ? 'تم تشغيل المايك' : 'User Unmuted';
  String get userMuted => _isAr ? 'تم كتم المايك' : 'User Muted';
  String get failed => _isAr ? 'فشل' : 'Failed';
  String get kickFromSeat => _isAr ? 'طرد من المقعد' : 'Kick from Seat';
  String get ban => _isAr ? 'حظر' : 'Ban';
  String get removeAdmin => _isAr ? 'إزالة المشرف' : 'Remove Admin';
  String get makeAdmin => _isAr ? 'تعيين مشرف' : 'Make Admin';
  String get userBanned => _isAr ? 'تم حظر المستخدم' : 'User Banned';
  String get banFailed => _isAr ? 'فشل الحظر' : 'Ban failed';
  String get adminRemoved => _isAr ? 'تم إزالة المشرف' : 'Admin Removed';
  String get adminAdded => _isAr ? 'تم تعيين مشرف' : 'Admin Added';
  String get roleChangeFailed =>
      _isAr ? 'فشل تغيير الصلاحية' : 'Failed to change role';

  // ── Ban Dialog ──
  String get banUser => _isAr ? 'حظر المستخدم' : 'Ban User';
  String get fiveMinutes => _isAr ? '5 دقائق' : '5 Minutes';
  String get fifteenMinutes => _isAr ? '15 دقيقة' : '15 Minutes';
  String get thirtyMinutes => _isAr ? '30 دقيقة' : '30 Minutes';
  String get oneHour => _isAr ? 'ساعة' : '1 Hour';
  String get twentyFourHours => _isAr ? '24 ساعة' : '24 Hours';
  String get permanent => _isAr ? 'دائم' : 'Permanent';

  // ── Invite to Mic ──
  String inviteToSeat(int index) =>
      _isAr ? 'دعوة للمقعد ${index + 1}' : 'Invite to Seat ${index + 1}';
  String get noAudienceMembers =>
      _isAr ? 'لا يوجد مستمعين متاحين' : 'No audience members available';
  String invitationSentTo(String name) =>
      _isAr ? 'تم إرسال الدعوة لـ $name' : 'Invitation sent to $name';
  String get invitationFailed =>
      _isAr ? 'فشل إرسال الدعوة' : 'Failed to send invitation';
  String get sent => _isAr ? 'أُرسلت' : 'Sent';
  String get invite => _isAr ? 'دعوة' : 'Invite';

  // ── Speaker Invitation ──
  String invitationToMic(int index) =>
      _isAr ? 'دعوة للمايك #${index + 1}' : 'Invitation to Mic #${index + 1}';
  String get decline => _isAr ? 'رفض' : 'Decline';
  String get accept => _isAr ? 'قبول' : 'Accept';

  // ── Room Header ──
  String get leaveRoom => _isAr ? 'مغادرة الغرفة' : 'Leave Room';
  String get leaveRoomConfirm =>
      _isAr ? 'هل أنت متأكد من مغادرة الغرفة؟' : 'Are you sure you want to leave this room?';
  String get leave => _isAr ? 'مغادرة' : 'Leave';
  String get admins => _isAr ? 'المشرفين' : 'Admins';
  String get blacklist => _isAr ? 'القائمة السوداء' : 'Blacklist';
  String get settings => _isAr ? 'الإعدادات' : 'Settings';

  // ── Management Sheets (Visitors / Admins / Blacklist) ──
  String get visitors => _isAr ? 'الزوار' : 'Visitors';
  String get noVisitors => _isAr ? 'لا يوجد زوار' : 'No visitors';
  String get kick => _isAr ? 'طرد' : 'Kick';
  String get noAdmins => _isAr ? 'لا يوجد مشرفين' : 'No admins';
  String get noBlacklist => _isAr ? 'لا يوجد محظورين' : 'No blocked users';
  String get permanentBan => _isAr ? 'حظر دائم' : 'Permanent ban';
  String expiresAt(String date) => _isAr ? 'ينتهي في: $date' : 'Expires: $date';
  String get unknown => _isAr ? 'غير معروف' : 'Unknown';

  // ── Messages ──
  String get sendMessageHint => _isAr ? 'أرسل رسالة...' : 'Send a message...';

  // ── Participant Events ──
  String userJoined(String name) =>
      _isAr ? '$name دخل الغرفة' : '$name joined the room';
  String userLeft(String name) =>
      _isAr ? '$name غادر الغرفة' : '$name left the room';

  // ── Room Page ──
  String get bannedFromRoom =>
      _isAr ? 'تم حظرك من هذه الغرفة' : 'You have been banned from this room';
  String get error => _isAr ? 'حدث خطأ' : 'Something went wrong';
  String get back => _isAr ? 'رجوع' : 'Back';
  String get streamConfigMissing =>
      _isAr ? 'إعدادات البث غير متوفرة' : 'Stream config is missing';
}
