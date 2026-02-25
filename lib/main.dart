import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Bahaar/screens/weather.dart';
import 'package:Bahaar/screens/integrated_map.dart';
import 'package:Bahaar/screens/mariner_harvest.dart';
import 'package:Bahaar/screens/settings_screen.dart';
import 'package:Bahaar/screens/profile_screen.dart';
import 'package:Bahaar/screens/fishing_log_screen.dart';
import 'package:Bahaar/widgets/language_switcher.dart';
import 'package:Bahaar/screens/fish_recognition_screen.dart';
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
  int _index = 1;
  late final PageController _controller = PageController(initialPage: _index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Color(0xFF0D4F54),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: l10n.settings,
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
          IntegratedMap(),
          Weather(),
          FishRecognitionScreen(),
          MarinerHarvestPage(),
          FishingLogScreen(),
        ]
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) {
          _controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',  
            backgroundColor:Color(0xFF0D4F54),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Weather',
            backgroundColor: Color(0xFF0D4F54)
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Fish ID',
            backgroundColor: Color(0xFF0D4F54)
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.sailing),
            label: 'Mariner Harvest',
            backgroundColor: Color(0xFF0D4F54)
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.anchor),
            label: 'Fishing Log',
            backgroundColor: Color(0xFF0D4F54)
          ),
        ],
      ),

    );
  }
}