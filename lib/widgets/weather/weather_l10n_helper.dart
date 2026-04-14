import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Wraps [AppLocalizations] with weather-specific locale helpers and
/// translation maps, so individual weather widgets stay free of boilerplate.
class WeatherL10nHelper {
  final AppLocalizations l10n;
  const WeatherL10nHelper(this.l10n);

  // ── Translation maps ────────────────────────────────────────────────────────

  static const Map<String, String> _cityArabic = {
    'manama': 'المنامة',
    'muharraq': 'المحرق',
    'riffa': 'الرفاع',
    'isa town': 'مدينة عيسى',
    'hamad town': 'مدينة حمد',
    'sitra': 'سترة',
    'budaiya': 'البديع',
    'jidhafs': 'جدحفص',
    'jidd hafs': 'جدحفص',
    'hidd': 'الحد',
    'tubli': 'توبلي',
    'sanabis': 'السنابس',
    'janabiyah': 'الجنبية',
    'aali': 'عالي',
    'zallaq': 'الزلاق',
    'nuwaidrat': 'نويدرات',
    'diraz': 'دراز',
    'barbar': 'بربار',
    'bilad al qadeem': 'بلاد القديم',
    'sar': 'سار',
    'bani jamra': 'بني جمرة',
    'karbabad': 'كرباباد',
    'malkiya': 'المالكية',
    'jasra': 'الجسرة',
    'shahrakan': 'شهركان',
    'al malikiyah': 'المالكية',
    'bahrain': 'البحرين',
    'east riffa': 'الرفاع الشرقي',
    'west riffa': 'الرفاع الغربي',
    'northern city': 'المدينة الشمالية',
    'southern city': 'المدينة الجنوبية',
    'manamah': 'المنامة',
    'al muharraq': 'المحرق',
    'al hidd': 'الحد',
    'al janabiyah': 'الجنبية',
    'al budaiya': 'البديع',
    'al sitra': 'سترة',
    'al aali': 'عالي',
    'qudaibiya': 'قضيبية',
    'adliya': 'العدلية',
    'hoora': 'الحورة',
    'um al hassam': 'أم الحصم',
    'mahooz': 'المحوز',
    'segaya': 'سيجيئة',
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

  bool get isArabic => l10n.localeName == 'ar';

  /// Returns the city name translated to Arabic when locale is Arabic.
  String cityName(String name) =>
      isArabic ? (_cityArabic[name.toLowerCase()] ?? name) : name;

  /// Converts ASCII digits to Arabic-Indic numerals when locale is Arabic.
  String n(dynamic value) {
    final str = value.toString();
    if (!isArabic) return str;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return str.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => digits[int.parse(m.group(0)!)]);
  }

  /// Translates WeatherAPI condition text when locale is Arabic.
  String conditionText(String text) =>
      isArabic ? (_conditionArabic[text.toLowerCase()] ?? text) : text;

  /// Translates moon phase text when locale is Arabic.
  String moonPhase(String phase) =>
      isArabic ? (_moonPhaseArabic[phase.toLowerCase()] ?? phase) : phase;

  /// Converts "06:30 AM" / "07:15 PM" to Arabic format when locale is Arabic.
  String formatTime(String time) {
    if (!isArabic) return time;
    final t = time
        .toUpperCase()
        .replaceAll(' AM', ' ص')
        .replaceAll(' PM', ' م');
    return n(t);
  }

  String get kmh => isArabic ? 'كم/س' : 'km/h';
  String get km => isArabic ? 'كم' : 'km';

  // ── Weather-specific text helpers ───────────────────────────────────────────

  String uvLevel(double uv) {
    if (uv <= 2) return l10n.uvLow;
    if (uv <= 5) return l10n.uvModerate;
    if (uv <= 7) return l10n.uvHigh;
    if (uv <= 10) return l10n.uvVeryHigh;
    return l10n.uvExtreme;
  }

  String feelsLikeDescription(double feelslike, double temp) {
    final diff = feelslike - temp;
    if (diff.abs() < 2) return l10n.feelsLikeSimilar;
    return diff > 0 ? l10n.feelsLikeWarmer : l10n.feelsLikeCooler;
  }

  String visibilityDescription(double vis) {
    if (vis >= 10) return l10n.visibilityClear;
    if (vis >= 5) return l10n.visibilityGood;
    if (vis >= 2) return l10n.uvModerate;
    return l10n.visibilityLow;
  }

  String dayName(int weekday) => [
        '',
        l10n.dayMon,
        l10n.dayTue,
        l10n.dayWed,
        l10n.dayThu,
        l10n.dayFri,
        l10n.daySat,
        l10n.daySun,
      ][weekday];

  IconData moonIcon(String phase) => switch (phase.toLowerCase()) {
        'new moon' => Icons.brightness_1_outlined,
        'full moon' => Icons.brightness_1,
        'first quarter' => Icons.brightness_2,
        'last quarter' => Icons.brightness_3,
        _ => Icons.nightlight_round,
      };
}
