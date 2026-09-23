/// Çizgi Bulmaca — Sabit Değerler
class AppConstants {
  AppConstants._();

  // ─── Uygulama Bilgileri ──────────────────────────────────
  static const String appName = 'Çizgi Bulmaca';
  static const String appNameEn = 'Line Puzzle';
  static const String bundleId = 'com.cizgibulmaca.app';

  // ─── Level Yapısı ────────────────────────────────────────
  static const int easyLevelCount = 200;
  static const int mediumLevelCount = 200;
  static const int hardLevelCount = 200;
  static const int totalLevelCount = 600;

  // ─── Yıldız Sistemi ──────────────────────────────────────
  static const int maxStarsPerLevel = 3;

  // ─── Reklam Ayarları (Google AdMob) ──────────────────────
  /// Canlı reklam modunu açıp kapatır.
  /// Canlıya (Store'a) göndermeden önce 'true' yapın ve aşağıdaki Canlı ID'leri doldurun.
  static const bool isProductionAds = true;

  /// İlk X level reklamsız (kullanıcıyı kaybetmemek için)
  static const int adFreeInitialLevels = 3;

  /// Kaç level'da bir geçiş (interstitial) reklam gösterilsin
  static const int interstitialFrequency = 3;

  // ─── Canlı AdMob Kimlikleri (Production IDs) ──────────────
  static const String admobAppIdAndroidLive = 'ca-app-pub-6930876126004356~5709613860';
  static const String admobAppIdIosLive = 'ca-app-pub-6930876126004356~7477067667';

  static const String admobInterstitialAndroidLive = 'ca-app-pub-6930876126004356/8641055653';
  static const String admobInterstitialIosLive = 'ca-app-pub-6930876126004356/9001991614';

  static const String admobRewardedAndroidLive = 'ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW';
  static const String admobRewardedIosLive = 'ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW';

  // ─── Test AdMob Kimlikleri (Google Resmi Test ID'leri) ─────
  static const String admobAppIdAndroidTest = 'ca-app-pub-3940256099942544~3347511713';
  static const String admobAppIdIosTest = 'ca-app-pub-3940256099942544~1458002511';

  static const String admobInterstitialAndroidTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String admobInterstitialIosTest = 'ca-app-pub-3940256099942544/4411468910';

  static const String admobRewardedAndroidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String admobRewardedIosTest = 'ca-app-pub-3940256099942544/1712485313';

  // Geriye dönük uyumluluk için alias test ID'leri
  static const String admobBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String admobInterstitialTestId = admobInterstitialAndroidTest;
  static const String admobRewardedTestId = admobRewardedAndroidTest;

  // ─── IAP Product ID'leri ─────────────────────────────────
  static const String iapRemoveAds = 'com.cizgibulmaca.remove_ads';

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

  // ─── Linkler & İletişim ──────────────────────────────────
  static const String privacyPolicyUrl = 'https://www.kahramanapp.com/privacy';
  static const String termsOfUseUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String supportEmail = 'kahramandev01@gmail.com';
  static const String developerName = 'Kahramanapp';
}
