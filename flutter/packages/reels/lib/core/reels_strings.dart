/// Translation keys + bundled values for the Reels feature.
///
/// Usage in widgets: `context.tr(ReelsStrings.post)`.
/// The [translations] map is merged into the app's translation table by
/// `ReelsFeature.getTranslations()` — admin/server overrides win automatically.
class ReelsStrings {
  ReelsStrings._();

  // ── Keys (use these with context.tr) ───────────────────
  static const title = 'reels.title';
  static const following = 'reels.following';
  static const forYou = 'reels.for_you';
  static const newReel = 'reels.new';
  static const post = 'reels.post';
  static const empty = 'reels.empty';
  static const comments = 'reels.comments';
  static const likes = 'reels.likes';
  static const views = 'reels.views';
  static const report = 'reels.report';
  static const delete = 'reels.delete';
  static const cancel = 'reels.cancel';
  static const retry = 'reels.retry';
  static const submit = 'reels.submit';
  static const somethingWrong = 'reels.something_wrong';
  static const reportedThanks = 'reels.reported_thanks';
  static const deleteConfirm = 'reels.delete_confirm';
  static const deleteCommentConfirm = 'reels.delete_comment_confirm';
  static const deleted = 'reels.deleted';
  static const reply = 'reels.reply';
  static const replyingTo = 'reels.replying_to';
  static const pickVideo = 'reels.pick_video';
  static const noVideoSelected = 'reels.no_video_selected';
  static const describeReel = 'reels.describe_reel';
  static const whoLiked = 'reels.who_liked';
  static const noComments = 'reels.no_comments';
  static const writeComment = 'reels.write_comment';
  static const noLikes = 'reels.no_likes';
  static const user = 'reels.user';
  static const myReels = 'reels.my_reels';
  static const editCaption = 'reels.edit_caption';
  static const edit = 'reels.edit';
  static const save = 'reels.save';
  static const gift = 'reels.gift';
  static const reportTitle = 'reels.report_title';
  static const reason = 'reels.reason';
  static const description = 'reels.description';

  // reaction labels (the action-button word; emoji comes from reactions.dart)
  static const like = 'reels.like';
  static const reactLove = 'reels.react.love';
  static const reactHaha = 'reels.react.haha';
  static const reactWow = 'reels.react.wow';
  static const reactSad = 'reels.react.sad';
  static const reactAngry = 'reels.react.angry';

  /// Maps a reaction type to its localized label key ('like' is the default).
  static String reactionLabelKey(String? type) {
    switch (type) {
      case 'love':
        return reactLove;
      case 'haha':
        return reactHaha;
      case 'wow':
        return reactWow;
      case 'sad':
        return reactSad;
      case 'angry':
        return reactAngry;
      default:
        return like;
    }
  }

  // report reason types (value sent to API stays the english slug)
  static const reportSpam = 'reels.report.spam';
  static const reportAbuse = 'reels.report.abuse';
  static const reportNudity = 'reels.report.nudity';
  static const reportViolence = 'reels.report.violence';
  static const reportOther = 'reels.report.other';

  /// Maps a report-type slug to its translation key.
  static String reportTypeKey(String type) {
    switch (type) {
      case 'spam':
        return reportSpam;
      case 'abuse':
        return reportAbuse;
      case 'nudity':
        return reportNudity;
      case 'violence':
        return reportViolence;
      default:
        return reportOther;
    }
  }

  // ── Bundled values ─────────────────────────────────────
  static Map<String, Map<String, String>> translations() => {
        'en': {
          title: 'Reels',
          following: 'Following',
          forYou: 'For You',
          newReel: 'New reel',
          post: 'Post',
          empty: 'No reels yet',
          comments: 'Comments',
          likes: 'Likes',
          views: 'views',
          report: 'Report',
          delete: 'Delete',
          cancel: 'Cancel',
          retry: 'Retry',
          submit: 'Submit',
          somethingWrong: 'Something went wrong',
          reportedThanks: 'Reported. Thank you.',
          deleteConfirm: 'Delete reel?',
          deleteCommentConfirm: 'Delete comment?',
          deleted: 'Deleted',
          reply: 'Reply',
          replyingTo: 'Replying to',
          like: 'Like',
          reactLove: 'Love',
          reactHaha: 'Haha',
          reactWow: 'Wow',
          reactSad: 'Sad',
          reactAngry: 'Angry',
          pickVideo: 'Pick a video',
          noVideoSelected: 'Please pick a video first',
          describeReel: 'Say something about your reel…',
          whoLiked: 'Who liked',
          noComments: 'No comments yet',
          writeComment: 'Write a comment…',
          noLikes: 'No likes yet',
          user: 'User',
          myReels: 'Reels',
          editCaption: 'Edit caption',
          edit: 'Edit',
          save: 'Save',
          gift: 'Gift',
          reportTitle: 'Report reel',
          reason: 'Reason',
          description: 'Description',
          reportSpam: 'Spam',
          reportAbuse: 'Abuse',
          reportNudity: 'Nudity',
          reportViolence: 'Violence',
          reportOther: 'Other',
        },
        'ar': {
          title: 'الريلز',
          following: 'المتابعون',
          forYou: 'لك',
          newReel: 'ريل جديد',
          post: 'نشر',
          empty: 'لا توجد ريلز بعد',
          comments: 'التعليقات',
          likes: 'الإعجابات',
          views: 'مشاهدة',
          report: 'إبلاغ',
          delete: 'حذف',
          cancel: 'إلغاء',
          retry: 'إعادة المحاولة',
          submit: 'إرسال',
          somethingWrong: 'حدث خطأ ما',
          reportedThanks: 'تم الإبلاغ. شكراً لك.',
          deleteConfirm: 'حذف الريل؟',
          deleteCommentConfirm: 'حذف التعليق؟',
          deleted: 'تم الحذف',
          reply: 'رد',
          replyingTo: 'الرد على',
          like: 'إعجاب',
          reactLove: 'أحبّه',
          reactHaha: 'هههه',
          reactWow: 'واو',
          reactSad: 'حزين',
          reactAngry: 'غاضب',
          pickVideo: 'اختر فيديو',
          noVideoSelected: 'برجاء اختيار فيديو أولاً',
          describeReel: 'اكتب شيئاً عن الريل…',
          whoLiked: 'مَن أعجبه',
          noComments: 'لا توجد تعليقات بعد',
          writeComment: 'اكتب تعليقاً…',
          noLikes: 'لا توجد إعجابات بعد',
          user: 'مستخدم',
          myReels: 'الريلز',
          editCaption: 'تعديل الوصف',
          edit: 'تعديل',
          save: 'حفظ',
          gift: 'هدية',
          reportTitle: 'الإبلاغ عن الريل',
          reason: 'السبب',
          description: 'الوصف',
          reportSpam: 'محتوى مزعج',
          reportAbuse: 'إساءة',
          reportNudity: 'محتوى إباحي',
          reportViolence: 'عنف',
          reportOther: 'أخرى',
        },
      };
}
