import 'package:flutter/material.dart';

class ProfileLocalizations {
  const ProfileLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static ProfileLocalizations of(BuildContext context) =>
      ProfileLocalizations._(Localizations.localeOf(context));

  String get email => _isAr ? 'البريد الإلكتروني' : 'Email';
  String get password => _isAr ? 'كلمة المرور' : 'Password';
  String get forgotPassword => _isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get forgotPasswordHint => _isAr
      ? 'أدخل بريدك الإلكتروني لاستلام رابط إعادة تعيين كلمة المرور.'
      : 'Enter your email to receive a password reset link.';
  String get sendResetLink => _isAr ? 'إرسال رابط الإعادة' : 'Send Reset Link';
  String get resetLinkSent => _isAr ? 'تم إرسال رابط الإعادة.' : 'Reset link sent.';
  String get resetLinkFailed => _isAr ? 'فشل إرسال رابط الإعادة.' : 'Failed to send reset link.';
  String get loginSubtitle => _isAr
      ? 'مستعد لمواصلة رحلتك؟\nطريقك هنا.'
      : 'Ready to continue your journey?\nYour path is right here.';
  String get enterEmail => _isAr ? 'أدخل البريد الإلكتروني' : 'Enter email';
  String get enterPassword => _isAr ? 'أدخل كلمة المرور' : 'Enter password';
  String get passwordResetComingSoon => _isAr ? 'إعادة تعيين كلمة المرور قريباً' : 'Password reset coming soon';
  String get orDivider => _isAr ? 'أو' : 'OR';
  String get dontHaveAccount => _isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ";
  String get backButton => _isAr ? 'رجوع' : 'Back';
  String get createYourAccount => _isAr ? 'إنشاء حسابك' : 'Create Your Account';
  String get signupSubtitle => _isAr
      ? 'نحن هنا لمساعدتك على بلوغ قمم الصيد.\nهل أنت مستعد؟'
      : "We're here to help you reach the peaks\nof fishing. Are you ready?";
  String get firstName => _isAr ? 'الاسم الأول' : 'First name';
  String get lastName => _isAr ? 'اسم العائلة' : 'Last name';
  String get usernameField => _isAr ? 'اسم المستخدم' : 'Username';
  String get confirmPasswordField => _isAr ? 'تأكيد كلمة المرور' : 'Confirm password';
  String get getStarted => _isAr ? 'ابدأ الآن' : 'Get Started';
  String get alreadyHaveAccount => _isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ';
  String get registrationSuccessful => _isAr ? 'تم التسجيل بنجاح!' : 'Registration successful!';
  String get validationEnterName => _isAr ? 'يرجى إدخال اسمك' : 'Please enter your name';
  String get validationNameTooShort => _isAr ? 'يجب أن يكون الاسم حرفين على الأقل' : 'Name must be at least 2 characters';
  String get validationEnterEmail => _isAr ? 'يرجى إدخال بريدك الإلكتروني' : 'Please enter your email';
  String get validationInvalidEmail => _isAr ? 'يرجى إدخال بريد إلكتروني صحيح' : 'Please enter a valid email address';
  String get validationEnterPassword => _isAr ? 'يرجى إدخال كلمة المرور' : 'Please enter a password';
  String get validationPasswordTooShort => _isAr ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل' : 'Password must be at least 6 characters';
  String get validationEnterUsername => _isAr ? 'يرجى إدخال اسم المستخدم' : 'Please enter a username';
  String get validationUsernameTooShort => _isAr ? 'يجب أن يكون اسم المستخدم 3 أحرف على الأقل' : 'Username must be at least 3 characters';
  String get validationUsernameTooLong => _isAr ? 'يجب أن يكون اسم المستخدم أقل من 20 حرفاً' : 'Username must be less than 20 characters';
  String get validationUsernameInvalidChars => _isAr
      ? 'اسم المستخدم يمكن أن يحتوي على حروف وأرقام وشرطة سفلية فقط'
      : 'Username can only contain letters, numbers, and underscores';
  String get validationConfirmPassword => _isAr ? 'يرجى تأكيد كلمة المرور' : 'Please confirm your password';
  String get validationPasswordsNoMatch => _isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get profile => _isAr ? 'الملف الشخصي' : 'Profile';
  String get editProfile => _isAr ? 'تعديل الملف' : 'Edit Profile';
  String get guestUser => _isAr ? 'مستخدم ضيف' : 'Guest User';
  String get guestAccount => _isAr ? 'حساب ضيف' : 'Guest Account';
  String get contactInformation => _isAr ? 'معلومات التواصل' : 'Contact Information';
  String get username => _isAr ? 'اسم المستخدم' : 'Username';
  String get accountStatus => _isAr ? 'حالة الحساب' : 'Account Status';
  String get guestBannerMessage => _isAr
      ? 'سجّل دخولك للوصول إلى ملفك الشخصي الكامل وميزات البيع.'
      : 'Sign in to access your full profile and seller features.';
  String get privacyPolicy => _isAr ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get gotIt => _isAr ? 'حسناً' : 'Got it';
  String get policyDataCollection => _isAr ? 'جمع البيانات' : 'Data Collection';
  String get policyDataCollectionBody => _isAr
      ? 'تجمع بحار بيانات الموقع وسجلات الصيد ومعلومات الحساب فقط لتقديم خدمات مساعدة الصيد. نحن لا نبيع بياناتك لأطراف ثالثة.'
      : 'Bahaar collects location data, catch logs, and account information solely to provide fishing assistance services. We do not sell your data to third parties.';
  String get policyLocation => _isAr ? 'استخدام الموقع' : 'Location Usage';
  String get policyLocationBody => _isAr
      ? 'تُستخدم بيانات الموقع للتنبؤات الجوية وخرائط الصيد وميزات الملاحة. لا يتم تخزين الموقع بعد الجلسة النشطة إلا إذا قمت بحفظ سجل.'
      : 'Location data is used for weather forecasts, fishing maps, and navigation features. Location is never stored beyond your active session unless you explicitly save a log.';
  String get policyFishRecognition => _isAr ? 'التعرف على الأسماك' : 'Fish Recognition';
  String get policyFishRecognitionBody => _isAr
      ? 'تتم معالجة الصور المقدمة لتحديد الأسماك محلياً على الجهاز باستخدام TensorFlow Lite. لا يتم رفع الصور إلى أي خادم.'
      : 'Images submitted for fish identification are processed locally on-device using TensorFlow Lite. Images are not uploaded to any server.';
  String get policyAuthentication => _isAr ? 'الحساب والمصادقة' : 'Account & Authentication';
  String get policyAuthenticationBody => _isAr
      ? 'تتم المصادقة بشكل آمن عبر Firebase. لا يتم تخزين كلمات المرور بنص عادي. جلسات الضيف مجهولة ولا تحتوي على معلومات شخصية.'
      : 'Authentication is handled securely through Firebase. Passwords are never stored in plain text. Guest sessions are anonymous and contain no personally identifiable information.';
  String get policyRetention => _isAr ? 'الاحتفاظ بالبيانات' : 'Data Retention';
  String get policyRetentionBody => _isAr
      ? 'يتم تخزين سجلات الصيد وبيانات حسابك في حساب Firebase الشخصي الخاص بك. يمكنك حذف بياناتك في أي وقت.'
      : 'Your fishing logs and account data are stored in your personal Firebase account. You may delete your data at any time by contacting support or deleting your account.';
  String get policyContactSection => _isAr ? 'التواصل' : 'Contact';
  String get policyContactSectionBody => _isAr
      ? 'للاستفسارات المتعلقة بالخصوصية، يرجى التواصل مع فريق تطوير بحار عبر قناة دعم التطبيق.'
      : 'For privacy-related inquiries, please contact the Bahaar development team through the app support channel.';
  String get yourName => _isAr ? 'اسمك' : 'Your Name';
  String get phoneNumber => _isAr ? 'رقم الهاتف' : 'Phone Number';
  String get deliveryLocationOptional => _isAr ? 'موقع التوصيل (اختياري)' : 'Delivery Location (optional)';
  String get pleaseEnterYourName => _isAr ? 'يرجى إدخال اسمك' : 'Please enter your name';
  String get pleaseEnterPhoneNumber => _isAr ? 'يرجى إدخال رقم هاتفك' : 'Please enter your phone number';

  // Auth screen helpers
  String get cancel => _isAr ? 'إلغاء' : 'Cancel';
  String get signIn => _isAr ? 'تسجيل الدخول' : 'Sign In';
  String get signUp => _isAr ? 'إنشاء حساب' : 'Sign Up';
  String get logIn => _isAr ? 'تسجيل الدخول' : 'Log In';
  String get continueAsGuest => _isAr ? 'المتابعة كضيف' : 'Continue as Guest';
  String get name => _isAr ? 'الاسم' : 'Name';
  String get phone => _isAr ? 'الهاتف' : 'Phone';
  String get location => _isAr ? 'الموقع' : 'Location';
  String get saveChanges => _isAr ? 'حفظ التغييرات' : 'Save Changes';
  String get save => _isAr ? 'حفظ' : 'Save';
  String get account => _isAr ? 'الحساب' : 'Account';
  String get security => _isAr ? 'الأمان' : 'Security';
  String get changePassword => _isAr ? 'تغيير كلمة المرور' : 'Change Password';
}
