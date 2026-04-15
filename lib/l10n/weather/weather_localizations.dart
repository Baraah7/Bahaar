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
}
