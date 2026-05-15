import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bahaar/core/constants/app_colors.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class FishingLawsScreen extends StatelessWidget {
  const FishingLawsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 164,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Column(
                        crossAxisAlignment: isAr
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gavel_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'قوانين الصيد' : 'Fishing Laws',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isAr
                                ? 'دليل شامل ومحدّث · 2025–2026'
                                : 'Complete Guide · 2025–2026',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: isAr
                  ? const Directionality(
                      textDirection: TextDirection.rtl,
                      child: _ArabicLaws(),
                    )
                  : const _EnglishLaws(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Arabic Content ───────────────────────────────────────────────────────────

class _ArabicLaws extends StatelessWidget {
  const _ArabicLaws();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoBanner(
            message:
                'القوانين قابلة للتحديث. يُنصح بالتحقق عبر بوابة bahrain.bh للحصول على أحدث الإصدارات.',
            isRtl: true,
          ),
          SizedBox(height: 16),
          _QuickStatsRow(items: [
            _Stat('5', 'قوانين'),
            _Stat('7', 'مخالفات'),
            _Stat('18', 'نوع محمي'),
            _Stat('3', 'أشهر حظر'),
          ]),
          SizedBox(height: 20),

          // ── Section 1 ──
          _SectionCard(
            icon: Icons.balance_rounded,
            title: '1. الإطار القانوني الأساسي',
            children: [
              _BodyText(
                'يستند تنظيم الصيد في البحرين إلى المرسوم بقانون رقم (20) لسنة 2002 بشأن تنظيم صيد واستغلال وحماية الثروة البحرية، والذي خضع لعدة تعديلات كان آخرها في عام 2025.',
              ),
              SizedBox(height: 12),
              _SubHeader('أهم القوانين والتعديلات الحديثة:'),
              _BulletItem(
                bold: 'المرسوم بقانون رقم (20) لسنة 2002:',
                text:
                    ' القانون الأم الذي يحدد الأحكام الرئيسية للتراخيص، وطرق الصيد، والمناطق المحظورة، والعقوبات.',
              ),
              _BulletItem(
                bold: 'القانون رقم (14) لسنة 2025:',
                text:
                    ' أحدث تعديل على المادة (33) من القانون الأم، والذي شدد العقوبات بشكل كبير على مخالفات الصيد.',
              ),
              _BulletItem(
                bold: 'القرار رقم (4) لسنة 2025:',
                text:
                    ' الخاص بتنظيم تراخيص الصيادين البحريين لمزاولة الصيد التجاري.',
              ),
              _BulletItem(
                bold: 'القرار رقم (6) لسنة 2025:',
                text:
                    ' الخاص بتنظيم الصيد باستخدام المصائد (القراقير) والشباك وخيوط الصيد.',
              ),
              _BulletItem(
                bold: 'المرسوم رقم (3) لسنة 2025:',
                text:
                    ' الصادر عن المجلس الأعلى للبيئة، يمنع صيد وتداول 18 نوعاً من صغار الأسماك والقشريات.',
              ),
            ],
          ),

          // ── Section 2 ──
          _SectionCard(
            icon: Icons.badge_outlined,
            title: '2. أنواع تراخيص الصيد والشروط',
            children: [
              _BodyText(
                'لا يُسمح لأي شخص بمزاولة الصيد في المياه الإقليمية البحرينية دون الحصول على ترخيص من الجهة المختصة (الإدارة العامة للموارد البحرية).',
              ),
              SizedBox(height: 12),
              _LicenseTable(),
              SizedBox(height: 12),
              _SubHeader('المستندات المطلوبة للتقديم:'),
              _BulletItem(
                  text: 'نموذج طلب مكتمل (متاح عبر بوابة bahrain.bh).'),
              _BulletItem(
                  text:
                      'صورة عن جواز السفر ساري المفعول (مع الإقامة للمقيمين).'),
              _BulletItem(text: 'صورة عن البطاقة الشخصية للمواطنين.'),
              _BulletItem(
                  text: 'إثبات عنوان (مثل فاتورة كهرباء حديثة).'),
              _BulletItem(text: 'صورتان شخصيتان حديثتان.'),
              _BulletItem(
                  text:
                      'شهادة طبية تثبت اللياقة البدنية (تُطلب أحياناً للصيد التجاري).'),
              _BulletItem(text: 'تسجيل القارب (للصيد التجاري).'),
              SizedBox(height: 8),
              _WarningBox(
                'ملاحظة: يُمنع على غير مواطني الدولة ممارسة الصيد التجاري، بينما يُسمح لهم بالصيد بهواية بشرط الحصول على الترخيص اللازم.',
              ),
            ],
          ),

          // ── Section 3 ──
          _SectionCard(
            icon: Icons.report_problem_outlined,
            title: '3. العقوبات والمخالفات (القانون رقم 14 لسنة 2025)',
            children: [
              _PenaltiesTable(),
              SizedBox(height: 8),
              _WarningBox(
                'تتضاعف الغرامة في حال تكرار المخالفة خلال سنة من تاريخ الانتهاء من تنفيذ العقوبة السابقة.',
              ),
            ],
          ),

          // ── Section 4 ──
          _SectionCard(
            icon: Icons.map_outlined,
            title: '4. المناطق المسموح والممنوع فيها الصيد',
            children: [
              _SubHeader('المناطق المتاحة لهواة الصيد:'),
              _BulletItem(
                  text: 'شواطئ الحدائق العامة المخصصة (مثل شاطئ الجزائر).'),
              _BulletItem(
                  text:
                      'الأرصفة الحضرية (مثل كورنيش شمال المنامة ورصيف المحرق).'),
              _BulletItem(
                  text:
                      'شواطئ المناطق السكنية بشرط الالتزام بالعلامات الإرشادية.'),
              SizedBox(height: 8),
              _SubHeader('المناطق المنظمة والخاصة:'),
              _BulletItem(
                bold: 'الساحل الشمالي الغربي (بودعيا):',
                text: ' متاح للجميع مع وجود حصص محددة للأنواع المهددة.',
              ),
              _BulletItem(
                bold: 'جزر حوار:',
                text:
                    ' شديدة التنظيم، الوصول للبحث العلمي أو بتصاريح خاصة نظراً لكونها محمية طبيعية.',
              ),
              _BulletItem(
                bold: 'منطقة الميناء (المنامة):',
                text: ' تخضع للرقابة وغالباً محجوزة للصيد التجاري.',
              ),
            ],
          ),

          // ── Section 5 ──
          _SectionCard(
            icon: Icons.event_busy_rounded,
            title: '5. مواسم الحظر والأنواع المحظورة',
            children: [
              _SubHeader('فترات الإغلاق الموسمي:'),
              _BulletItem(
                bold: 'الجمبري:',
                text:
                    ' يُمنع صيده تماماً خلال مايو ويونيو ويوليو (1 مايو – 31 يوليو) لحماية موسم التكاثر.',
              ),
              _BulletItem(
                bold: 'الهامور، الشعري، الصافي، والدنيس:',
                text:
                    ' تُعلن الجهات المختصة دورياً عن فترات حظر موسمية. يجب متابعة الإعلانات الرسمية.',
              ),
              SizedBox(height: 8),
              _SubHeader('الأنواع المحظورة صيداً وتداولاً:'),
              _BulletItem(
                bold: 'صغار الأسماك:',
                text:
                    ' بموجب المرسوم رقم (3) لسنة 2025، يُمنع صيد أو بيع 18 نوعاً لا يبلغ طولها الحد القانوني؛ يجب إعادتها للبحر فور صيدها.',
              ),
              _BulletItem(
                bold: 'الأنواع المهددة بالانقراض:',
                text:
                    ' أبقار البحر (الدوجونج)، السلاحف البحرية، وأسماك القرش الساحلية.',
              ),
              _BulletItem(
                bold: 'طرق الصيد المحظورة:',
                text:
                    ' شباك الجرافة في المناطق الحساسة، والمتفجرات والسموم في كل الأحوال.',
              ),
            ],
          ),

          // ── Section 6 ──
          _SectionCard(
            icon: Icons.lightbulb_outline_rounded,
            title: '6. نصائح عملية للمستخدمين',
            children: [
              _TipItem(
                  number: 1,
                  text: 'احمل الترخيص دائماً — قد تواجه تفتيشاً مفاجئاً.'),
              _TipItem(
                  number: 2,
                  text:
                      'استخدم الأدوات القانونية فقط — تأكد من أن شباكك وقراقيرك مرخصة.'),
              _TipItem(
                  number: 3,
                  text:
                      'احتفظ بجدول الأحجام المسموح بها للأسماك لمراجعتها قبل الاحتفاظ بأي صيد.'),
              _TipItem(
                  number: 4,
                  text:
                      'لأي استفسار راجع الإدارة العامة للموارد البحرية عبر bahrain.bh أو وزارة الأشغال وشؤون البلديات والتخطيط العمراني.'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── English Content ──────────────────────────────────────────────────────────

class _EnglishLaws extends StatelessWidget {
  const _EnglishLaws();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoBanner(
            message:
                'Laws are subject to updates. Always verify via bahrain.bh for the latest versions.',
            isRtl: false,
          ),
          SizedBox(height: 16),
          _QuickStatsRow(items: [
            _Stat('5', 'Key Laws'),
            _Stat('7', 'Violations'),
            _Stat('18', 'Protected\nSpecies'),
            _Stat('3mo', 'Shrimp Ban'),
          ]),
          SizedBox(height: 20),

          // ── Section 1 ──
          _SectionCard(
            icon: Icons.balance_rounded,
            title: '1. Legal Framework',
            children: [
              _BodyText(
                'Fishing in Bahrain is governed by Legislative Decree No. (20) of 2002 on the Regulation, Exploitation, and Protection of Marine Resources, amended most recently in 2025.',
              ),
              SizedBox(height: 12),
              _SubHeader('Key Laws & Recent Amendments:'),
              _BulletItem(
                bold: 'Legislative Decree No. 20 of 2002:',
                text:
                    ' The parent law defining licensing, fishing methods, prohibited areas, and penalties.',
              ),
              _BulletItem(
                bold: 'Law No. 14 of 2025:',
                text:
                    ' Latest amendment to Article 33, significantly increasing penalties for fishing violations.',
              ),
              _BulletItem(
                bold: 'Decision No. 4 of 2025:',
                text:
                    ' Regulates commercial fishing licenses for Bahraini fishermen.',
              ),
              _BulletItem(
                bold: 'Decision No. 6 of 2025:',
                text:
                    ' Regulates fishing with traps (fish pots), nets, and lines.',
              ),
              _BulletItem(
                bold: 'Decree No. 3 of 2025:',
                text:
                    ' Issued by the Supreme Council for Environment; bans the catching and trading of 18 species of juvenile fish and crustaceans.',
              ),
            ],
          ),

          // ── Section 2 ──
          _SectionCard(
            icon: Icons.badge_outlined,
            title: '2. Fishing Licenses & Requirements',
            children: [
              _BodyText(
                'No person may fish in Bahrain\'s territorial waters without a valid license from the General Directorate of Marine Resources.',
              ),
              SizedBox(height: 12),
              _LicenseTableEn(),
              SizedBox(height: 12),
              _SubHeader('Required Documents:'),
              _BulletItem(
                  text: 'Completed application form (via bahrain.bh portal).'),
              _BulletItem(
                  text:
                      'Valid passport copy (with residency permit for expatriates).'),
              _BulletItem(text: 'National ID copy (for citizens).'),
              _BulletItem(text: 'Proof of address (recent utility bill).'),
              _BulletItem(text: 'Two recent passport-size photographs.'),
              _BulletItem(
                  text:
                      'Medical fitness certificate (sometimes required for commercial fishing).'),
              _BulletItem(text: 'Vessel registration (for commercial fishing).'),
              SizedBox(height: 8),
              _WarningBox(
                'Note: Non-Bahraini nationals are prohibited from commercial fishing. Recreational fishing is permitted with the appropriate license.',
              ),
            ],
          ),

          // ── Section 3 ──
          _SectionCard(
            icon: Icons.report_problem_outlined,
            title: '3. Violations & Penalties (Law No. 14 of 2025)',
            children: [
              _PenaltiesTableEn(),
              SizedBox(height: 8),
              _WarningBox(
                'Fines double for repeat offences committed within one year of completing a previous sentence.',
              ),
            ],
          ),

          // ── Section 4 ──
          _SectionCard(
            icon: Icons.map_outlined,
            title: '4. Permitted & Restricted Fishing Areas',
            children: [
              _SubHeader('Areas Open to Recreational Fishing:'),
              _BulletItem(
                  text: 'Public park beaches (e.g. Al-Jazayir Beach).'),
              _BulletItem(
                  text:
                      'Urban waterfronts (e.g. North Manama Corniche, Muharraq Pier).'),
              _BulletItem(
                  text:
                      'Residential area beaches — observe all posted signage.'),
              SizedBox(height: 8),
              _SubHeader('Regulated & Restricted Areas:'),
              _BulletItem(
                bold: 'North-West Coast (Bu Daiya):',
                text:
                    ' Open to all with species-specific quotas for threatened stocks.',
              ),
              _BulletItem(
                bold: 'Hawar Islands:',
                text:
                    ' Strictly regulated; access is limited to scientific research or with special permits — a protected nature reserve.',
              ),
              _BulletItem(
                bold: 'Port Area (Manama):',
                text:
                    ' Under surveillance; generally reserved for commercial fishing.',
              ),
            ],
          ),

          // ── Section 5 ──
          _SectionCard(
            icon: Icons.event_busy_rounded,
            title: '5. Closed Seasons & Prohibited Species',
            children: [
              _SubHeader('Seasonal Closures:'),
              _BulletItem(
                bold: 'Shrimp:',
                text:
                    ' Fishing completely banned during May, June, and July (1 May – 31 July) to protect the breeding season.',
              ),
              _BulletItem(
                bold: 'Hamour, Sha\'ari, Safi, and Deinis:',
                text:
                    ' Periodic seasonal bans announced by the Supreme Council for the Environment. Monitor official announcements.',
              ),
              SizedBox(height: 8),
              _SubHeader('Prohibited Species (Catching & Trading):'),
              _BulletItem(
                bold: 'Juvenile fish:',
                text:
                    ' Decree No. 3 of 2025 prohibits catching, selling, or trading 18 species below the legal minimum size — they must be returned to the sea immediately.',
              ),
              _BulletItem(
                bold: 'Endangered species:',
                text:
                    ' Dugongs, sea turtles, and coastal sharks are fully protected.',
              ),
              _BulletItem(
                bold: 'Prohibited methods:',
                text:
                    ' Trawl nets in sensitive areas; explosives and poisons under all circumstances.',
              ),
            ],
          ),

          // ── Section 6 ──
          _SectionCard(
            icon: Icons.lightbulb_outline_rounded,
            title: '6. Practical Tips',
            children: [
              _TipItem(
                  number: 1,
                  text:
                      'Always carry your fishing license — inspections can occur at any time.'),
              _TipItem(
                  number: 2,
                  text:
                      'Use only legal equipment — ensure your nets and fish pots are properly licensed.'),
              _TipItem(
                  number: 3,
                  text:
                      'Keep a copy of the minimum size chart and verify each catch before keeping it.'),
              _TipItem(
                  number: 4,
                  text:
                      'For enquiries, contact the General Directorate of Marine Resources via bahrain.bh or the Ministry of Works, Municipalities Affairs, and Urban Planning.'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF007A96)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Stats Row ──────────────────────────────────────────────────────────

class _Stat {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
}

class _QuickStatsRow extends StatelessWidget {
  final List<_Stat> items;
  const _QuickStatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      s.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String message;
  final bool isRtl;
  const _InfoBanner({required this.message, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                height: 1.55,
              ),
              textDirection:
                  isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub Header ──────────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E6B6F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Body Text ────────────────────────────────────────────────────────────────

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.65,
        color: Color(0xFF444444),
      ),
    );
  }
}

// ─── Bullet Item ──────────────────────────────────────────────────────────────

class _BulletItem extends StatelessWidget {
  final String text;
  final String? bold;
  const _BulletItem({required this.text, this.bold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: Color(0xFF333333),
                ),
                children: [
                  if (bold != null)
                    TextSpan(
                      text: bold,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tip Item ─────────────────────────────────────────────────────────────────

class _TipItem extends StatelessWidget {
  final int number;
  final String text;
  const _TipItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Warning Box ──────────────────────────────────────────────────────────────

class _WarningBox extends StatelessWidget {
  final String text;
  const _WarningBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFCA28)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF57F17), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arabic License Table ─────────────────────────────────────────────────────

class _LicenseTable extends StatelessWidget {
  const _LicenseTable();

  @override
  Widget build(BuildContext context) {
    return _TableWidget(
      headers: const ['نوع الترخيص', 'الفئة', 'الصلاحية', 'الرسوم'],
      rows: const [
        ['ترخيص الهواة', 'مواطنون ومقيمون', 'سنوي / مؤقت', '10–15 د.ب'],
        ['ترخيص تجاري', 'شركات وأفراد', 'سنوي', '50–100 د.ب'],
      ],
    );
  }
}

// ─── Arabic Penalties Table ───────────────────────────────────────────────────

class _PenaltiesTable extends StatelessWidget {
  const _PenaltiesTable();

  @override
  Widget build(BuildContext context) {
    return _TableWidget(
      headers: const ['المخالفة', 'العقوبة'],
      rows: const [
        [
          'إلقاء النفايات البحرية (م. 18)',
          'سجن ≥ سنة + غرامة 1,000–10,000 د.ب'
        ],
        [
          'استخدام متفجرات/سموم (م. 23)',
          'سجن ≥ 6 أشهر + غرامة 30,000–100,000 د.ب'
        ],
        [
          'إنشاء مزارع دون ترخيص (م. 21)',
          'سجن + غرامة 1,000–5,000 د.ب'
        ],
        ['الصيد دون ترخيص (م. 27)', 'سجن + غرامة 500–3,000 د.ب'],
        ['حيازة شباك غير مرخصة (م. 20)', 'سجن + غرامة 500–3,000 د.ب'],
        ['صيد أسماك صغيرة/سلاحف (م. 19)', 'سجن + غرامة 500–3,000 د.ب'],
        ['رفض إبراز الرخصة (م. 28)', 'سجن + غرامة 100–2,000 د.ب'],
      ],
    );
  }
}

// ─── English License Table ────────────────────────────────────────────────────

class _LicenseTableEn extends StatelessWidget {
  const _LicenseTableEn();

  @override
  Widget build(BuildContext context) {
    return _TableWidget(
      headers: const ['License Type', 'Target Group', 'Validity', 'Approx. Fee'],
      rows: const [
        ['Recreational', 'Citizens & residents', 'Annual / Temp.', 'BD 10–15'],
        ['Commercial', 'Companies & individuals', 'Annual', 'BD 50–100'],
      ],
    );
  }
}

// ─── English Penalties Table ──────────────────────────────────────────────────

class _PenaltiesTableEn extends StatelessWidget {
  const _PenaltiesTableEn();

  @override
  Widget build(BuildContext context) {
    return _TableWidget(
      headers: const ['Violation', 'Penalty'],
      rows: const [
        [
          'Dumping waste in marine environment (Art. 18)',
          'Prison ≥ 1 yr + BD 1,000–10,000 fine'
        ],
        [
          'Use of explosives / poisons (Art. 23)',
          'Prison ≥ 6 months + BD 30,000–100,000 fine'
        ],
        [
          'Unlicensed fish farm / enclosure (Art. 21)',
          'Prison + BD 1,000–5,000 fine'
        ],
        ['Fishing without a license (Art. 27)', 'Prison + BD 500–3,000 fine'],
        ['Possessing unlicensed gear (Art. 20)', 'Prison + BD 500–3,000 fine'],
        [
          'Catching juvenile fish / turtles (Art. 19)',
          'Prison + BD 500–3,000 fine'
        ],
        ['Refusing to show license (Art. 28)', 'Prison + BD 100–2,000 fine'],
      ],
    );
  }
}

// ─── Reusable Table Widget ────────────────────────────────────────────────────

class _TableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  const _TableWidget({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        columnWidths: headers.length == 2
            ? const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(1.6)}
            : null,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.primary),
            children: headers
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final isEven = entry.key % 2 == 0;
            return TableRow(
              decoration: BoxDecoration(
                color: isEven
                    ? Colors.white
                    : AppColors.primary.withValues(alpha: 0.04),
              ),
              children: entry.value
                  .map(
                    (cell) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Text(
                        cell,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
