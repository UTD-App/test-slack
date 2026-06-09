import 'package:authentication/authentication.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stac/stac.dart' hide StacService;
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_flow.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/localization/locale_notifier.dart';
import 'package:utd_app/network/network.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/models/my_data_model.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/stac/stac_data_registry.dart';

/// Custom Stac actions for the base app's CORE screens (auth/profile/settings).
///
/// These let a UTD-Studio-designed, server-driven screen drive real behaviour:
/// each action reads its inputs from the enclosing `form` ([StacFormScope]) and
/// delegates to the EXISTING auth use cases / repositories via [AuthLocator],
/// reproducing the BLoCs' success/failure flow (token caching, user notifier,
/// toast, navigation). The Studio never hardcodes these — it discovers them
/// from the backend manifest's `action_elements` (`produces` == `actionType`).

/// Reads a submitted form field by id (the `textFormField` `id`).
String _field(BuildContext context, Map<String, dynamic> model, String key,
    {String fallback = ''}) {
  final id = (model[key] as String?)?.trim();
  if (id == null || id.isEmpty) return '';
  final value = StacFormScope.of(context)?.formData[id];
  final text = (value ?? fallback).toString().trim();
  return text;
}

/// Base for our actions: the JSON map IS the model (no codegen needed).
abstract class _MapActionParser extends StacActionParser<Map<String, dynamic>> {
  const _MapActionParser();

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;
}

/// `core.login` — `{ actionType, emailField, passwordField }`
class CoreLoginActionParser extends _MapActionParser {
  const CoreLoginActionParser();

  @override
  String get actionType => 'core.login';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.login;
    if (useCase == null) return;

    final email = _field(context, model, 'emailField');
    final password = _field(context, model, 'passwordField');
    // الشاشة اللي يروح لها عند النجاح: لو المصمم حدّدها في Studio نستخدمها،
    // وإلا نرجع لوجهة النجاح في الـ AppFlow (الافتراضي = Home).
    final successRoute = (model['successRoute'] as String?)?.trim();

    final result = await useCase(
      AuthParameter(email: email, password: password),
    );

    switch (result) {
      case Success(data: final data):
        final entity = data.data;
        if (entity != null) {
          await CacheManager.saveToken(entity.authToken);
          final user = entity.user as MyDataModel?;
          if (user != null && context.mounted) {
            await CacheManager.saveUserData(user.toJson());
            context.read<UserDataNotifier>().setUser(user);
          }
        }
        if (context.mounted) {
          ToastManager.showToast(context, message: data.message);
          context.go(
            (successRoute != null && successRoute.isNotEmpty)
                ? successRoute
                : AppFlow.instance.onAuthSuccess,
          );
        }
      case Failure(message: final message):
        if (context.mounted) {
          ToastManager.showToast(context, message: message, isError: true);
        }
    }
  }
}

/// `core.register` — `{ actionType, emailField, passwordField }`
class CoreRegisterActionParser extends _MapActionParser {
  const CoreRegisterActionParser();

  @override
  String get actionType => 'core.register';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.register;
    if (useCase == null) return;

    final email = _field(context, model, 'emailField');
    final password = _field(context, model, 'passwordField');
    // الشاشة اللي يروح لها عند نجاح التسجيل: لو المصمم حدّدها في Studio نستخدمها،
    // وإلا نرجع للسلوك الافتراضي (شاشة إكمال البيانات).
    final successRoute = (model['successRoute'] as String?)?.trim();

    final result = await useCase(
      RegisterParameter(email: email, password: password),
    );

    switch (result) {
      case Success(data: final data):
        await CacheManager.saveToken(data.data ?? '');
        if (context.mounted) {
          ToastManager.showToast(context, message: data.message);
          context.go(
            (successRoute != null && successRoute.isNotEmpty)
                ? successRoute
                : AuthRoutes.addInformation,
          );
        }
      case Failure(message: final message):
        if (context.mounted) {
          ToastManager.showToast(context, message: message, isError: true);
        }
    }
  }
}

/// `core.forgotPassword` — `{ actionType, emailField, passwordField?, tokenField? }`
class CoreForgotPasswordActionParser extends _MapActionParser {
  const CoreForgotPasswordActionParser();

  @override
  String get actionType => 'core.forgotPassword';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.forgetPassword;
    if (useCase == null) return;

    final email = _field(context, model, 'emailField');
    final password = _field(context, model, 'passwordField');
    final token = _field(context, model, 'tokenField');

    final result = await useCase(
      ForgetPasswordParameter(email: email, password: password, token: token),
    );

    switch (result) {
      case Success(data: final data):
        if (context.mounted) {
          ToastManager.showToast(context, message: data.message);
          final route = model['route'] as String?;
          if (route != null && route.isNotEmpty) context.go(route);
        }
      case Failure(message: final message):
        if (context.mounted) {
          ToastManager.showToast(context, message: message, isError: true);
        }
    }
  }
}

/// `core.saveProfile` — `{ actionType, nameField, bioField }`
class CoreSaveProfileActionParser extends _MapActionParser {
  const CoreSaveProfileActionParser();

  @override
  String get actionType => 'core.saveProfile';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final name = _field(context, model, 'nameField');
    final bio = _field(context, model, 'bioField');
    if (name.isEmpty) return;

    try {
      await ApiClient.instance.dio.post(
        '/profile/update',
        data: FormData.fromMap({'name': name, 'bio': bio}),
      );
      if (context.mounted) {
        context.read<UserDataNotifier>().update(name: name, bio: bio);
        ToastManager.showToast(context, message: 'تم الحفظ');
      }
    } catch (_) {
      if (context.mounted) {
        ToastManager.showToast(context, message: 'فشل الحفظ', isError: true);
      }
    }
  }
}

/// `core.changeAvatar` — `{ actionType, source?: gallery|camera }`
/// العميل بيحطّه كـ onTap على عنصر الصورة في شاشة الـ profile. بيفتح المعرض
/// (أو الكاميرا)، يرفع الصورة لـ `/profile/avatar`، ويكتب الـ URL الجديد في
/// كاش المستخدم (اللي مصدر `core.currentUser` بيقرأ منه) وينبّه على إعادة الرسم
/// فالصورة تتحدّث فورًا من غير ما نعيد تحميل الشاشة.
class CoreChangeAvatarActionParser extends _MapActionParser {
  const CoreChangeAvatarActionParser();

  @override
  String get actionType => 'core.changeAvatar';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final wantsCamera =
        (model['source'] as String?)?.trim().toLowerCase() == 'camera';

    final XFile? picked = await ImagePicker().pickImage(
      source: wantsCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (picked == null) return; // المستخدم لغى الاختيار

    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });
      final res = await ApiClient.instance.dio.post(
        '/profile/avatar',
        data: form,
      );

      final data = res.data is Map ? (res.data['data'] as Map?) : null;
      final url = data?['url']?.toString() ?? '';
      if (url.isEmpty) throw StateError('no url');

      // حدّث الكاش اللي بيقرأ منه مصدر core.currentUser ثم نبّه على إعادة الجلب.
      final cached = CacheManager.getUserData() ?? <String, dynamic>{};
      cached['avatar'] = url;
      await CacheManager.saveUserData(cached);
      StacDataRegistry.instance.invalidate();

      if (context.mounted) {
        ToastManager.showToast(context, message: 'تم تحديث الصورة');
      }
    } catch (_) {
      if (context.mounted) {
        ToastManager.showToast(
          context,
          message: 'فشل تحديث الصورة',
          isError: true,
        );
      }
    }
  }
}

/// `core.logout` — `{ actionType, confirm? }`
class CoreLogoutActionParser extends _MapActionParser {
  const CoreLogoutActionParser();

  @override
  String get actionType => 'core.logout';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final needsConfirm = model['confirm'] == true;
    if (needsConfirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    await CacheManager.clear();
    if (context.mounted) {
      context.read<UserDataNotifier>().clear();
      context.go(AppFlow.instance.onLogout);
    }
  }
}

/// `core.navigate` — `{ actionType, route, mode: go|push|replace, extra? }`
/// GoRouter-aware (the built-in `navigate` uses Flutter Navigator instead).
class CoreNavigateActionParser extends _MapActionParser {
  const CoreNavigateActionParser();

  @override
  String get actionType => 'core.navigate';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    final route = (model['route'] as String?)?.trim();
    if (route == null || route.isEmpty) return;
    // الافتراضي push: الانتقال لشاشة فرعية يسيب زرّ الرجوع شغّالًا (لا يقفل التطبيق).
    // أكشنز الـ auth (login/logout) تستخدم go صراحةً عند الحاجة.
    final mode = (model['mode'] as String?) ?? 'push';
    final extra = model['extra'];

    switch (mode) {
      case 'push':
        context.push(route, extra: extra);
      case 'replace':
        context.pushReplacement(route, extra: extra);
      default:
        context.go(route, extra: extra);
    }
  }
}

/// `core.back` — يرجع خطوة للشاشة السابقة (GoRouter `pop`). لو مفيش شاشة سابقة
/// يروح للـ `fallback` المحدّد أو لـ home. ده اللي العميل بيحطه على زرّ/أيقونة
/// الرجوع بنفسه (مفيش زرّ رجوع تلقائي في الـ AppBar).
class CoreBackActionParser extends _MapActionParser {
  const CoreBackActionParser();

  @override
  String get actionType => 'core.back';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final route = (model['fallback'] as String?)?.trim();
    context.go((route != null && route.isNotEmpty) ? route : AppFlow.instance.home);
  }
}

/// `core.toggleTheme` — `{ actionType, mode? }` (mode: light|dark|system)
class CoreToggleThemeActionParser extends _MapActionParser {
  const CoreToggleThemeActionParser();

  @override
  String get actionType => 'core.toggleTheme';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final notifier = context.read<ThemeNotifier>();
    final mode = model['mode'] as String?;
    switch (mode) {
      case 'light':
        await notifier.setThemeMode(ThemeMode.light);
      case 'dark':
        await notifier.setThemeMode(ThemeMode.dark);
      case 'system':
        await notifier.setThemeMode(ThemeMode.system);
      default:
        await notifier.toggle();
    }
  }
}

/// `core.setLocale` — `{ actionType, code }`
class CoreSetLocaleActionParser extends _MapActionParser {
  const CoreSetLocaleActionParser();

  @override
  String get actionType => 'core.setLocale';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final code = (model['code'] as String?)?.trim();
    if (code == null || code.isEmpty) return;
    try {
      await context.read<LocaleNotifier>().setLocale(Locale(code));
    } catch (_) {
      // Unsupported locale — ignore.
    }
  }
}

/// All core action parsers, registered in [Stac.initialize].
const List<StacActionParser> coreStacActionParsers = [
  CoreLoginActionParser(),
  CoreRegisterActionParser(),
  CoreForgotPasswordActionParser(),
  CoreSaveProfileActionParser(),
  CoreChangeAvatarActionParser(),
  CoreLogoutActionParser(),
  CoreNavigateActionParser(),
  CoreBackActionParser(),
  CoreToggleThemeActionParser(),
  CoreSetLocaleActionParser(),
];
