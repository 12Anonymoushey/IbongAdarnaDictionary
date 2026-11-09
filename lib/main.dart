import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/themes/app_colors.dart';
import 'features/search/search_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/activities/activities_screen.dart';
import 'features/kabanata/mga_kabanata_screen.dart';
import 'features/saves/saves_screen.dart';
import 'features/rewards/rewards_screen.dart';
import 'features/growth/growth_screen.dart';
import 'features/pilak/pilak_service.dart';
import 'services/app_feedback.dart';
import 'widgets/dictionary_bar.dart';
import 'widgets/dictionary_drawer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const IbongAdarnaApp());
}

class IbongAdarnaApp extends StatelessWidget {
  const IbongAdarnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PilakService.instance,
      builder: (context, child) => MaterialApp(
        scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
        title: 'Ibong Adarna Dictionary',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(PilakService.instance.activeThemeId),
        home: const SplashScreen(),
        builder: (context, navigator) => Stack(
          fit: StackFit.expand,
          children: [
            ?navigator,
            if (PilakService.instance.adarnaModeEnabled)
              Positioned(
                right: 12,
                bottom: 88,
                child: IgnorePointer(
                  child: _AdarnaHeartHud(
                    hearts: PilakService.instance.adarnaHearts,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdarnaHeartHud extends StatelessWidget {
  const _AdarnaHeartHud({required this.hearts});

  final int hearts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$hearts of 3 Adarna hearts remaining',
      liveRegion: true,
      child: Material(
        color: colors.surface.withValues(alpha: 0.94),
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < 3; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Icon(
                    Icons.favorite,
                    color: index < hearts ? Colors.red : colors.outline,
                    size: 25,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

ThemeData _buildAppTheme(String? themeId) {
  var primary = AppColors.sapphire;
  var secondary = AppColors.crimson;
  var surface = AppColors.parchment;
  var brightness = Brightness.light;
  String? fontFamily;
  final blocky = themeId == '8bit_retro';
  switch (themeId) {
    case 'armenya_forest':
      primary = const Color(0xFF14532D);
      secondary = const Color(0xFF4D7C0F);
      break;
    case 'berbanya_crimson':
      primary = const Color(0xFF8F1024);
      secondary = const Color(0xFFC51E3A);
      break;
    case 'cave_ermitanyo':
      primary = Colors.black;
      secondary = const Color(0xFF7C3AED);
      surface = Colors.black;
      brightness = Brightness.dark;
      break;
    case 'sepia_manuscript':
      primary = const Color(0xFF6F4E37);
      secondary = const Color(0xFF9A6B3F);
      surface = const Color(0xFFF2E6CF);
      break;
    case 'typewriter_typography':
      fontFamily = 'monospace';
      break;
    case 'piedras_platas_gold':
      primary = const Color(0xFF8A5A00);
      secondary = const Color(0xFFE0A800);
      break;
    case 'cristales_glass':
      primary = const Color(0xFF075985);
      secondary = const Color(0xFF06B6D4);
      break;
    case '8bit_retro':
      primary = const Color(0xFF0F766E);
      secondary = const Color(0xFFD946EF);
      break;
    case 'colonial_calligraphy':
    case 'baybayin_overlay':
      fontFamily = 'serif';
      break;
  }
  final onSurface = brightness == Brightness.dark
      ? Colors.white
      : AppColors.midnight;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    tertiary: AppColors.gold,
    surface: surface,
    onSurface: onSurface,
  );
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: surface,
    primaryColor: primary,
    colorScheme: colorScheme,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      color: brightness == Brightness.dark
          ? const Color(0xFF111111)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(blocky ? 0 : 12),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: secondary,
      unselectedItemColor: primary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : Colors.white,
      iconColor: primary,
      prefixIconColor: primary,
      suffixIconColor: primary,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: secondary, width: 2),
        borderRadius: BorderRadius.circular(blocky ? 0 : 14),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: secondary,
      selectionHandleColor: secondary,
    ),
  );
}

// --- Main Navigation Shell (Bottom Tabs) ---
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ActivitiesScreen(),
    SavesScreen(),
    RewardsScreen(),
    GrowthScreen(),
    MgaKabanataScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _recordDailyLogin();
  }

  Future<void> _recordDailyLogin() async {
    try {
      await PilakService.instance.recordDailyLogin();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Pilak economy',
          context: ErrorDescription('while recording the daily login reward'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DictionaryBar(),
      drawer: DictionaryDrawer(
        onRouteSelected: (int index) {
          if (index == 6) {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const SearchScreen(),
              ),
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.extension_outlined),
              activeIcon: Icon(Icons.extension),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Saves',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Growth',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: 'Mga Kabanata',
            ),
          ],
        ),
      ),
    );
  }
}
