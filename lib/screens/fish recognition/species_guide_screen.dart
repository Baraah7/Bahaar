/* UNUSED FILE - commented out
﻿// lib/screens/species_guide_screen.dart
// Searchable species grid + tappable detail screen (nested in the same file).

import 'package:flutter/material.dart';
import 'package:Bahaar/core/constants/species_data.dart';
import 'package:Bahaar/core/constants/app_colors.dart';
import 'package:Bahaar/screens/fish recognition/prediction_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// Species Guide Screen  —  searchable 2-column grid
// ════════════════════════════════════════════════════════════════════════════

class SpeciesGuideScreen extends StatefulWidget {
  const SpeciesGuideScreen({super.key});

  @override
  State<SpeciesGuideScreen> createState() => _SpeciesGuideScreenState();
}

class _SpeciesGuideScreenState extends State<SpeciesGuideScreen> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return kAllSpecies;
    final q = _query.toLowerCase();
    return kAllSpecies.where((s) {
      return (s['nameAr'] as String).contains(q) ||
          (s['nameEn'] as String).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'دليل الأسماك',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
              ),
            ),
          ),
        ),
        body: _filtered.isEmpty
            ? const Center(child: Text('لا توجد نتائج'))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filtered.length,
                itemBuilder: (context, i) =>
                    _SpeciesCard(species: _filtered[i]),
              ),
      ),
    );
  }
}

// ── Species card (grid item) ─────────────────────────────────────────────────

class _SpeciesCard extends StatelessWidget {
  final Map<String, dynamic> species;
  const _SpeciesCard({required this.species});

  @override
  Widget build(BuildContext context) {
    final peakMonths = (species['peakMonths'] as List).cast<int>();
    final now = DateTime.now().month;
    final isPeak = peakMonths.contains(now);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpeciesDetailScreen(species: species),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fish icon circle
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D4F54).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.set_meal,
                    color: Color(0xFF0D4F54),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Arabic name
              Text(
                species['nameAr'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // English name
              Text(
                species['nameEn'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Depth range
              Row(children: [
                Icon(Icons.water, size: 13, color: Colors.blue.shade400),
                const SizedBox(width: 3),
                Text(
                  species['depthRange'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ]),

              const Spacer(),

              // Peak season badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPeak
                        ? Colors.teal.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPeak
                          ? Colors.teal.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    isPeak ? 'موسم الصيد الآن' : 'خارج الموسم',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPeak
                          ? Colors.teal.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Species Detail Screen
// ════════════════════════════════════════════════════════════════════════════

class SpeciesDetailScreen extends StatelessWidget {
  final Map<String, dynamic> species;
  const SpeciesDetailScreen({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final peakMonths = (species['peakMonths'] as List).cast<int>();
    final methods = (species['methods'] as List).cast<String>();
    final bottomTypes = (species['bottomTypes'] as List).cast<String>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            // ── App bar with fish icon ────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  species['nameAr'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  color: const Color(0xFF0D4F54),
                  child: Center(
                    child: Icon(
                      Icons.set_meal,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Names & scientific name ───────────────────────────
                    _SectionCard(
                      children: [
                        _DetailRow(
                          label: 'الاسم العربي',
                          value: species['nameAr'] as String,
                        ),
                        _DetailRow(
                          label: 'الاسم الإنجليزي',
                          value: species['nameEn'] as String,
                        ),
                        _DetailRow(
                          label: 'الاسم العلمي',
                          value: species['scientific'] as String,
                          valueStyle: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Peak months ──────────────────────────────────────
                    _SectionHeader(
                      icon: Icons.calendar_month,
                      title: 'أشهر الصيد',
                    ),
                    _MonthCalendar(peakMonths: peakMonths),
                    const SizedBox(height: 14),

                    // ── Depth & bottom types ─────────────────────────────
                    _SectionHeader(icon: Icons.water, title: 'البيئة'),
                    _SectionCard(
                      children: [
                        _DetailRow(
                          label: 'عمق الصيد',
                          value: species['depthRange'] as String,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نوع القاع:',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: bottomTypes.map((bt) {
                            return Chip(
                              label: Text(
                                kBottomTypeNamesAr[bt] ?? bt,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor:
                                  Colors.blue.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.blue.shade700),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Fishing methods ───────────────────────────────────
                    _SectionHeader(
                      icon: Icons.anchor,
                      title: 'طرق الصيد',
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: methods.map((m) {
                        return Chip(
                          label: Text(
                            kMethodNamesAr[m] ?? m,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor:
                              const Color(0xFF0D4F54).withValues(alpha: 0.1),
                          labelStyle:
                              const TextStyle(color: Color(0xFF0D4F54)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // ── Advice ────────────────────────────────────────────
                    _SectionHeader(
                      icon: Icons.lightbulb_outline,
                      title: 'نصائح الصيد',
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.amber.shade50,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          species['advice'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── CTA button ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PredictionScreen(
                              initialSpeciesId: species['id'] as String,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text(
                          'احصل على تنبؤ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D4F54),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 12-month calendar widget ─────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  final List<int> peakMonths;
  const _MonthCalendar({required this.peakMonths});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().month;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: List.generate(12, (i) {
            final month = i + 1;
            final isPeak = peakMonths.contains(month);
            final isCurrent = month == now;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPeak
                          ? Colors.teal
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrent
                          ? Border.all(
                              color: Colors.orange,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _shortMonth(month),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isPeak ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  String _shortMonth(int m) {
    const short = [
      'ي', 'ف', 'م', 'أ', 'م', 'ي',
      'ي', 'أ', 'س', 'أ', 'ن', 'د',
    ];
    return short[m - 1];
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0D4F54), size: 20),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0D4F54),
              ),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                '$label:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: valueStyle ??
                    const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
}
*/
