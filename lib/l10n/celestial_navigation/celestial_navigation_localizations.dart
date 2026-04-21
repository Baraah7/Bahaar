import 'package:flutter/material.dart';

class CelestialNavigationLocalizations {
  const CelestialNavigationLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static CelestialNavigationLocalizations of(BuildContext context) =>
      CelestialNavigationLocalizations._(Localizations.localeOf(context));

  // ── Header ────────────────────────────────────────────────────────────────
  String get celestialNavigation => _isAr ? 'الملاحة الفلكية' : 'Celestial Navigation';
  String get starBasedPositionFixing => _isAr ? 'تحديد الموقع عبر النجوم' : 'Star-based position fixing';
  String get gettingGps    => _isAr ? 'جارٍ تحديد الموقع...' : 'Getting GPS...';
  String get gpsUnavailable => _isAr ? 'GPS غير متوفر' : 'GPS unavailable';
  String starsDetectedCount(int n) => _isAr ? '$n نجوم' : '$n stars';
  String get noScanYet     => _isAr ? 'لم يتم المسح بعد' : 'No scan yet';
  String get viewOnMap     => _isAr ? 'عرض على الخريطة' : 'View on Map';

  // ── Steps card ────────────────────────────────────────────────────────────
  String get howToUse => _isAr ? 'كيفية الاستخدام' : 'How to Use';

  List<List<String>> get steps => _isAr
      ? [
          ['اخرج في الليل',        'ابحث عن مكان بعيد عن أضواء المدينة مع رؤية واضحة للسماء'],
          ['أمسك الجهاز بثبات',   'أمسك هاتفك أفقيًا مع توجيه الكاميرا نحو الأعلى'],
          ['اضغط لبدء المسح',     'اضغط الزر أدناه لفتح الكاميرا وبدء الكشف'],
          ['ابقَ ثابتًا 5–10 ثوانٍ', 'حافظ على ثبات الجهاز بينما يكتشف النظام النجوم'],
          ['راجع النتائج',         'تحقق من عدد النجوم المكتشفة ودرجة الثقة أدناه'],
        ]
      : [
          ['Go outside at night',       'Find a spot away from city lights with a clear view of the sky'],
          ['Hold device steady',        'Hold your phone horizontally with the camera pointing upward'],
          ['Tap Start Sky Scan',        'Press the button below to open the camera and begin detection'],
          ['Stay still 5–10 seconds',   'Keep the device stable while the engine detects stars'],
          ['Review the results',        'Check the detected star count and confidence score below'],
        ];

  // ── Scanner card ─────────────────────────────────────────────────────────
  String get skyScanner        => _isAr ? 'ماسح السماء' : 'Sky Scanner';
  String confidencePct(String pct) => _isAr ? '$pct% دقة' : '$pct% confidence';
  String get scannerDescription =>
      _isAr
          ? 'وجّه كاميرتك نحو السماء الليلية لاكتشاف النجوم وحساب موقعك.'
          : 'Point your camera at the night sky to detect stars and calculate your position.';
  String get scanAgain    => _isAr ? 'مسح مجددًا' : 'Scan Again';
  String get startSkyScan => _isAr ? 'بدء مسح السماء' : 'Start Sky Scan';

  // ── Results card ──────────────────────────────────────────────────────────
  String get scanResults      => _isAr ? 'نتائج المسح'      : 'Scan Results';
  String get starsDetected    => _isAr ? 'النجوم المكتشفة'  : 'Stars detected';
  String get confidence       => _isAr ? 'الدقة'            : 'Confidence';
  String get imuDrift         => _isAr ? 'انجراف IMU'       : 'IMU drift';
  String get horizon          => _isAr ? 'الأفق'            : 'Horizon';
  String horizonDetectedAngle(String angle) =>
      _isAr ? 'مكتشف ($angle°)' : 'Detected ($angle°)';
  String get notDetected      => _isAr ? 'غير مكتشف'        : 'Not detected';
  String get identifiedStars  => _isAr ? 'النجوم المحددة'   : 'Identified Stars';

  // ── Spoofing banner ───────────────────────────────────────────────────────
  String get spoofingAlert =>
      _isAr
          ? '⚠ تحذير: تزوير GPS\nالموقع الفلكي يختلف عن GPS بأكثر من 2 ميل بحري. لا تعتمد على موقع GPS.'
          : '⚠ GPS SPOOFING ALERT\nCelestial fix diverges from GPS by > 2 NM. Do not rely on GPS position.';

  // ── Legacy ────────────────────────────────────────────────────────────────
  String get celestialAlmanac => _isAr ? 'التقويم الفلكي'  : 'Celestial Almanac';
  String get solarNoon        => _isAr ? 'الذروة الشمسية'  : 'Solar Noon';
}
