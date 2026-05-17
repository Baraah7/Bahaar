import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app/fishing_laws_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class FishingLawsScreen extends StatelessWidget {
  const FishingLawsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = FishingLawsLocalizations.of(context);
    final isAr = l10n.isAr;
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
                            l10n.screenTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.screenSubtitle,
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
                  ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: _LawsContent(l10n: l10n),
                    )
                  : _LawsContent(l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Unified Content ──────────────────────────────────────────────────────────

class _LawsContent extends StatelessWidget {
  final FishingLawsLocalizations l10n;
  const _LawsContent({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(message: l10n.infoBanner, isRtl: l10n.isAr),
          const SizedBox(height: 16),
          _QuickStatsRow(items: [
            _Stat(l10n.statLawsValue, l10n.statLawsLabel),
            _Stat(l10n.statViolationsValue, l10n.statViolationsLabel),
            _Stat(l10n.statSpeciesValue, l10n.statSpeciesLabel),
            _Stat(l10n.statShrimpValue, l10n.statShrimpLabel),
          ]),
          const SizedBox(height: 20),

          // ── Section 1 ──
          _SectionCard(
            icon: Icons.balance_rounded,
            title: l10n.section1Title,
            children: [
              _BodyText(l10n.legalFrameworkBody),
              const SizedBox(height: 12),
              _SubHeader(l10n.keyLawsSubHeader),
              _BulletItem(bold: l10n.decree20Bold, text: l10n.decree20Text),
              _BulletItem(bold: l10n.law14Bold, text: l10n.law14Text),
              _BulletItem(bold: l10n.decision4Bold, text: l10n.decision4Text),
              _BulletItem(bold: l10n.decision6Bold, text: l10n.decision6Text),
              _BulletItem(bold: l10n.decree3Bold, text: l10n.decree3Text),
            ],
          ),

          // ── Section 2 ──
          _SectionCard(
            icon: Icons.badge_outlined,
            title: l10n.section2Title,
            children: [
              _BodyText(l10n.licenseIntroBody),
              const SizedBox(height: 12),
              _TableWidget(
                headers: l10n.licenseTableHeaders,
                rows: l10n.licenseTableRows,
              ),
              const SizedBox(height: 12),
              _SubHeader(l10n.requiredDocsSubHeader),
              _BulletItem(text: l10n.doc1),
              _BulletItem(text: l10n.doc2),
              _BulletItem(text: l10n.doc3),
              _BulletItem(text: l10n.doc4),
              _BulletItem(text: l10n.doc5),
              _BulletItem(text: l10n.doc6),
              _BulletItem(text: l10n.doc7),
              const SizedBox(height: 8),
              _WarningBox(l10n.licenseWarning),
            ],
          ),

          // ── Section 3 ──
          _SectionCard(
            icon: Icons.report_problem_outlined,
            title: l10n.section3Title,
            children: [
              _TableWidget(
                headers: l10n.penaltiesTableHeaders,
                rows: l10n.penaltiesTableRows,
              ),
              const SizedBox(height: 8),
              _WarningBox(l10n.penaltiesWarning),
            ],
          ),

          // ── Section 4 ──
          _SectionCard(
            icon: Icons.map_outlined,
            title: l10n.section4Title,
            children: [
              _SubHeader(l10n.openAreasSubHeader),
              _BulletItem(text: l10n.openArea1),
              _BulletItem(text: l10n.openArea2),
              _BulletItem(text: l10n.openArea3),
              const SizedBox(height: 8),
              _SubHeader(l10n.restrictedAreasSubHeader),
              _BulletItem(bold: l10n.buDaiyaBold, text: l10n.buDaiyaText),
              _BulletItem(bold: l10n.hawarBold, text: l10n.hawarText),
              _BulletItem(bold: l10n.portAreaBold, text: l10n.portAreaText),
            ],
          ),

          // ── Section 5 ──
          _SectionCard(
            icon: Icons.event_busy_rounded,
            title: l10n.section5Title,
            children: [
              _SubHeader(l10n.seasonalClosuresSubHeader),
              _BulletItem(bold: l10n.shrimpBold, text: l10n.shrimpText),
              _BulletItem(bold: l10n.hamourBold, text: l10n.hamourText),
              const SizedBox(height: 8),
              _SubHeader(l10n.prohibitedSpeciesSubHeader),
              _BulletItem(bold: l10n.juvenileFishBold, text: l10n.juvenileFishText),
              _BulletItem(bold: l10n.endangeredBold, text: l10n.endangeredText),
              _BulletItem(bold: l10n.prohibitedMethodsBold, text: l10n.prohibitedMethodsText),
            ],
          ),

          // ── Section 6 ──
          _SectionCard(
            icon: Icons.lightbulb_outline_rounded,
            title: l10n.section6Title,
            children: [
              _TipItem(number: 1, text: l10n.tip1),
              _TipItem(number: 2, text: l10n.tip2),
              _TipItem(number: 3, text: l10n.tip3),
              _TipItem(number: 4, text: l10n.tip4),
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
