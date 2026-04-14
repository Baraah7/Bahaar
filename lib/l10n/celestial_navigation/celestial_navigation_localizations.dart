import 'package:flutter/material.dart';

class CelestialNavigationLocalizations {
  const CelestialNavigationLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static CelestialNavigationLocalizations of(BuildContext context) =>
      CelestialNavigationLocalizations._(Localizations.localeOf(context));

  String get celestialNavigation => _isAr ? 'الملاحة الفلكية' : 'Celestial Nav';
  String get celestialAlmanac    => _isAr ? 'التقويم الفلكي'  : 'Celestial Almanac';
  String get solarNoon           => _isAr ? 'الذروة الشمسية' : 'Solar Noon';
}
