import 'package:flutter/material.dart';
import 'package:Bahaar/core/constants/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Bahaar/screens/weather.dart';
import 'package:Bahaar/screens/integrated_map.dart';
import 'package:Bahaar/screens/mariner_harvest.dart';
import 'package:Bahaar/screens/settings_screen.dart';
import 'package:Bahaar/screens/profile_screen.dart';
import 'package:Bahaar/providers/authentication_provider.dart';
import 'package:Bahaar/screens/fishing_log_screen.dart';
import 'package:Bahaar/screens/fish_recognition_screen.dart';
import 'package:Bahaar/screens/celestial_navigation_screen.dart';
import 'package:Bahaar/providers/language_provider.dart';
import 'package:Bahaar/services/offline/connectivity_service.dart';
import 'package:Bahaar/services/offline/database_service.dart';
import 'package:Bahaar/services/notifications/notification_service.dart';
import 'package:Bahaar/services/notifications/weather_monitor.dart';
import 'l10n/app_localizations.dart';
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
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
  int _index = 2;
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
    final l10n = AppLocalizations.of(context)!;

    final pageTitles = [
      l10n.marketplace,
      l10n.fishingMap,
      l10n.weather,
      l10n.fishRecognition,
      l10n.fishingLog,
      'Sextant',
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            'assets/logo/appIcon.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
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
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final dl10n = AppLocalizations.of(ctx)!;
                    return AlertDialog(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(dl10n.emergency,
                          style: const TextStyle(color: AppColors.cream)),
                      content: Text(
                          dl10n.emergencyComingSoon,
                          style: const TextStyle(color: AppColors.cream)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(dl10n.ok,
                              style: const TextStyle(color: AppColors.accent)),
                        ),
                      ],
                    );
                  },
                );
              } else if (value == 'settings') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == 'profile') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }
            },
            itemBuilder: (ctx) {
              final ml10n = AppLocalizations.of(ctx)!;
              return [
                PopupMenuItem(
                  value: 'emergency',
                  child: Row(children: [
                    const Icon(Icons.sos_rounded, color: AppColors.red, size: 22),
                    const SizedBox(width: 12),
                    Text(ml10n.emergency,
                        style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600)),
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
                    Text(ml10n.profile,
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
        onPageChanged: (index){
          setState(() {
            _index = index;
          });
        },

        children: const [
          MarinerHarvestPage(),
          IntegratedMap(),
          Weather(),
          FishRecognitionScreen(),
          FishingLogScreen(),
          CelestialNavigationScreen(),
        ]
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.85),
        unselectedItemColor: AppColors.cream.withValues(alpha: 0.55),
        onTap: (index) {
          _controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sailing),
            label: 'Marketplace',
            backgroundColor: AppColors.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
            backgroundColor: AppColors.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Weather',
            backgroundColor: AppColors.accent,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Fish ID',
            backgroundColor: AppColors.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.anchor),
            label: 'Fishing Log',
            backgroundColor: AppColors.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Sextant',
            backgroundColor: AppColors.primary,
          ),
        ],
      ),

    );
  }
}