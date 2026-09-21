import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/settings_provider.dart';
import 'core/services/game_provider.dart';
import 'core/utils/app_router.dart';

/// Çizgi Bulmaca — Ana Giriş Noktası
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dikey yönlendirmeyi zorunlu kıl (bulmaca oyunu için ideal)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const CizgiBulmacaApp());
}

class CizgiBulmacaApp extends StatelessWidget {
  const CizgiBulmacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Çizgi Bulmaca',
            debugShowCheckedModeBanner: false,

            // Tema
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // Router
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
