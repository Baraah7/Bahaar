import 'package:flutter/material.dart';

class WeatherLocalizations {
  const WeatherLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static WeatherLocalizations of(BuildContext context) =>
      WeatherLocalizations._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get weather => _isAr ? 'الطقس' : 'Weather';
  String get unableToLoadWeather => _isAr ? 'تعذر تحميل بيانات الطقس' : 'Unable to load weather';
  String get tryAgain => _isAr ? 'حاول مرة أخرى' : 'Try Again';
  String get noDataAvailable => _isAr ? 'لا توجد بيانات' : 'No data available';
  String get kmUnit => _isAr ? 'كم' : 'km';
  String get kmh => _isAr ? 'كم/س' : 'km/h';
  String get km => _isAr ? 'كم' : 'km';
  String get hourlyForecast => _isAr ? 'الـ 24 ساعة القادمة' : 'Next 24 Hours';
  String get dailyForecast => _isAr ? 'توقعات اليوم' : 'Day Forecast';
  String get wind => _isAr ? 'الرياح' : 'Wind';
  String get uvIndex => _isAr ? 'مؤشر الأشعة فوق البنفسجية' : 'UV Index';
  String get feelsLike => _isAr ? 'يبدو كأنه' : 'Feels Like';
  String get humidity => _isAr ? 'الرطوبة' : 'Humidity';
  String get visibility => _isAr ? 'الرؤية' : 'Visibility';
  String get sunrise => _isAr ? 'شروق الشمس' : 'Sunrise';
  String get sunset => _isAr ? 'غروب الشمس' : 'Sunset';
  String get moonrise => _isAr ? 'شروق القمر' : 'Moonrise';
  String get moonset => _isAr ? 'غروب القمر' : 'Moonset';
  String get celestialAlmanac => _isAr ? 'التقويم الفلكي' : 'Celestial Almanac';
  String get solarNoon => _isAr ? 'منتصف النهار الشمسي' : 'Solar Noon';
  String get weatherNow => _isAr ? 'الآن' : 'Now';
  String get weatherToday => _isAr ? 'اليوم' : 'Today';
  String get weatherGusts => _isAr ? 'هبوب حتى' : 'Gusts up to';
  String get weatherDewPoint => _isAr ? 'نقطة الندى' : 'Dew';
  String get weatherTodayTides => _isAr ? 'مد وجزر اليوم' : "Today's Tides";
  String get weatherTideUnavailable => _isAr ? 'بيانات المد غير متاحة' : 'Tide data unavailable';
  String get weatherHighTide => _isAr ? 'مد عالٍ' : 'High Tide';
  String get weatherLowTide => _isAr ? 'جزر منخفض' : 'Low Tide';
  String get illuminated => _isAr ? '٪ مضيء' : '% illuminated';
  String get uvLow => _isAr ? 'منخفض' : 'Low';
  String get uvModerate => _isAr ? 'معتدل' : 'Moderate';
  String get uvHigh => _isAr ? 'مرتفع' : 'High';
  String get uvVeryHigh => _isAr ? 'مرتفع جداً' : 'Very High';
  String get uvExtreme => _isAr ? 'شديد' : 'Extreme';
  String get visibilityClear => _isAr ? 'واضح' : 'Clear';
  String get visibilityGood => _isAr ? 'جيد' : 'Good';
  String get visibilityLow => _isAr ? 'منخفض' : 'Low';
  String get feelsLikeSimilar => _isAr ? 'مماثل للفعلي' : 'Similar to actual';
  String get feelsLikeWarmer => _isAr ? 'يبدو أدفأ' : 'Feels warmer';
  String get feelsLikeCooler => _isAr ? 'يبدو أبرد' : 'Feels cooler';
  String get dayMon => _isAr ? 'الإثنين' : 'Mon';
  String get dayTue => _isAr ? 'الثلاثاء' : 'Tue';
  String get dayWed => _isAr ? 'الأربعاء' : 'Wed';
  String get dayThu => _isAr ? 'الخميس' : 'Thu';
  String get dayFri => _isAr ? 'الجمعة' : 'Fri';
  String get daySat => _isAr ? 'السبت' : 'Sat';
  String get daySun => _isAr ? 'الأحد' : 'Sun';

    static const Map<String, String> cityArabic = {
    // ── Core names ──────────────────────────────────────────────────────────
    'manama': 'المنامة',
    'manamah': 'المنامة',
    'al manamah': 'المنامة',
    'muharraq': 'المحرق',
    'al muharraq': 'المحرق',
    'busaytin': 'البسيتين',
    'al busaytin': 'البسيتين',
    'riffa': 'الرفاع',
    'ar rifa': 'الرفاع',
    'east riffa': 'الرفاع الشرقي',
    'west riffa': 'الرفاع الغربي',
    'sitra': 'سترة',
    'sitrah': 'سترة',
    'al sitra': 'سترة',
    'hidd': 'الحد',
    'al hidd': 'الحد',
    'isa town': 'مدينة عيسى',
    'madinat isa': 'مدينة عيسى',
    'hamad town': 'مدينة حمد',
    'madinat hamad': 'مدينة حمد',
    'budaiya': 'البديع',
    'al budaiya': 'البديع',
    'jidhafs': 'جدحفص',
    'jidd hafs': 'جدحفص',
    'jidd al hafs': 'جدحفص',
    'tubli': 'توبلي',
    'tubali': 'توبلي',
    'sanabis': 'السنابس',
    'as sanabis': 'السنابس',
    'janabiyah': 'الجنبية',
    'al janabiyah': 'الجنبية',
    'aali': 'عالي',
    'al aali': 'عالي',
    'zallaq': 'الزلاق',
    'az zallaq': 'الزلاق',
    'nuwaidrat': 'نويدرات',
    'an nuwaidrat': 'نويدرات',
    'diraz': 'دراز',
    'barbar': 'بربار',
    'bilad al qadeem': 'بلاد القديم',
    'bilad al qadim': 'بلاد القديم',
    'sar': 'سار',
    'bani jamra': 'بني جمرة',
    'karbabad': 'كرباباد',
    'malkiya': 'المالكية',
    'al malikiyah': 'المالكية',
    'al malkiyah': 'المالكية',
    'jasra': 'الجسرة',
    'shahrakan': 'شهركان',
    'bahrain': 'البحرين',
    'northern city': 'المدينة الشمالية',
    'southern city': 'المدينة الجنوبية',
    'qudaibiya': 'قضيبية',
    'adliya': 'العدلية',
    'hoora': 'الحورة',
    'um al hassam': 'أم الحصم',
    'mahooz': 'المحوز',
    'segaya': 'سيجيئة',
    'al busaiteen': 'البسيتين',
    // ── Additional WeatherAPI variants ──────────────────────────────────────
    'manama city': 'المنامة',
    'kingdom of bahrain': 'البحرين',
    'al manamah city': 'المنامة',
    'juffair': 'الجفير',
    'al jufayr': 'الجفير',
    'seef': 'السيف',
    'as seef': 'السيف',
    'diplomatic area': 'المنطقة الدبلوماسية',
    'zinj': 'زنج',
    'az zinj': 'زنج',
    'exhibitions avenue': 'شارع المعارض',
    'umm al hassam': 'أم الحصم',
    'gudaibiya': 'قضيبية',
    'gudaibiyah': 'قضيبية',
  };

  
  static const Map<String, String> _conditionArabic = {
    'sunny': 'مشمس',
    'clear': 'صافٍ',
    'partly cloudy': 'غائم جزئياً',
    'cloudy': 'غائم',
    'overcast': 'ملبد بالغيوم',
    'mist': 'ضباب خفيف',
    'fog': 'ضباب',
    'freezing fog': 'ضباب متجمد',
    'haze': 'ضباب دخاني',
    'dust': 'غبار',
    'sand': 'رمال',
    'dust whirls': 'أعمدة غبار',
    'blowing dust': 'عواصف غبارية',
    'blowing sand': 'عواصف رملية',
    'sandstorm': 'عاصفة رملية',
    'dust storm': 'عاصفة ترابية',
    'patchy rain possible': 'أمطار متفرقة محتملة',
    'patchy snow possible': 'ثلوج متفرقة محتملة',
    'patchy sleet possible': 'زخات صقيع متفرقة',
    'patchy freezing drizzle possible': 'رذاذ متجمد متفرق',
    'thundery outbreaks possible': 'عواصف رعدية محتملة',
    'blowing snow': 'عواصف ثلجية',
    'blizzard': 'عاصفة ثلجية شديدة',
    'patchy light drizzle': 'رذاذ خفيف متفرق',
    'light drizzle': 'رذاذ خفيف',
    'freezing drizzle': 'رذاذ متجمد',
    'heavy freezing drizzle': 'رذاذ متجمد كثيف',
    'patchy light rain': 'أمطار خفيفة متفرقة',
    'light rain': 'أمطار خفيفة',
    'moderate rain at times': 'أمطار معتدلة أحياناً',
    'moderate rain': 'أمطار معتدلة',
    'heavy rain at times': 'أمطار غزيرة أحياناً',
    'heavy rain': 'أمطار غزيرة',
    'light freezing rain': 'مطر متجمد خفيف',
    'moderate or heavy freezing rain': 'مطر متجمد معتدل أو غزير',
    'light sleet': 'صقيع خفيف',
    'moderate or heavy sleet': 'صقيع معتدل أو غزير',
    'patchy light snow': 'ثلج خفيف متفرق',
    'light snow': 'ثلج خفيف',
    'patchy moderate snow': 'ثلج معتدل متفرق',
    'moderate snow': 'ثلج معتدل',
    'patchy heavy snow': 'ثلج كثيف متفرق',
    'heavy snow': 'ثلج كثيف',
    'ice pellets': 'حبات صقيع',
    'light rain shower': 'زخة مطر خفيفة',
    'moderate or heavy rain shower': 'زخة مطر معتدلة أو غزيرة',
    'torrential rain shower': 'زخة مطر غزيرة جداً',
    'light snow showers': 'زخات ثلج خفيفة',
    'moderate or heavy snow showers': 'زخات ثلج معتدلة أو غزيرة',
    'patchy light rain with thunder': 'أمطار خفيفة مع رعد',
    'moderate or heavy rain with thunder': 'أمطار معتدلة أو غزيرة مع رعد',
    'patchy light snow with thunder': 'ثلج خفيف مع رعد',
    'moderate or heavy snow with thunder': 'ثلج معتدل أو غزير مع رعد',
    'thunderstorm': 'عاصفة رعدية',
    'light thunderstorm': 'عاصفة رعدية خفيفة',
    'heavy thunderstorm': 'عاصفة رعدية شديدة',
  };

  static const Map<String, String> _moonPhaseArabic = {
    'new moon': 'محاق',
    'waxing crescent': 'هلال متصاعد',
    'first quarter': 'تربيع أول',
    'waxing gibbous': 'أحدب متصاعد',
    'full moon': 'بدر',
    'waning gibbous': 'أحدب متناقص',
    'last quarter': 'تربيع أخير',
    'waning crescent': 'هلال متناقص',
  };

  // ── Locale helpers ──────────────────────────────────────────────────────────


  /// Returns the city name translated to Arabic when locale is Arabic.
  String cityName(String name) {
    if (!_isAr) return name;
    final lower = name.toLowerCase();
    if (cityArabic.containsKey(lower)) return cityArabic[lower]!;
    final normalized = lower
        .replaceAll(RegExp(r'[āáàâä]'), 'a')
        .replaceAll(RegExp(r'[ūúùûü]'), 'u')
        .replaceAll(RegExp(r'[īíìîï]'), 'i')
        .replaceAll(RegExp(r'[ēéèêë]'), 'e')
        .replaceAll(RegExp(r'[ōóòôö]'), 'o')
        .replaceAll(RegExp(r"['\u2018\u2019\u02bc`]"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cityArabic[normalized] ?? name;
  }

  /// Converts ASCII digits to Arabic-Indic numerals when locale is Arabic.
  String n(dynamic value) {
    final str = value.toString();
    if (!_isAr) return str;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return str.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => digits[int.parse(m.group(0)!)]);
  }

  /// Translates WeatherAPI condition text when locale is Arabic.
  String conditionText(String text) =>
      _isAr ? (_conditionArabic[text.toLowerCase()] ?? text) : text;

  /// Translates moon phase text when locale is Arabic.
  String moonPhase(String phase) =>
      _isAr ? (_moonPhaseArabic[phase.toLowerCase()] ?? phase) : phase;

  /// Converts "06:30 AM" / "07:15 PM" to Arabic format when locale is Arabic.
  String formatTime(String time) {
    if (!_isAr) return time;
    final t = time
        .toUpperCase()
        .replaceAll(' AM', ' ص')
        .replaceAll(' PM', ' م');
    return n(t);
  }


  // ── Weather-specific text helpers ───────────────────────────────────────────

  String uvLevel(double uv) {
    if (uv <= 2) return uvLow;
    if (uv <= 5) return uvModerate;
    if (uv <= 7) return uvHigh;
    if (uv <= 10) return uvVeryHigh;
    return uvExtreme;
  }

  String feelsLikeDescription(double feelslike, double temp) {
    final diff = feelslike - temp;
    if (diff.abs() < 2) return feelsLikeSimilar;
    return diff > 0 ? feelsLikeWarmer : feelsLikeCooler;
  }

  String visibilityDescription(double vis) {
    if (vis >= 10) return visibilityClear;
    if (vis >= 5) return visibilityGood;
    if (vis >= 2) return uvModerate;
    return visibilityLow;
  }

  String dayName(int weekday) => [
        '',
        dayMon,
        dayTue,
        dayWed,
        dayThu,
        dayFri,
        daySat,
        daySun,
      ][weekday];

  IconData moonIcon(String phase) => switch (phase.toLowerCase()) {
        'new moon' => Icons.brightness_1_outlined,
        'full moon' => Icons.brightness_1,
        'first quarter' => Icons.brightness_2,
        'last quarter' => Icons.brightness_3,
        _ => Icons.nightlight_round,
      };
}
