import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/network.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// Wires the base app's CORE data into the Stac renderer (app glue).
///
/// Mirrors `registerChatStacSources` (chat package) but for the screens that
/// ship inside the base app. Currently exposes the signed-in user as the
/// single-object source `core.currentUser`, consumed by a `utdObject` on the
/// profile screen. Keys MUST match the `core` manifest elements
/// (backend/config/utd_manifest_core.php → name/email/bio/avatar).
///
/// Pulls fresh data from `/my-data` (which now returns a ready-to-display
/// `avatar` URL) and refreshes the cache, so the profile screen shows the real
/// photo on first open. Falls back to the cached payload when offline.
void registerCoreStacSources() {
  StacDataRegistry.instance.registerObject('core.currentUser', () async {
    // cache-first: نرجّع المخزَّن فورًا (في فريم واحد) فالـ utdObject مايعرضش
    // سبينر يغطّي الشاشة، ونحدّث /my-data في الخلفية ونعمل invalidate بس لو حقل
    // معروض اتغيّر فعلاً. كده تغيير الصورة (core.changeAvatar كتب الـ avatar في
    // الكاش) يبان فورًا، وإعادة الرسم تتحصر في الـ Image المتغيّرة (widget diffing).
    _refreshCurrentUser();
    final user = CacheManager.getUserData() ?? const <String, dynamic>{};
    return _userFields(user);
  });
}

/// الحقول المعروضة من المستخدم (نفس مفاتيح الـ manifest object_source
/// `core.currentUser`: name/email/bio/avatar/cover/country/flag/uid). نحلّها
/// دفاعيًا من أي شكل بيرجع به `/my-data`؛ الناقص → '' (الـ manifest بيخفيه عبر
/// visibleBinding). الـ bio بياخد placeholder لو فاضي عشان صف التعديل يفضل ذو معنى.
Map<String, dynamic> _userFields(Map<String, dynamic> user) {
  // `/my-data` NESTS media: avatar/cover live under `profile` (with absolute
  // `image`/`cover_images` URLs built by the Media seam — prefer those over the
  // raw `avatar`/`covers` paths, which 404 on cloud storage), and the country
  // flag lives under `country`. Reading the wrong TOP-LEVEL keys is why the outer
  // Me-landing showed no avatar/flag while the inner full profile (which reads
  // these same nested keys via the profile API) did.
  final profile = user['profile'] is Map ? user['profile'] as Map : const {};
  final country = user['country'] is Map ? user['country'] as Map : const {};
  final rawGender = profile['gender'] ?? user['gender'];
  final gender =
      rawGender is num ? rawGender.toInt() : int.tryParse('${rawGender ?? ''}');
  final rawAvatar =
      (profile['image'] ?? profile['avatar'] ?? user['avatar'] ?? user['image'])
          ?.toString();
  final coverList =
      profile['cover_images'] ?? profile['covers'] ?? user['covers'] ?? user['cover'];
  final rawCover = (coverList is List && coverList.isNotEmpty)
      ? coverList.first.toString()
      : (coverList is String ? coverList : '');
  // Level badges (wealth / charm). Sent by the gifts/levels package via
  // /my-data when installed; absent otherwise → the badge string stays '' so the
  // bound Text on the Studio profile renders nothing (graceful, like the native
  // ProfileIdentity which only shows a chip when the level is present).
  final levels = user['levels'] is Map ? user['levels'] as Map : const {};
  final wealthLevel =
      user['wealth_level'] ?? user['wealthLevel'] ?? levels['wealth'];
  final charmLevel =
      user['charm_level'] ?? user['charmLevel'] ?? levels['charm'];
  return {
    'name': user['name'] ?? '',
    'email': user['email'] ?? '',
    'bio': (user['bio']?.toString().trim().isNotEmpty ?? false)
        ? user['bio']
        : 'أضف نبذة',
    // Resolve media to ABSOLUTE URLs — the Stac renderer loads the value
    // verbatim, so a raw path 404s. Absolute http(s) values pass through.
    'avatar': _media(rawAvatar),
    'cover': _media(rawCover),
    'country': (country['name'] ?? user['country_name'])?.toString() ?? '',
    'flag': _media(
        (country['flag'] ?? user['country_flag'] ?? user['flag'])?.toString()),
    'uid': user['uuid']?.toString() ??
        user['uid']?.toString() ??
        user['id']?.toString() ??
        '',
    // Gender → two visibleBinding-gated icons in the manifest (1=male,2=female).
    'isMale': gender == 1 ? '1' : '',
    'isFemale': gender == 2 ? '1' : '',
    // Gender sign: the symbol for the matching gender, '' otherwise. Bound to a
    // colored Text in the manifest (UTD Studio drops visibleBinding, so a bound
    // empty string is how we hide the non-matching one).
    'maleSign': gender == 1 ? '♂' : '',
    'femaleSign': gender == 2 ? '♀' : '',
    // Bound to two Text nodes on the Studio profile (empty → renders nothing).
    'wealthBadge': '$wealthLevel'.trim().isNotEmpty && '$wealthLevel' != 'null'
        ? '🏆 LV.$wealthLevel'
        : '',
    'charmBadge': '$charmLevel'.trim().isNotEmpty && '$charmLevel' != 'null'
        ? '💎 LV.$charmLevel'
        : '',
  };
}

/// Resolve a backend media path to an absolute `…/storage/…` URL (mirrors the
/// profile package's resolveMediaUrl). Absolute http(s) values pass through.
String _media(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return '';
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  var clean = s.startsWith('/') ? s.substring(1) : s;
  if (!clean.startsWith('storage/')) clean = 'storage/$clean';
  return '${_apiOrigin()}/$clean';
}

/// يسحب `/my-data` في الخلفية (fire-and-forget) ويكاشه؛ يعمل invalidate بس لو حقل
/// معروض اتغيّر فعلاً (نتفادى أي loop/flash على اختلافات غير مرئية).
void _refreshCurrentUser() {
  Future(() async {
    try {
      final res = await ApiClient.instance.dio.get('/my-data');
      final data = res.data is Map ? (res.data['data'] as Map?) : null;
      if (data == null) return;
      final old = CacheManager.getUserData() ?? const <String, dynamic>{};
      final merged = {...old, ...Map<String, dynamic>.from(data)};
      await CacheManager.saveUserData(merged);
      if (!_sameUser(old, merged)) {
        StacDataRegistry.instance.invalidate();
      }
    } catch (_) {
      // أوفلاين/خطأ → نكمّل بالمخزَّن.
    }
  });
}

/// مقارنة الحقول المعروضة فقط لتقرير الحاجة لـ invalidate.
bool _sameUser(Map old, Map neu) {
  final a = _userFields(Map<String, dynamic>.from(old));
  final b = _userFields(Map<String, dynamic>.from(neu));
  for (final k in const [
    'name', 'email', 'bio', 'avatar', 'cover', 'country', 'flag', 'uid',
    'isMale', 'isFemale', 'maleSign', 'femaleSign', 'wealthBadge', 'charmBadge',
  ]) {
    if ((a[k] ?? '').toString() != (b[k] ?? '').toString()) return false;
  }
  return true;
}

/// Wires the app-level branding source `core.app` (logo / name / tagline) used
/// by server-driven screens (e.g. the splash). The VALUES are owned by the
/// base/web admin (`Config: app_logo / app_name / app_tagline`) — UTD Studio
/// only reads the `core.app` attributes from the manifest and shows them in its
/// binding picker; it never stores branding itself.
///
/// Pulls `/configs` (the public app config) and caches it so warm launches
/// resolve offline; always returns non-empty defaults so a bound logo never
/// collapses into the avatar placeholder. The logo is normalised to an absolute
/// URL on-device (the manifest is base-agnostic, so the origin is added here).
void registerCoreAppSource() {
  StacDataRegistry.instance.registerObject('core.app', () async {
    // الـ splash لازم يظهر محتواه فورًا. فمنستنّاش الشبكة هنا: نرجّع الكاش/الافتراضي
    // على طول (المصدر بيرجع في فريم واحد بدل ما يفضل سبينر طول ما /configs بيتحمّل)،
    // والتحديث من /configs بيتم في الخلفية مع invalidate لو الـ branding اتغيّر.
    _refreshAppConfig();
    final cfg = CacheManager.getAppConfig() ?? const <String, dynamic>{};
    return _appBranding(cfg);
  });
}

/// تمّ سحب `/configs` في الجلسة الحالية؟ (مرة واحدة تكفي للـ splash؛ المخزَّن بيغطّي الباقي).
bool _appConfigSynced = false;

/// يسحب `/configs` في الخلفية (fire-and-forget) ويكاشه؛ لو الـ branding اتغيّر يعمل
/// invalidate عشان الـ splash (وأي binding لـ core.app) يعيد الجلب بالقيم الجديدة.
void _refreshAppConfig() {
  if (_appConfigSynced) return;
  _appConfigSynced = true; // امنع التكرار في نفس الجلسة (لو فشل نعتمد على المخزَّن)
  Future(() async {
    try {
      final res = await ApiClient.instance.dio.get('/configs');
      final list = res.data is Map ? res.data['data'] : null;
      if (list is! List) return;
      final parsed = <String, dynamic>{};
      for (final row in list) {
        if (row is Map && row['name'] != null) {
          parsed[row['name'].toString()] = row['value'];
        }
      }
      final old = CacheManager.getAppConfig() ?? const {};
      await CacheManager.saveAppConfig(parsed);
      if (!_sameBranding(old, parsed)) {
        StacDataRegistry.instance.invalidate(); // يعيد رسم الـ splash بالقيم الجديدة
      }
    } catch (_) {
      // أوفلاين/خطأ → نكمّل بالمخزَّن.
    }
  });
}

/// بناء الـ branding (logo مطلق / name / tagline) من الإعدادات مع defaults غير فاضية
/// عشان الـ splash مايبانش فاضي أبدًا.
Map<String, dynamic> _appBranding(Map<String, dynamic> cfg) {
  final origin = _apiOrigin();
  final rawLogo = (cfg['app_logo'] ?? '').toString().trim();
  final name = (cfg['app_name'] ?? '').toString().trim();
  final tagline = (cfg['app_tagline'] ?? '').toString().trim();
  return {
    'logo': rawLogo.isNotEmpty
        ? _absUrl(rawLogo, origin)
        : '$origin/images/utd-splash-logo.png',
    'name': name.isNotEmpty ? name : 'UTD Stack',
    'tagline': tagline.isNotEmpty ? tagline : 'Build apps, instantly',
  };
}

/// مقارنة مفاتيح الـ branding التلاتة فقط (نتفادى invalidate/loop على اختلافات تافهة).
bool _sameBranding(Map old, Map neu) {
  for (final k in const ['app_logo', 'app_name', 'app_tagline']) {
    if ((old[k] ?? '').toString() != (neu[k] ?? '').toString()) return false;
  }
  return true;
}

/// Origin of the API (the configured base URL without the trailing `/api`),
/// used to absolutise relative asset paths returned by the backend.
String _apiOrigin() {
  var base = ApiClient.instance.dio.options.baseUrl;
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
  return base;
}

/// Returns [v] as-is when already absolute, otherwise prefixes the API [origin].
String _absUrl(String v, String origin) {
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  return '$origin/${v.startsWith('/') ? v.substring(1) : v}';
}
