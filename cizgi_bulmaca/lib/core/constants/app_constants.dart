/// Çizgi Bulmaca — Sabit Değerler
class AppConstants {
  AppConstants._();

  // ─── Uygulama Bilgileri ──────────────────────────────────
  static const String appName = 'Çizgi Bulmaca';
  static const String appNameEn = 'Line Puzzle';
  static const String bundleId = 'com.teknopark.cizgiBulmaca';

  // ─── Level Yapısı ────────────────────────────────────────
  static const int easyLevelCount = 200;
  static const int mediumLevelCount = 200;
  static const int hardLevelCount = 200;
  static const int totalLevelCount = 600;

  // ─── Yıldız Sistemi ──────────────────────────────────────
  static const int maxStarsPerLevel = 3;

  // ─── Reklam Ayarları ─────────────────────────────────────
  /// İlk X level reklamsız (kullanıcıyı kaybetmemek için)
  static const int adFreeInitialLevels = 3;
  /// Kaç level'da bir interstitial gösterilsin
  static const int interstitialFrequency = 3;

  // ─── AdMob Test ID'leri ──────────────────────────────────
  static const String admobBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String admobInterstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String admobRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  // ─── IAP Product ID'leri ─────────────────────────────────
  static const String iapRemoveAds = 'com.teknopark.cizgiBulmaca.remove_ads';

  // ─── Animasyon Süreleri ──────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 2000);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // ─── Boyut Sabitleri ─────────────────────────────────────
  static const double borderRadius = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 24.0;
  static const double cardElevation = 4.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;

  // ─── Padding & Spacing ───────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // ─── Storage Keys ────────────────────────────────────────
  static const String keyThemeMode = 'theme_mode';
  static const String keyThemeColor = 'theme_color';
  static const String keyLocale = 'locale';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticEnabled = 'haptic_enabled';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyAdsRemoved = 'ads_removed';
  static const String keyTotalStars = 'total_stars';
  static const String keyTotalScore = 'total_score';
  static const String keyLastDifficulty = 'last_difficulty';
  static const String keyLastLevel = 'last_level';
  static const String keyHintCount = 'hint_count';
  static const int defaultHintCount = 5;

  // ─── Linkler ─────────────────────────────────────────────
  static const String privacyPolicyUrl = 'https://teknopark.com/privacy';
  static const String termsOfUseUrl = 'https://teknopark.com/terms';
}
