class AuthStrings {
  AuthStrings._();

  // ── Onboarding ──────────────────────────────────────────
  static const onBoarding1Title = 'auth.onboarding1_title';
  static const onBoarding2Title = 'auth.onboarding2_title';
  static const onBoarding3Title = 'auth.onboarding3_title';
  static const onBoarding1Subtitle = 'auth.onboarding1_subtitle';
  static const onBoarding2Subtitle = 'auth.onboarding2_subtitle';
  static const onBoarding3Subtitle = 'auth.onboarding3_subtitle';
  static const getStarted = 'auth.get_started';

  // ── Intro / Sign In ────────────────────────────────────
  static const playStreamConnect = 'auth.play_stream_connect';
  static const signInWithEmail = 'auth.sign_in_with_email';
  static const createAccount = 'auth.create_account';
  static const bySigningUp = 'auth.by_signing_up';
  static const termsOfService = 'auth.terms_of_service';
  static const privacyPolicy = 'auth.privacy_policy';
  static const haveRead = 'auth.have_read';
  static const termsAndCondition = 'auth.terms_and_condition';
  static const ban = 'auth.ban';

  // ── Login ───────────────────────────────────────────────
  static const hiTemp = 'auth.hi_temp';
  static const loginTel = 'auth.login_tel';
  static const email = 'auth.email';
  static const pleaseEnterYourEmail = 'auth.please_enter_your_email';
  static const password = 'auth.password';
  static const requiredField = 'auth.required_field';
  static const emailValidator = 'auth.email_validator';
  static const recoverPassword = 'auth.recover_password';
  static const login = 'auth.login';
  static const agreeLogin = 'auth.agree_login';
  static const userAgreementLogin = 'auth.user_agreement_login';
  static const andLogin = 'auth.and_login';

  // ── Add Information ─────────────────────────────────────
  static const improveTheInfo = 'auth.improve_the_info';
  static const uploadPicture = 'auth.upload_picture';
  static const fullName = 'auth.full_name';
  static const gender = 'auth.gender';
  static const male = 'auth.male';
  static const female = 'auth.female';
  static const submit = 'auth.submit';
  static const pickImage = 'auth.pick_image';
  static const username = 'auth.username';
  static const selectGender = 'auth.select_gender';
  static const selectBirthday = 'auth.select_birthday';
  static const userUnder18 = 'auth.user_under_18';

  // ── Splash ──────────────────────────────────────────────
  static const loadingResources = 'auth.loading_resources';

  // ── Register ─────────────────────────────────────────────
  static const registration = 'auth.registration';
  static const exitDialogTitle = 'auth.exit_dialog_title';
  static const exitDialogForgetPass = 'auth.exit_dialog_forget_pass';
  static const thinkAgain = 'auth.think_again';
  static const giveUpRegistering = 'auth.give_up_registering';
  static const giveUpReset = 'auth.give_up_reset';
  static const passwordTooShort = 'auth.password_too_short';
  static const notRegisteredYet = 'auth.not_registered_yet';
  static const registerNow = 'auth.register_now';

  // ── Common ──────────────────────────────────────────────
  static const success = 'auth.success';
  static const next = 'auth.next';
  static const updateDesc = 'auth.update_desc';

  static Map<String, Map<String, String>> translations(String appName) => {
        'en': {
          onBoarding1Title: 'Welcome to $appName',
          onBoarding2Title: 'Connect with Friends',
          onBoarding3Title: 'Start Your Journey',
          onBoarding1Subtitle:
              'The best platform to stream, play, and connect with others.',
          onBoarding2Subtitle:
              'Meet new people, join rooms, and share moments together.',
          onBoarding3Subtitle:
              'Create your profile and start exploring features now.',
          getStarted: 'Get Started',
          playStreamConnect: 'Play · Stream · Connect',
          signInWithEmail: 'Sign in with Email',
          createAccount: 'Create Account',
          bySigningUp: 'By signing up, you agree to our ',
          termsOfService: 'Terms of Service',
          privacyPolicy: 'Privacy Policy',
          haveRead: 'I have read the ',
          termsAndCondition: 'Terms and Conditions',
          ban: 'Account Banned',
          hiTemp: 'Hi there 👋',
          loginTel: 'Enter your email to continue',
          email: 'Email',
          pleaseEnterYourEmail: 'Enter your email address',
          password: 'Password',
          requiredField: 'This field is required',
          emailValidator: 'Please enter a valid email address',
          recoverPassword: 'Recover Password',
          login: 'Login',
          agreeLogin: 'By logging in you agree to the ',
          userAgreementLogin: 'User Agreement',
          andLogin: ' and Privacy Policy',
          improveTheInfo: 'Complete your profile to get started',
          uploadPicture: 'Upload Picture',
          fullName: 'Full Name',
          gender: 'Gender',
          male: 'Male',
          female: 'Female',
          submit: 'Submit',
          pickImage: 'Please pick a profile image',
          username: 'Please enter your name',
          selectGender: 'Please select your gender',
          selectBirthday: 'Please select your birthday',
          userUnder18: 'You must be at least 18 years old',
          loadingResources: 'Loading some resources...',
          registration: 'Registration',
          exitDialogTitle: 'Are you sure you want to leave registration?',
          exitDialogForgetPass:
              'Are you sure you want to leave password reset?',
          thinkAgain: 'Think Again',
          giveUpRegistering: 'Give Up Registering',
          giveUpReset: 'Give Up Reset',
          passwordTooShort: 'Password must be at least 6 characters',
          notRegisteredYet: 'Not registered yet?',
          registerNow: 'Register Now',
          success: 'Success',
          next: 'Next',
          updateDesc: 'A new version is available. Please update the app.',
        },
        'ar': {
          onBoarding1Title: 'مرحباً بك في $appName',
          onBoarding2Title: 'تواصل مع الأصدقاء',
          onBoarding3Title: 'ابدأ رحلتك',
          onBoarding1Subtitle:
              'أفضل منصة للبث والتواصل والاستمتاع مع الآخرين.',
          onBoarding2Subtitle:
              'تعرف على أشخاص جدد، انضم إلى الغرف وشارك لحظاتك.',
          onBoarding3Subtitle:
              'أنشئ ملفك الشخصي وابدأ باستكشاف الميزات الآن.',
          getStarted: 'ابدأ الآن',
          playStreamConnect: 'العب · بث · تواصل',
          signInWithEmail: 'تسجيل الدخول بالبريد الإلكتروني',
          createAccount: 'إنشاء حساب',
          bySigningUp: 'بالتسجيل، أنت توافق على ',
          termsOfService: 'شروط الخدمة',
          privacyPolicy: 'سياسة الخصوصية',
          haveRead: 'لقد قرأت ',
          termsAndCondition: 'الشروط والأحكام',
          ban: 'الحساب محظور',
          hiTemp: 'مرحباً 👋',
          loginTel: 'أدخل بريدك الإلكتروني للمتابعة',
          email: 'البريد الإلكتروني',
          pleaseEnterYourEmail: 'أدخل عنوان بريدك الإلكتروني',
          password: 'كلمة المرور',
          requiredField: 'هذا الحقل مطلوب',
          emailValidator: 'يرجى إدخال بريد إلكتروني صحيح',
          recoverPassword: 'استعادة كلمة المرور',
          login: 'تسجيل الدخول',
          agreeLogin: 'بتسجيل الدخول أنت توافق على ',
          userAgreementLogin: 'اتفاقية المستخدم',
          andLogin: ' وسياسة الخصوصية',
          improveTheInfo: 'أكمل ملفك الشخصي للبدء',
          uploadPicture: 'رفع صورة',
          fullName: 'الاسم الكامل',
          gender: 'الجنس',
          male: 'ذكر',
          female: 'أنثى',
          submit: 'إرسال',
          pickImage: 'يرجى اختيار صورة للملف الشخصي',
          username: 'يرجى إدخال اسمك',
          selectGender: 'يرجى اختيار الجنس',
          selectBirthday: 'يرجى اختيار تاريخ الميلاد',
          userUnder18: 'يجب أن يكون عمرك 18 عامًا على الأقل',
          loadingResources: 'جارٍ تحميل الموارد...',
          registration: 'التسجيل',
          exitDialogTitle: 'هل أنت متأكد أنك تريد مغادرة التسجيل؟',
          exitDialogForgetPass:
              'هل أنت متأكد أنك تريد مغادرة إعادة تعيين كلمة المرور؟',
          thinkAgain: 'فكر مرة أخرى',
          giveUpRegistering: 'التخلي عن التسجيل',
          giveUpReset: 'التخلي عن إعادة التعيين',
          passwordTooShort: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
          notRegisteredYet: 'لم تسجل بعد؟',
          registerNow: 'سجل الآن',
          success: 'نجاح',
          next: 'التالي',
          updateDesc: 'يتوفر إصدار جديد. يرجى تحديث التطبيق.',
        },
      };
}
