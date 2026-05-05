import 'package:flutter/material.dart';

class AppLocalization {
  const AppLocalization._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static AppLocalization of(BuildContext context) =>
      AppLocalization._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get appName => _isAr ? 'بـحّـــار' : 'Bahaar';
  String get cancel => _isAr ? 'إلغاء' : 'Cancel';
  String get confirm => _isAr ? 'تأكيد' : 'Confirm';
  String get tryAgain => _isAr ? 'حاول مرة أخرى' : 'Try Again';
  String get loading => _isAr ? 'جاري التحميل...' : 'Loading...';
  String get error => _isAr ? 'خطأ' : 'Error';
  String get success => _isAr ? 'نجاح' : 'Success';
  String get noDataAvailable => _isAr ? 'لا توجد بيانات' : 'No data available';
  String get close => _isAr ? 'إغلاق' : 'Close';
  String get ok => _isAr ? 'موافق' : 'OK';
  String get reset => _isAr ? 'إعادة تعيين' : 'Reset';
  String get save => _isAr ? 'حفظ' : 'Save';
  String get done => _isAr ? 'تم' : 'Done';
  String get delete => _isAr ? 'حذف' : 'Delete';
  String get welcomeToBahaar => _isAr ? 'مرحباً بك في بحار' : 'Welcome to Bahaar';
  String get fishingMap => _isAr ? 'الخريطة' : 'Map';
  String get fishingMapSubtitle => _isAr ? 'خريطة تفاعلية مع ألوان العمق' : 'Interactive map with depth colors';
  String get weather => _isAr ? 'الطقس' : 'Weather';
  String get weatherSubtitle => _isAr ? 'تحقق من طقس البحر' : 'Check marine weather';
  String get fishRecognition => _isAr ? 'التصنيف' : 'Discerment';
  String get fishRecognitionSubtitle => _isAr ? 'تعرف على أنواع الأسماك' : 'Identify fish species';
  String get marinerHarvest => _isAr ? 'حصاد البحار' : 'Mariner Harvest';
  String get marinerHarvestSubtitle => _isAr ? 'شراء وبيع الأسماك الطازجة' : 'Buy & sell fresh fish';
  String get marketplace => _isAr ? 'السوق' : 'Market';
  String get fishingLog => _isAr ? 'السجل' : 'Log';
  String get signOut => _isAr ? 'تسجيل الخروج' : 'Sign Out';
  String get signIn => _isAr ? 'تسجيل الدخول' : 'Sign In';
  String get signUp => _isAr ? 'إنشاء حساب' : 'Sign Up';
  String get logIn => _isAr ? 'تسجيل الدخول' : 'Log In';
  String get guest => _isAr ? 'ضيف' : 'Guest';
  String get signedIn => _isAr ? 'مسجل الدخول' : 'Signed in';
  String get guestMode => _isAr ? 'وضع الضيف' : 'Guest mode';
  String get areYouSureSignOut => _isAr ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to sign out?';
  String get continueAsGuest => _isAr ? 'المتابعة كضيف' : 'Continue as Guest';
  String get signInToSell => _isAr ? 'سجّل الدخول لبيع صيدك.' : 'Sign in to sell your catch.';
  String get loginRequired => _isAr ? 'تسجيل الدخول مطلوب' : 'Login Required';
  String get guestAccountLoginMessage => _isAr
      ? 'تحتاج إلى تسجيل الدخول لإتمام الطلب.\nحسابات الضيف لا يمكنها الشراء أو البيع.'
      : 'You need to sign in to place an order.\nGuest accounts cannot buy or sell fish.';
  String get guestAccountSellMessage => _isAr
      ? 'تحتاج إلى تسجيل الدخول لنشر عرض.\nحسابات الضيف لا يمكنها بيع الأسماك.'
      : 'You need to sign in to post a listing.\nGuest accounts cannot sell fish.';
  String get settings => _isAr ? 'الإعدادات' : 'Settings';
  String get language => _isAr ? 'اللغة' : 'Language';
  String get english => _isAr ? 'الإنجليزية' : 'English';
  String get arabic => _isAr ? 'العربية' : 'العربية';
  String get changeLanguage => _isAr ? 'تغيير اللغة' : 'Change Language';
  String get selectLanguage => _isAr ? 'اختر اللغة' : 'Select Language';
  String get account => _isAr ? 'الحساب' : 'Account';
  String get notifications => _isAr ? 'الإشعارات' : 'Notifications';
  String get about => _isAr ? 'حول التطبيق' : 'About';
  String get version => _isAr ? 'الإصدار' : 'Version';
  String get name => _isAr ? 'الاسم' : 'Name';
  String get phone => _isAr ? 'الهاتف' : 'Phone';
  String get location => _isAr ? 'الموقع' : 'Location';
  String get weight => _isAr ? 'الوزن' : 'Weight';
  String get kgUnit => _isAr ? 'كجم' : 'kg';
  String get phoneNumberCopied => _isAr ? 'تم نسخ رقم الهاتف' : 'Phone number copied';
  String get saveChanges => _isAr ? 'حفظ التغييرات' : 'Save Changes';

  // Profile strings used in settings
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

  // Emergency (used in main.dart menu)
  String get emergency => _isAr ? 'الطوارئ' : 'Emergency';

  // Celestial navigation
  String get celestialNavigation => _isAr ? 'الملاحة الفلكية' : 'Celestial Navigation';

  // Profile
  String get profile => _isAr ? 'الملف الشخصي' : 'Profile';
  String get guestUser => _isAr ? 'مستخدم ضيف' : 'Guest User';

  // Fishing laws
  String get fishingLaws => _isAr ? 'قوانين الصيد' : 'Fishing Laws';

  // Bottom nav
  String get otherTools => _isAr ? 'أدوات أخرى' : 'Other Tools';

  // About app popup
  String get aboutAppTitle => _isAr ? 'بـحّـــار' : 'Bahaar';
  String get aboutAppDescription => _isAr
      ? 'بحار هو تطبيق مساعدة صيد متكامل مصمم للصيادين في البحرين. يوفر خرائط صيد تفاعلية، تنبؤات جوية بحرية، التعرف على الأسماك بالذكاء الاصطناعي، سوقاً لبيع وشراء الأسماك الطازجة، تسجيل رحلات الصيد، وأدوات الملاحة الفلكية.'
      : 'Bahaar is a comprehensive fishing assistant app designed for fishermen in Bahrain. It offers interactive fishing maps, marine weather forecasts, AI-powered fish recognition, a marketplace to buy and sell fresh fish, fishing trip logging, and celestial navigation tools.';
}
