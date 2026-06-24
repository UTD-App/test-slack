import 'package:authentication/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_flow.dart';
import 'package:utd_app/network/network.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/models/my_data_model.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/services/user_session_service.dart';
import 'package:utd_app/shared/widgets/wheel_picker.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// The Base app's APP-SPECIFIC core actions (auth/profile/settings).
///
/// These were split out of the old `core_actions.dart`: the generic actions
/// (navigate/back/openDialog/closeDialog/toggleTheme/setLocale) now ship inside
/// `utd_studio_sdk`; the actions below stay in the app because they depend on
/// the app's auth use-cases, session model, and endpoints. They are passed to
/// `UtdStudio.init` via `StudioConfig.extraActions`.
///
/// Each reads its inputs from the enclosing `form` ([StacFormScope], via
/// [readFormField]) and delegates to the existing auth use cases / repositories
/// via [AuthLocator], reproducing the BLoCs' success/failure flow.

/// `core.login` — `{ actionType, emailField, passwordField }`
class CoreLoginActionParser extends StacMapActionParser {
  const CoreLoginActionParser();

  @override
  String get actionType => 'core.login';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.login;
    if (useCase == null) return;

    final email = readFormField(context, model, 'emailField');
    final password = readFormField(context, model, 'passwordField');
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
class CoreRegisterActionParser extends StacMapActionParser {
  const CoreRegisterActionParser();

  @override
  String get actionType => 'core.register';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.register;
    if (useCase == null) return;

    final email = readFormField(context, model, 'emailField');
    final password = readFormField(context, model, 'passwordField');
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
class CoreForgotPasswordActionParser extends StacMapActionParser {
  const CoreForgotPasswordActionParser();

  @override
  String get actionType => 'core.forgotPassword';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.forgetPassword;
    if (useCase == null) return;

    final email = readFormField(context, model, 'emailField');
    final password = readFormField(context, model, 'passwordField');
    final token = readFormField(context, model, 'tokenField');

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
class CoreSaveProfileActionParser extends StacMapActionParser {
  const CoreSaveProfileActionParser();

  @override
  String get actionType => 'core.saveProfile';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final name = readFormField(context, model, 'nameField');
    final bio = readFormField(context, model, 'bioField');
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

/// `core.changeAvatar` — `{ actionType, source?: gallery|camera }`. Picks an
/// image, uploads to `/profile/avatar`, writes the new URL into the user cache
/// (the `core.currentUser` source reads it) and invalidates so the avatar
/// updates in place without a screen reload.
class CoreChangeAvatarActionParser extends StacMapActionParser {
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
    if (picked == null) return; // user cancelled

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
class CoreLogoutActionParser extends StacMapActionParser {
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

/// `core.openProfile` — opens a user's FULL profile page (cover + counters +
/// package cards). `{ actionType, userId? }`; defaults to the signed-in user.
/// Used by the Me-landing avatar tap (the camera badge keeps `core.changeAvatar`).
/// The full profile is too rich for Stac primitives, so this routes to the
/// native profile route (`/user-profile/:id`, registered by the Profile package).
class CoreOpenProfileActionParser extends StacMapActionParser {
  const CoreOpenProfileActionParser();

  @override
  String get actionType => 'core.openProfile';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    final raw = model['userId'];
    final id = raw is int
        ? raw
        : int.tryParse('${raw ?? ''}') ??
            (context.read<UserDataNotifier>().user.id ?? 0);
    if (id <= 0) return;
    context.push('/user-profile/$id');
  }
}

/// `core.editProfile` — opens an in-place MODAL sheet to edit name + bio (the
/// old per-field "edit model"), instead of navigating to a separate page. Saves
/// via `/profile/update`, updates the session, and invalidates `core.currentUser`
/// so the landing reflects the change immediately.
class CoreEditProfileActionParser extends StacMapActionParser {
  const CoreEditProfileActionParser();

  @override
  String get actionType => 'core.editProfile';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final notifier = context.read<UserDataNotifier>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EditProfileSheet(notifier: notifier),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.notifier});

  final UserDataNotifier notifier;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.notifier.user.name ?? '');
  late final TextEditingController _bio =
      TextEditingController(text: widget.notifier.user.bio ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final bio = _bio.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.dio.post(
        '/profile/update',
        data: FormData.fromMap({'name': name, 'bio': bio}),
      );
      if (!mounted) return;
      widget.notifier.update(name: name, bio: bio);
      StacDataRegistry.instance.invalidate();
      ToastManager.showToast(context, message: 'تم الحفظ');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ToastManager.showToast(context, message: 'فشل الحفظ', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A1B4D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'تعديل الملف',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          _field(_name, 'الاسم'),
          const SizedBox(height: 12),
          _field(_bio, 'نبذة', maxLines: 3),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFCDBFEE)),
        filled: true,
        fillColor: const Color(0xFF3A2A5E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// `core.refresh` — re-fetches the server-driven data sources (core.currentUser,
/// profile.user, …) so the screen reflects the latest backend state. Wired to a
/// refresh button on the profile.
class CoreRefreshActionParser extends StacMapActionParser {
  const CoreRefreshActionParser();

  @override
  String get actionType => 'core.refresh';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    StacDataRegistry.instance.invalidate();
    ToastManager.showToast(context, message: 'تم التحديث');
  }
}

/// `core.copy` — copies a value to the clipboard (+ "تم النسخ" toast). Uses the
/// literal `value` when provided, otherwise reads the named `field` from the
/// signed-in user cache (default `uid` → uuid/uid/id). Wired to the copy glyph
/// next to the profile UID, mirroring the native Me-landing "ID: …" copy row.
class CoreCopyActionParser extends StacMapActionParser {
  const CoreCopyActionParser();

  @override
  String get actionType => 'core.copy';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    var text = (model['value'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      final field = (model['field'] as String?)?.trim();
      final user = CacheManager.getUserData() ?? const <String, dynamic>{};
      if (field == null || field.isEmpty || field == 'uid' || field == 'uuid') {
        text = (user['uuid'] ?? user['uid'] ?? user['id'] ?? '').toString();
      } else {
        text = (user[field] ?? '').toString();
      }
    }
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ToastManager.showToast(context, message: 'تم النسخ');
    }
  }
}

/// Derives age (years) from a stored birthday `yyyy-MM-dd`, or null when unset
/// — used to seed the age wheel with the current draft pick.
int? _ageFromBirthday(String? text) {
  if (text == null || text.isEmpty) return null;
  final birth = DateTime.tryParse(text);
  if (birth == null) return null;
  final now = DateTime.now();
  var age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age;
}

/// `core.selectGender` — `{ gender: 'male' | 'female' }`. Records the onboarding
/// gender draft and refreshes the renderer so the chosen card shows its check
/// (the `core.onboarding.genderMaleCheck/femaleCheck` bound Text). Used by the
/// server-driven add_information screen.
class CoreSelectGenderActionParser extends StacMapActionParser {
  const CoreSelectGenderActionParser();

  @override
  String get actionType => 'core.selectGender';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final g = (model['gender'] as String?)?.trim().toLowerCase();
    if (g != 'male' && g != 'female') return;
    await CacheManager.saveOnboardingDraft(
      g,
      CacheManager.getOnboardingBirthday(),
    );
    StacDataRegistry.instance.invalidate();
  }
}

/// `core.pickAge` — opens the age wheel, converts the picked age to a birthday
/// (`yyyy-MM-dd`, the backend contract), stores it in the onboarding draft, and
/// refreshes so `core.onboarding.ageLabel` shows it. Used by add_information.
class CorePickAgeActionParser extends StacMapActionParser {
  const CorePickAgeActionParser();

  @override
  String get actionType => 'core.pickAge';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final current = _ageFromBirthday(CacheManager.getOnboardingBirthday()) ?? 18;
    final age = await showAgePickerSheet(
      context,
      title: 'اختر عمرك',
      doneLabel: 'تم',
      initial: current,
      min: 18,
      max: 80,
    );
    if (age == null) return;
    final now = DateTime.now();
    final b = DateTime(now.year - age, now.month, now.day);
    final ymd = '${b.year.toString().padLeft(4, '0')}-'
        '${b.month.toString().padLeft(2, '0')}-'
        '${b.day.toString().padLeft(2, '0')}';
    await CacheManager.saveOnboardingDraft(
      CacheManager.getOnboardingGender(),
      ymd,
    );
    StacDataRegistry.instance.invalidate();
  }
}

/// `core.completeProfile` — `{ nameField }`. Submits the onboarding profile:
/// reads the name from the enclosing form + gender/birthday from the draft,
/// calls the AddInfo use case (`POST /profile/update`), hydrates the session and
/// navigates home. The avatar is uploaded separately by `core.changeAvatar`.
class CoreCompleteProfileActionParser extends StacMapActionParser {
  const CoreCompleteProfileActionParser();

  @override
  String get actionType => 'core.completeProfile';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final useCase = AuthLocator.addInfo;
    if (useCase == null) return;

    final name = readFormField(context, model, 'nameField').trim();
    final gender = CacheManager.getOnboardingGender();
    final birthday = CacheManager.getOnboardingBirthday();

    final missing = <String>[];
    if (name.isEmpty) missing.add('الاسم');
    if (gender == null) missing.add('الجنس');
    if (birthday == null || birthday.isEmpty) missing.add('العمر');
    if (missing.isNotEmpty) {
      ToastManager.showToast(
        context,
        message: 'يرجى إكمال: ${missing.join('، ')}',
        isError: true,
      );
      return;
    }

    final result = await useCase(
      InformationParameter(
        name: name,
        gender: gender == 'male' ? 1 : 0,
        date: birthday,
        image: null,
      ),
    );

    switch (result) {
      case Success(data: final data):
        if (context.mounted) {
          await UserSessionService.hydrate(context.read<UserDataNotifier>());
        }
        await CacheManager.clearOnboardingDraft();
        if (context.mounted) {
          ToastManager.showToast(context, message: data.message);
          context.go(AppFlow.instance.onAuthSuccess);
        }
      case Failure(message: final message):
        if (context.mounted) {
          ToastManager.showToast(context, message: message, isError: true);
        }
    }
  }
}

/// The app-specific core actions, passed to `StudioConfig.extraActions`.
const List<StacActionParser> appCoreActionParsers = [
  CoreLoginActionParser(),
  CoreRegisterActionParser(),
  CoreForgotPasswordActionParser(),
  CoreSaveProfileActionParser(),
  CoreChangeAvatarActionParser(),
  CoreOpenProfileActionParser(),
  CoreEditProfileActionParser(),
  CoreRefreshActionParser(),
  CoreCopyActionParser(),
  CoreLogoutActionParser(),
  CoreSelectGenderActionParser(),
  CorePickAgeActionParser(),
  CoreCompleteProfileActionParser(),
];
