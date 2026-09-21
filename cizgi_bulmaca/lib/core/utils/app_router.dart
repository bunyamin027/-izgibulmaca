import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/level_map/level_map_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/store/store_screen.dart';
import '../../features/profile/profile_screen.dart';

/// Çizgi Bulmaca — GoRouter Yapılandırması
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Ana Sayfa (Mod Seçimi)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Level Haritası
      GoRoute(
        path: '/levels/:difficulty',
        name: 'levels',
        builder: (context, state) {
          final difficulty = int.tryParse(
                state.pathParameters['difficulty'] ?? '0',
              ) ?? 0;
          return LevelMapScreen(difficulty: difficulty);
        },
      ),

      // Oynanış Ekranı
      GoRoute(
        path: '/game/:levelId',
        name: 'game',
        builder: (context, state) {
          final levelId = int.tryParse(
                state.pathParameters['levelId'] ?? '1',
              ) ?? 1;
          final difficulty = int.tryParse(
                state.uri.queryParameters['d'] ?? '0',
              ) ?? 0;
          return GameScreen(levelId: levelId, difficulty: difficulty);
        },
      ),

      // Ayarlar
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Mağaza (Reklamları Kaldır)
      GoRoute(
        path: '/store',
        name: 'store',
        builder: (context, state) => const StoreScreen(),
      ),

      // Profil & Başarımlar
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
