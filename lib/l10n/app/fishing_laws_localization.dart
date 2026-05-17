import 'package:flutter/material.dart';

class FishingLawsLocalizations {
  const FishingLawsLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static FishingLawsLocalizations of(BuildContext context) =>
      FishingLawsLocalizations._(Localizations.localeOf(context));

  bool get isAr => _isAr;

  // ── Header ────────────────────────────────────────────────────────────────
  String get screenTitle => _isAr ? 'قوانين الصيد' : 'Fishing Laws';
  String get screenSubtitle =>
      _isAr ? 'دليل شامل ومحدّث · 2025–2026' : 'Complete Guide · 2025–2026';

  // ── Info Banner ───────────────────────────────────────────────────────────
  String get infoBanner => _isAr
      ? 'القوانين قابلة للتحديث. يُنصح بالتحقق عبر بوابة bahrain.bh للحصول على أحدث الإصدارات.'
      : 'Laws are subject to updates. Always verify via bahrain.bh for the latest versions.';

  // ── Quick Stats ───────────────────────────────────────────────────────────
  String get statLawsValue => '5';
  String get statLawsLabel => _isAr ? 'قوانين' : 'Key Laws';

  String get statViolationsValue => '7';
  String get statViolationsLabel => _isAr ? 'مخالفات' : 'Violations';

  String get statSpeciesValue => '18';
  String get statSpeciesLabel => _isAr ? 'نوع محمي' : 'Protected\nSpecies';

  String get statShrimpValue => _isAr ? '3' : '3mo';
  String get statShrimpLabel => _isAr ? 'أشهر حظر' : 'Shrimp Ban';

  // ── Section Titles ────────────────────────────────────────────────────────
  String get section1Title =>
      _isAr ? '1. الإطار القانوني الأساسي' : '1. Legal Framework';
  String get section2Title =>
      _isAr ? '2. أنواع تراخيص الصيد والشروط' : '2. Fishing Licenses & Requirements';
  String get section3Title => _isAr
      ? '3. العقوبات والمخالفات (القانون رقم 14 لسنة 2025)'
      : '3. Violations & Penalties (Law No. 14 of 2025)';
  String get section4Title =>
      _isAr ? '4. المناطق المسموح والممنوع فيها الصيد' : '4. Permitted & Restricted Fishing Areas';
  String get section5Title =>
      _isAr ? '5. مواسم الحظر والأنواع المحظورة' : '5. Closed Seasons & Prohibited Species';
  String get section6Title =>
      _isAr ? '6. نصائح عملية للمستخدمين' : '6. Practical Tips';

  // ── Section 1 – Legal Framework ───────────────────────────────────────────
  String get legalFrameworkBody => _isAr
      ? 'يستند تنظيم الصيد في البحرين إلى المرسوم بقانون رقم (20) لسنة 2002 بشأن تنظيم صيد واستغلال وحماية الثروة البحرية، والذي خضع لعدة تعديلات كان آخرها في عام 2025.'
      : 'Fishing in Bahrain is governed by Legislative Decree No. (20) of 2002 on the Regulation, Exploitation, and Protection of Marine Resources, amended most recently in 2025.';

  String get keyLawsSubHeader =>
      _isAr ? 'أهم القوانين والتعديلات الحديثة:' : 'Key Laws & Recent Amendments:';

  String get decree20Bold =>
      _isAr ? 'المرسوم بقانون رقم (20) لسنة 2002:' : 'Legislative Decree No. 20 of 2002:';
  String get decree20Text => _isAr
      ? ' القانون الأم الذي يحدد الأحكام الرئيسية للتراخيص، وطرق الصيد، والمناطق المحظورة، والعقوبات.'
      : ' The parent law defining licensing, fishing methods, prohibited areas, and penalties.';

  String get law14Bold =>
      _isAr ? 'القانون رقم (14) لسنة 2025:' : 'Law No. 14 of 2025:';
  String get law14Text => _isAr
      ? ' أحدث تعديل على المادة (33) من القانون الأم، والذي شدد العقوبات بشكل كبير على مخالفات الصيد.'
      : ' Latest amendment to Article 33, significantly increasing penalties for fishing violations.';

  String get decision4Bold =>
      _isAr ? 'القرار رقم (4) لسنة 2025:' : 'Decision No. 4 of 2025:';
  String get decision4Text => _isAr
      ? ' الخاص بتنظيم تراخيص الصيادين البحريين لمزاولة الصيد التجاري.'
      : ' Regulates commercial fishing licenses for Bahraini fishermen.';

  String get decision6Bold =>
      _isAr ? 'القرار رقم (6) لسنة 2025:' : 'Decision No. 6 of 2025:';
  String get decision6Text => _isAr
      ? ' الخاص بتنظيم الصيد باستخدام المصائد (القراقير) والشباك وخيوط الصيد.'
      : ' Regulates fishing with traps (fish pots), nets, and lines.';

  String get decree3Bold =>
      _isAr ? 'المرسوم رقم (3) لسنة 2025:' : 'Decree No. 3 of 2025:';
  String get decree3Text => _isAr
      ? ' الصادر عن المجلس الأعلى للبيئة، يمنع صيد وتداول 18 نوعاً من صغار الأسماك والقشريات.'
      : ' Issued by the Supreme Council for Environment; bans the catching and trading of 18 species of juvenile fish and crustaceans.';

  // ── Section 2 – Licenses ──────────────────────────────────────────────────
  String get licenseIntroBody => _isAr
      ? 'لا يُسمح لأي شخص بمزاولة الصيد في المياه الإقليمية البحرينية دون الحصول على ترخيص من الجهة المختصة (الإدارة العامة للموارد البحرية).'
      : "No person may fish in Bahrain's territorial waters without a valid license from the General Directorate of Marine Resources.";

  List<String> get licenseTableHeaders => _isAr
      ? ['نوع الترخيص', 'الفئة', 'الصلاحية', 'الرسوم']
      : ['License Type', 'Target Group', 'Validity', 'Approx. Fee'];

  List<List<String>> get licenseTableRows => _isAr
      ? [
          ['ترخيص الهواة', 'مواطنون ومقيمون', 'سنوي / مؤقت', '10–15 د.ب'],
          ['ترخيص تجاري', 'شركات وأفراد', 'سنوي', '50–100 د.ب'],
        ]
      : [
          ['Recreational', 'Citizens & residents', 'Annual / Temp.', 'BD 10–15'],
          ['Commercial', 'Companies & individuals', 'Annual', 'BD 50–100'],
        ];

  String get requiredDocsSubHeader =>
      _isAr ? 'المستندات المطلوبة للتقديم:' : 'Required Documents:';

  String get doc1 => _isAr
      ? 'نموذج طلب مكتمل (متاح عبر بوابة bahrain.bh).'
      : 'Completed application form (via bahrain.bh portal).';
  String get doc2 => _isAr
      ? 'صورة عن جواز السفر ساري المفعول (مع الإقامة للمقيمين).'
      : 'Valid passport copy (with residency permit for expatriates).';
  String get doc3 =>
      _isAr ? 'صورة عن البطاقة الشخصية للمواطنين.' : 'National ID copy (for citizens).';
  String get doc4 =>
      _isAr ? 'إثبات عنوان (مثل فاتورة كهرباء حديثة).' : 'Proof of address (recent utility bill).';
  String get doc5 =>
      _isAr ? 'صورتان شخصيتان حديثتان.' : 'Two recent passport-size photographs.';
  String get doc6 => _isAr
      ? 'شهادة طبية تثبت اللياقة البدنية (تُطلب أحياناً للصيد التجاري).'
      : 'Medical fitness certificate (sometimes required for commercial fishing).';
  String get doc7 =>
      _isAr ? 'تسجيل القارب (للصيد التجاري).' : 'Vessel registration (for commercial fishing).';

  String get licenseWarning => _isAr
      ? 'ملاحظة: يُمنع على غير مواطني الدولة ممارسة الصيد التجاري، بينما يُسمح لهم بالصيد بهواية بشرط الحصول على الترخيص اللازم.'
      : 'Note: Non-Bahraini nationals are prohibited from commercial fishing. Recreational fishing is permitted with the appropriate license.';

  // ── Section 3 – Penalties ─────────────────────────────────────────────────
  List<String> get penaltiesTableHeaders =>
      _isAr ? ['المخالفة', 'العقوبة'] : ['Violation', 'Penalty'];

  List<List<String>> get penaltiesTableRows => _isAr
      ? [
          ['إلقاء النفايات البحرية (م. 18)', 'سجن ≥ سنة + غرامة 1,000–10,000 د.ب'],
          ['استخدام متفجرات/سموم (م. 23)', 'سجن ≥ 6 أشهر + غرامة 30,000–100,000 د.ب'],
          ['إنشاء مزارع دون ترخيص (م. 21)', 'سجن + غرامة 1,000–5,000 د.ب'],
          ['الصيد دون ترخيص (م. 27)', 'سجن + غرامة 500–3,000 د.ب'],
          ['حيازة شباك غير مرخصة (م. 20)', 'سجن + غرامة 500–3,000 د.ب'],
          ['صيد أسماك صغيرة/سلاحف (م. 19)', 'سجن + غرامة 500–3,000 د.ب'],
          ['رفض إبراز الرخصة (م. 28)', 'سجن + غرامة 100–2,000 د.ب'],
        ]
      : [
          ['Dumping waste in marine environment (Art. 18)', 'Prison ≥ 1 yr + BD 1,000–10,000 fine'],
          ['Use of explosives / poisons (Art. 23)', 'Prison ≥ 6 months + BD 30,000–100,000 fine'],
          ['Unlicensed fish farm / enclosure (Art. 21)', 'Prison + BD 1,000–5,000 fine'],
          ['Fishing without a license (Art. 27)', 'Prison + BD 500–3,000 fine'],
          ['Possessing unlicensed gear (Art. 20)', 'Prison + BD 500–3,000 fine'],
          ['Catching juvenile fish / turtles (Art. 19)', 'Prison + BD 500–3,000 fine'],
          ['Refusing to show license (Art. 28)', 'Prison + BD 100–2,000 fine'],
        ];

  String get penaltiesWarning => _isAr
      ? 'تتضاعف الغرامة في حال تكرار المخالفة خلال سنة من تاريخ الانتهاء من تنفيذ العقوبة السابقة.'
      : 'Fines double for repeat offences committed within one year of completing a previous sentence.';

  // ── Section 4 – Fishing Areas ─────────────────────────────────────────────
  String get openAreasSubHeader =>
      _isAr ? 'المناطق المتاحة لهواة الصيد:' : 'Areas Open to Recreational Fishing:';

  String get openArea1 =>
      _isAr ? 'شواطئ الحدائق العامة المخصصة (مثل شاطئ الجزائر).' : 'Public park beaches (e.g. Al-Jazayir Beach).';
  String get openArea2 => _isAr
      ? 'الأرصفة الحضرية (مثل كورنيش شمال المنامة ورصيف المحرق).'
      : 'Urban waterfronts (e.g. North Manama Corniche, Muharraq Pier).';
  String get openArea3 => _isAr
      ? 'شواطئ المناطق السكنية بشرط الالتزام بالعلامات الإرشادية.'
      : 'Residential area beaches — observe all posted signage.';

  String get restrictedAreasSubHeader =>
      _isAr ? 'المناطق المنظمة والخاصة:' : 'Regulated & Restricted Areas:';

  String get buDaiyaBold =>
      _isAr ? 'الساحل الشمالي الغربي (بودعيا):' : 'North-West Coast (Bu Daiya):';
  String get buDaiyaText => _isAr
      ? ' متاح للجميع مع وجود حصص محددة للأنواع المهددة.'
      : ' Open to all with species-specific quotas for threatened stocks.';

  String get hawarBold => _isAr ? 'جزر حوار:' : 'Hawar Islands:';
  String get hawarText => _isAr
      ? ' شديدة التنظيم، الوصول للبحث العلمي أو بتصاريح خاصة نظراً لكونها محمية طبيعية.'
      : ' Strictly regulated; access is limited to scientific research or with special permits — a protected nature reserve.';

  String get portAreaBold => _isAr ? 'منطقة الميناء (المنامة):' : 'Port Area (Manama):';
  String get portAreaText => _isAr
      ? ' تخضع للرقابة وغالباً محجوزة للصيد التجاري.'
      : ' Under surveillance; generally reserved for commercial fishing.';

  // ── Section 5 – Closed Seasons ────────────────────────────────────────────
  String get seasonalClosuresSubHeader =>
      _isAr ? 'فترات الإغلاق الموسمي:' : 'Seasonal Closures:';

  String get shrimpBold => _isAr ? 'الجمبري:' : 'Shrimp:';
  String get shrimpText => _isAr
      ? ' يُمنع صيده تماماً خلال مايو ويونيو ويوليو (1 مايو – 31 يوليو) لحماية موسم التكاثر.'
      : ' Fishing completely banned during May, June, and July (1 May – 31 July) to protect the breeding season.';

  String get hamourBold => _isAr ? 'الهامور، الشعري، الصافي، والدنيس:' : "Hamour, Sha'ari, Safi, and Deinis:";
  String get hamourText => _isAr
      ? ' تُعلن الجهات المختصة دورياً عن فترات حظر موسمية. يجب متابعة الإعلانات الرسمية.'
      : ' Periodic seasonal bans announced by the Supreme Council for the Environment. Monitor official announcements.';

  String get prohibitedSpeciesSubHeader =>
      _isAr ? 'الأنواع المحظورة صيداً وتداولاً:' : 'Prohibited Species (Catching & Trading):';

  String get juvenileFishBold => _isAr ? 'صغار الأسماك:' : 'Juvenile fish:';
  String get juvenileFishText => _isAr
      ? ' بموجب المرسوم رقم (3) لسنة 2025، يُمنع صيد أو بيع 18 نوعاً لا يبلغ طولها الحد القانوني؛ يجب إعادتها للبحر فور صيدها.'
      : ' Decree No. 3 of 2025 prohibits catching, selling, or trading 18 species below the legal minimum size — they must be returned to the sea immediately.';

  String get endangeredBold => _isAr ? 'الأنواع المهددة بالانقراض:' : 'Endangered species:';
  String get endangeredText => _isAr
      ? ' أبقار البحر (الدوجونج)، السلاحف البحرية، وأسماك القرش الساحلية.'
      : ' Dugongs, sea turtles, and coastal sharks are fully protected.';

  String get prohibitedMethodsBold => _isAr ? 'طرق الصيد المحظورة:' : 'Prohibited methods:';
  String get prohibitedMethodsText => _isAr
      ? ' شباك الجرافة في المناطق الحساسة، والمتفجرات والسموم في كل الأحوال.'
      : ' Trawl nets in sensitive areas; explosives and poisons under all circumstances.';

  // ── Section 6 – Practical Tips ────────────────────────────────────────────
  String get tip1 => _isAr
      ? 'احمل الترخيص دائماً — قد تواجه تفتيشاً مفاجئاً.'
      : 'Always carry your fishing license — inspections can occur at any time.';
  String get tip2 => _isAr
      ? 'استخدم الأدوات القانونية فقط — تأكد من أن شباكك وقراقيرك مرخصة.'
      : 'Use only legal equipment — ensure your nets and fish pots are properly licensed.';
  String get tip3 => _isAr
      ? 'احتفظ بجدول الأحجام المسموح بها للأسماك لمراجعتها قبل الاحتفاظ بأي صيد.'
      : 'Keep a copy of the minimum size chart and verify each catch before keeping it.';
  String get tip4 => _isAr
      ? 'لأي استفسار راجع الإدارة العامة للموارد البحرية عبر bahrain.bh أو وزارة الأشغال وشؤون البلديات والتخطيط العمراني.'
      : 'For enquiries, contact the General Directorate of Marine Resources via bahrain.bh or the Ministry of Works, Municipalities Affairs, and Urban Planning.';
}
