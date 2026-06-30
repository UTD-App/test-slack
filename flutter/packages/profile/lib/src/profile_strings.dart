/// Translation keys + bundled values for the Profile feature.
/// Usage: `context.tr(ProfileStrings.title)`.
///
/// Key strings and en/ar values mirror the backend translation catalog
/// (`resources/lang/<locale>/profile.php`) — keep them in sync.
class ProfileStrings {
  ProfileStrings._();

  static const menuProfile = 'profile.menu_profile';
  static const title = 'profile.title';
  static const error = 'profile.error';
  static const retry = 'profile.retry';
  static const notFound = 'profile.not_found';
  static const id = 'profile.id';
  static const copied = 'profile.copied';
  static const comingSoon = 'profile.coming_soon';
  static const previewAsVisitor = 'profile.preview_as_visitor';

  // Stats
  static const friend = 'profile.friend';
  static const following = 'profile.following';
  static const followers = 'profile.followers';
  static const visitors = 'profile.visitors';

  // SVIP banner
  static const svipTitle = 'profile.svip_title';
  static const svipSubtitle = 'profile.svip_subtitle';
  static const getSvip = 'profile.get_svip';

  // Wallet
  static const diamonds = 'profile.diamonds';
  static const coins = 'profile.coins';

  // Feature grid
  static const level = 'profile.level';
  static const store = 'profile.store';
  static const tasks = 'profile.tasks';
  static const family = 'profile.family';
  static const vip = 'profile.vip';
  static const cp = 'profile.cp';
  static const bdCenter = 'profile.bd_center';
  static const agencyCenter = 'profile.agency_center';
  static const myPost = 'profile.my_post';
  static const offlineRecharge = 'profile.offline_recharge';
  static const hostCenter = 'profile.host_center';
  static const myVideos = 'profile.my_videos';
  static const settings = 'profile.settings';
  static const addBio = 'profile.add_bio';

  // Cover banner
  static const cover = 'profile.cover';
  static const addCover = 'profile.add_cover';
  static const manageCovers = 'profile.manage_covers';
  static const maxCoversReached = 'profile.max_covers_reached';

  // Visited-profile content tabs
  static const tabGeneral = 'profile.tab_general';

  // Badge chips (keyed on canonical badge id) — built as
  // `'${ProfileStrings.badgePrefix}$id'`.
  static const badgePrefix = 'profile.badge_';
  static const badgeAgency = 'profile.badge_agency';
  static const badgeTasks = 'profile.badge_tasks';
  static const badgeVip = 'profile.badge_vip';
  static const badgeBd = 'profile.badge_bd';
  static const badgeVerified = 'profile.badge_verified';

  static Map<String, Map<String, String>> translations() => {
        'en': {
          menuProfile: 'Profile',
          title: 'Profile',
          error: 'Failed to load profile',
          retry: 'Retry',
          notFound: 'User not found',
          id: 'ID',
          copied: 'ID copied',
          comingSoon: 'Coming soon',
          previewAsVisitor: 'Visitor view',
          // Stats
          friend: 'Friend',
          following: 'Following',
          followers: 'Followers',
          visitors: 'Visitors',
          // SVIP banner
          svipTitle: 'SVIP Club',
          svipSubtitle: 'Enjoy distinguished privileges',
          getSvip: 'Get SVIP',
          // Wallet
          diamonds: 'Diamonds',
          coins: 'Coins',
          // Feature grid
          level: 'Level',
          store: 'Store',
          tasks: 'Tasks',
          family: 'Family',
          vip: 'VIP',
          cp: 'CP',
          bdCenter: 'BD Center',
          agencyCenter: 'Agency Center',
          myPost: 'My Post',
          offlineRecharge: 'Offline Recharge',
          hostCenter: 'Host Center',
          myVideos: 'My Videos',
          settings: 'Settings',
          addBio: 'Add a bio',
          // Cover banner
          cover: 'Cover',
          addCover: 'Add a cover',
          manageCovers: 'Cover photos',
          maxCoversReached: 'You can add up to 3 covers',
          // Visited-profile content tabs
          tabGeneral: 'General',
          // Badge chips (keyed on canonical badge id)
          badgeAgency: 'Agency',
          badgeTasks: 'Tasks',
          badgeVip: 'VIP',
          badgeBd: 'BD',
          badgeVerified: 'Verified',
        },
        'ar': {
          menuProfile: 'الملف الشخصي',
          title: 'الملف الشخصي',
          error: 'فشل تحميل الملف الشخصي',
          retry: 'إعادة المحاولة',
          notFound: 'المستخدم غير موجود',
          id: 'الأيدي',
          copied: 'تم نسخ الأيدي',
          comingSoon: 'قريبًا',
          previewAsVisitor: 'كما يراه الزائر',
          // Stats
          friend: 'الأصدقاء',
          following: 'يتابع',
          followers: 'المتابعون',
          visitors: 'الزوار',
          // SVIP banner
          svipTitle: 'نادي SVIP',
          svipSubtitle: 'استمتع بامتيازات مميزة',
          getSvip: 'احصل على SVIP',
          // Wallet
          diamonds: 'الماس',
          coins: 'العملات',
          // Feature grid
          level: 'المستوى',
          store: 'المتجر',
          tasks: 'المهام',
          family: 'العائلة',
          vip: 'VIP',
          cp: 'CP',
          bdCenter: 'مركز BD',
          agencyCenter: 'مركز الوكالة',
          myPost: 'منشوراتي',
          offlineRecharge: 'شحن أوفلاين',
          hostCenter: 'مركز المضيف',
          myVideos: 'فيديوهاتي',
          settings: 'الإعدادات',
          addBio: 'أضف نبذة',
          // Cover banner
          cover: 'الغلاف',
          addCover: 'أضف صورة غلاف',
          manageCovers: 'صور الغلاف',
          maxCoversReached: 'يمكنك إضافة 3 صور غلاف كحد أقصى',
          // Visited-profile content tabs
          tabGeneral: 'عام',
          // Badge chips (keyed on canonical badge id)
          badgeAgency: 'وكالة',
          badgeTasks: 'المهام',
          badgeVip: 'VIP',
          badgeBd: 'BD',
          badgeVerified: 'موثّق',
        },
      };
}
