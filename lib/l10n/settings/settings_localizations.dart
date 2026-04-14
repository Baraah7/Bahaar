import 'package:flutter/material.dart';

class SettingsLocalizations {
  const SettingsLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static SettingsLocalizations of(BuildContext context) =>
      SettingsLocalizations._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get emergency => _isAr ? 'الطوارئ' : 'Emergency';
  String get emergencyComingSoon => _isAr ? 'ميزات الطوارئ قادمة قريباً.' : 'Emergency features are coming soon.';
  String get emergencyContacts => _isAr ? 'جهات اتصال الطوارئ' : 'Emergency Contacts';
  String get coastGuard => _isAr ? 'خفر السواحل' : 'Coast Guard';
  String get marineRescue => _isAr ? 'الإنقاذ البحري' : 'Marine Rescue';
  String get police => _isAr ? 'الشرطة' : 'Police';
  String get ambulance => _isAr ? 'الإسعاف' : 'Ambulance';
  String get fishingRules => _isAr ? 'قواعد الصيد' : 'Fishing Rules';
  String get sosLongPressHint => _isAr ? 'اضغط مطولاً 3 ثوانٍ لتفعيل SOS' : 'Long-press 3 seconds to activate SOS';
  String get emergencyChannelHint => _isAr ? 'قناة VHF للطوارئ 16' : 'Emergency VHF Channel 16';
  String get rule1Title => _isAr ? 'رخصة الصيد' : 'Fishing Licence';
  String get rule1Body => _isAr
      ? 'يجب على جميع الصيادين الحصول على رخصة صيد سارية صادرة عن وزارة الأشغال وشؤون البلديات والتخطيط العمراني.'
      : 'All fishers must hold a valid fishing licence issued by the Ministry of Works, Municipalities Affairs & Urban Planning.';
  String get rule2Title => _isAr ? 'المناطق المحمية' : 'Protected Areas';
  String get rule2Body => _isAr
      ? 'يُحظر الصيد بشكل صارم داخل المناطق البحرية المحمية والمناطق العسكرية المقيدة الموضحة على الخريطة.'
      : 'Fishing is strictly prohibited within designated marine protected areas and restricted military zones shown on the map.';
  String get rule3Title => _isAr ? 'المعدات' : 'Equipment';
  String get rule3Body => _isAr
      ? 'يُعد استخدام المتفجرات أو السموم أو الصدمات الكهربائية لاصطياد الأسماك أمرًا غير قانوني ويُعاقب عليه.'
      : 'Use of explosives, poisons, or electric shocks to catch fish is illegal and punishable by law.';
  String get rule4Title => _isAr ? 'الأنواع المحمية' : 'Protected Species';
  String get rule4Body => _isAr
      ? 'يُحظر اصطياد أو تداول أو حيازة الأنواع المحمية (السلحفاة الصفراء والدوجونج وحوت القرش).'
      : 'Catching, trading, or possessing protected species (hawksbill turtle, dugong, whale shark) is prohibited.';
  String get rule5Title => _isAr ? 'الصيد الليلي' : 'Night Fishing';
  String get rule5Body => _isAr
      ? 'يستلزم الصيد الليلي توفر أضواء ملاحة مناسبة وهو مقيد في بعض المناطق. تحقق من اللوائح المحلية.'
      : 'Night fishing requires proper navigation lights and is restricted in certain zones. Check local regulations.';
  String get rule6Title => _isAr ? 'سلامة السفينة' : 'Vessel Safety';
  String get rule6Body => _isAr
      ? 'سترات النجاة إلزامية لجميع الركاب. يجب أن تحمل السفن راديو VHF يعمل وشعلات إشارة.'
      : 'Life jackets are mandatory for all passengers. Vessels must carry a working VHF radio and flares.';
  String get phoneNumberCopied => _isAr ? 'تم نسخ رقم الهاتف' : 'Phone number copied';
}
