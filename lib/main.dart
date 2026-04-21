import 'package:flutter/material.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bahaar/screens/weather/weather.dart';
import 'package:bahaar/screens/map/integrated_map.dart';
import 'package:bahaar/screens/marketplace/marketplace.dart';
import 'package:bahaar/screens/settings/settings_screen.dart';
import 'package:bahaar/screens/settings/emergency_screen.dart';
import 'package:bahaar/screens/authentication/profile_screen.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/screens/fishing log/fishing_log_screen.dart';
import 'package:bahaar/screens/fish recognition/fish_recognition_screen.dart';
import 'package:bahaar/providers/language/language_provider.dart';
import 'package:bahaar/services/offline/connectivity_service.dart';
import 'package:bahaar/services/offline/database_service.dart';
import 'package:bahaar/services/notifications/notification_service.dart';
import 'package:bahaar/services/notifications/weather_monitor.dart';
import 'l10n/app_localizations.dart';
import 'package:bahaar/l10n/app/app_localization.dart';
import 'package:bahaar/l10n/settings/settings_localizations.dart';
import 'package:bahaar/l10n/profile/profile_localizations.dart';
import 'app_start.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: "secrets.env");

  // Offline services
  await DatabaseService.instance.database;
  await ConnectivityService.instance.initialize();

  // Notifications + weather monitor
  await NotificationService.instance.initialize();
  WeatherMonitor.instance.start();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Bahaar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Zain',
      ),
      home: const AppStart(),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int _index = 1;
  late final PageController _controller = PageController(initialPage: _index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProviderProvider).initializeAuthState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final pageTitles = [l10n.fishingMap, l10n.weather];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => _showAboutDialog(context, l10n),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/logo/appIcon.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          pageTitles[_index],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.cream),
            color: AppColors.cream.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 'emergency') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmergencyScreen()));
              } else if (value == 'settings') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == 'profile') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }
            },
            itemBuilder: (ctx) {
              final ml10n = AppLocalization.of(ctx);
              final sl10n = SettingsLocalizations.of(ctx);
              final pl10n = ProfileLocalizations.of(ctx);
              return [
                PopupMenuItem(
                  value: 'emergency',
                  child: Row(children: [
                    const Icon(Icons.sos_rounded, color: AppColors.red, size: 22),
                    const SizedBox(width: 12),
                    Text(sl10n.emergency,
                        style: const TextStyle(
                            color: AppColors.red, fontWeight: FontWeight.w600)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(children: [
                    const Icon(Icons.settings_outlined,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Text(ml10n.settings,
                        style: const TextStyle(color: AppColors.primary)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    const Icon(Icons.person_outline,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Text(pl10n.profile,
                        style: const TextStyle(color: AppColors.primary)),
                  ]),
                ),
              ];
            },
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _index = index),
        children: const [
          IntegratedMap(),
          Weather(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: Colors.white.withValues(alpha: 0.9),
        unselectedItemColor: AppColors.cream.withValues(alpha: 0.55),
        onTap: (index) {
          if (index == 2) {
            _showOtherToolsSheet(context, l10n);
          } else {
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map),
            label: l10n.fishingMap,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.cloud_outlined),
            activeIcon: const Icon(Icons.cloud),
            label: l10n.weather,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.apps_outlined),
            activeIcon: const Icon(Icons.apps),
            label: l10n.otherTools,
          ),
        ],
      ),
    );
  }

  void _showOtherToolsSheet(BuildContext context, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OtherToolsSheet(l10n: l10n),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalization l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo/appIcon.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.aboutAppTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          l10n.aboutAppDescription,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                l10n.close,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherToolsSheet extends StatelessWidget {
  final AppLocalization l10n;
  const _OtherToolsSheet({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            l10n.otherTools,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _ToolTile(
            icon: Icons.anchor,
            color: AppColors.brown,
            textColor: Color.fromARGB(255, 83, 68, 52),
            title: l10n.fishingLog,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FishingLogScreen()));
            },
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.camera_alt_outlined,
            color: AppColors.brown,
            textColor: Color.fromARGB(255, 83, 68, 52),
            title: l10n.fishRecognition,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FishRecognitionScreen()));
            },
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.storefront_outlined,
            color: AppColors.brown,
            textColor: Color.fromARGB(255, 83, 68, 52),
            title: l10n.marketplace,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarinerHarvestPage()));
            },
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color textColor;
  final String title;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.color,
    required this.textColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
