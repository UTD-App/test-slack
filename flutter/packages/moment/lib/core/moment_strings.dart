/// Translation keys + bundled values for the Moment feature.
///
/// Usage in widgets: `context.tr(MomentStrings.post)`.
/// The [translations] map is merged into the app's translation table by
/// `MomentFeature.getTranslations()` — admin/server overrides win automatically.
class MomentStrings {
  MomentStrings._();

  // ── Keys (use these with context.tr) ───────────────────
  static const title = 'moment.title';
  static const posts = 'moment.posts';
  static const newMoment = 'moment.new';
  static const post = 'moment.post';
  static const empty = 'moment.empty';
  static const comments = 'moment.comments';
  static const likes = 'moment.likes';
  static const report = 'moment.report';
  static const delete = 'moment.delete';
  static const cancel = 'moment.cancel';
  static const retry = 'moment.retry';
  static const submit = 'moment.submit';
  static const somethingWrong = 'moment.something_wrong';
  static const reportedThanks = 'moment.reported_thanks';
  static const deleteConfirm = 'moment.delete_confirm';
  static const deleteCommentConfirm = 'moment.delete_comment_confirm';
  static const deleted = 'moment.deleted';
  static const writeOrPhoto = 'moment.write_or_photo';
  static const whatsOnMind = 'moment.whats_on_mind';
  static const addPhotos = 'moment.add_photos';
  static const whoLiked = 'moment.who_liked';
  static const noComments = 'moment.no_comments';
  static const writeComment = 'moment.write_comment';
  static const reply = 'moment.reply';
  static const replyingTo = 'moment.replying_to';
  static const noLikes = 'moment.no_likes';
  static const user = 'moment.user';

  // reaction labels (the action-button word; emoji comes from reactions.dart)
  static const like = 'moment.like';
  static const reactLove = 'moment.react.love';
  static const reactHaha = 'moment.react.haha';
  static const reactWow = 'moment.react.wow';
  static const reactSad = 'moment.react.sad';
  static const reactAngry = 'moment.react.angry';

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

  // create-post screen
  static const createPost = 'moment.create_post';
  static const whatToTalkAbout = 'moment.what_to_talk_about';
  static const addToYourPost = 'moment.add_to_your_post';
  static const photoVideo = 'moment.photo_video';
  static const gif = 'moment.gif';
  static const poll = 'moment.poll';
  static const adoption = 'moment.adoption';
  static const lostNotice = 'moment.lost_notice';
  static const event = 'moment.event';
  static const comingSoon = 'moment.coming_soon';
  static const reportTitle = 'moment.report_title';
  static const reason = 'moment.reason';
  static const description = 'moment.description';

  // report reason types (value sent to API stays the english slug)
  static const reportSpam = 'moment.report.spam';
  static const reportAbuse = 'moment.report.abuse';
  static const reportNudity = 'moment.report.nudity';
  static const reportViolence = 'moment.report.violence';
  static const reportOther = 'moment.report.other';

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
          title: 'Moments',
          posts: 'Posts',
          newMoment: 'New moment',
          post: 'Post',
          empty: 'No moments yet',
          comments: 'Comments',
          likes: 'Likes',
          report: 'Report',
          delete: 'Delete',
          cancel: 'Cancel',
          retry: 'Retry',
          submit: 'Submit',
          somethingWrong: 'Something went wrong',
          reportedThanks: 'Reported. Thank you.',
          deleteConfirm: 'Delete moment?',
          deleteCommentConfirm: 'Delete comment?',
          deleted: 'Moment deleted',
          writeOrPhoto: 'Write something or add a photo',
          whatsOnMind: "What's on your mind?",
          addPhotos: 'Add photos',
          whoLiked: 'Who liked',
          noComments: 'No comments yet',
          writeComment: 'Write a comment…',
          reply: 'Reply',
          replyingTo: 'Replying to',
          noLikes: 'No likes yet',
          user: 'User',
          like: 'Like',
          reactLove: 'Love',
          reactHaha: 'Haha',
          reactWow: 'Wow',
          reactSad: 'Sad',
          reactAngry: 'Angry',
          createPost: 'Create Post',
          whatToTalkAbout: 'What do you want to talk about?',
          addToYourPost: 'Add to your post',
          photoVideo: 'Photo/Video',
          gif: 'Gif',
          poll: 'Poll',
          adoption: 'Adoption',
          lostNotice: 'Lost Notice',
          event: 'Event',
          comingSoon: 'Coming soon',
          reportTitle: 'Report moment',
          reason: 'Reason',
          description: 'Description',
          reportSpam: 'Spam',
          reportAbuse: 'Abuse',
          reportNudity: 'Nudity',
          reportViolence: 'Violence',
          reportOther: 'Other',
        },
        'ar': {
          title: 'اللحظات',
          posts: 'المنشورات',
          newMoment: 'لحظة جديدة',
          post: 'نشر',
          empty: 'لا توجد لحظات بعد',
          comments: 'التعليقات',
          likes: 'الإعجابات',
          report: 'إبلاغ',
          delete: 'حذف',
          cancel: 'إلغاء',
          retry: 'إعادة المحاولة',
          submit: 'إرسال',
          somethingWrong: 'حدث خطأ ما',
          reportedThanks: 'تم الإبلاغ. شكراً لك.',
          deleteConfirm: 'حذف اللحظة؟',
          deleteCommentConfirm: 'حذف التعليق؟',
          deleted: 'تم حذف اللحظة',
          writeOrPhoto: 'اكتب شيئاً أو أضف صورة',
          whatsOnMind: 'بمَ تفكّر؟',
          addPhotos: 'إضافة صور',
          whoLiked: 'مَن أعجبه',
          noComments: 'لا توجد تعليقات بعد',
          writeComment: 'اكتب تعليقاً…',
          reply: 'رد',
          replyingTo: 'الرد على',
          noLikes: 'لا توجد إعجابات بعد',
          user: 'مستخدم',
          like: 'إعجاب',
          reactLove: 'أحبّه',
          reactHaha: 'هههه',
          reactWow: 'واو',
          reactSad: 'حزين',
          reactAngry: 'غاضب',
          createPost: 'إنشاء منشور',
          whatToTalkAbout: 'عمَّ تريد أن تتحدث؟',
          addToYourPost: 'أضف إلى منشورك',
          photoVideo: 'صورة/فيديو',
          gif: 'صورة متحركة',
          poll: 'استطلاع',
          adoption: 'تبنّي',
          lostNotice: 'إعلان فقدان',
          event: 'فعالية',
          comingSoon: 'قريباً',
          reportTitle: 'الإبلاغ عن اللحظة',
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
