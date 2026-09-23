import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

/// Çizgi Bulmaca — Reklam Servisi (Google AdMob)
/// Interstitial ve Rewarded reklamları yönetir.
/// Platforma (Android/iOS) ve Canlı/Test moduna göre uygun ID'leri kullanır.
/// Reklam yüklenemezse oyunu bloklamaz.
class AdService {
  AdService._();

  static final AdService _instance = AdService._();
  static AdService get instance => _instance;

  bool _isInitialized = false;
  bool _adsRemoved = false;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _completedLevelsSinceLastAd = 0;
  int _totalCompletedLevels = 0;

  // ─── Getters ──────────────────────────────────────────────

  bool get isInitialized => _isInitialized;
  bool get adsRemoved => _adsRemoved;
  bool get isRewardedReady => _rewardedAd != null && !_adsRemoved;

  /// Platform ve mod bazlı Geçiş (Interstitial) Reklam ID'si
  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (AppConstants.isProductionAds) {
      return Platform.isAndroid
          ? AppConstants.admobInterstitialAndroidLive
          : AppConstants.admobInterstitialIosLive;
    }
    return Platform.isAndroid
        ? AppConstants.admobInterstitialAndroidTest
        : AppConstants.admobInterstitialIosTest;
  }

  /// Platform ve mod bazlı Ödüllü (Rewarded) Reklam ID'si
  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (AppConstants.isProductionAds) {
      return Platform.isAndroid
          ? AppConstants.admobRewardedAndroidLive
          : AppConstants.admobRewardedIosLive;
    }
    return Platform.isAndroid
        ? AppConstants.admobRewardedAndroidTest
        : AppConstants.admobRewardedIosTest;
  }

  // ─── Initialization ──────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] MobileAds initialized successfully (Production: ${AppConstants.isProductionAds})');
      // Ön yükleme
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] Init failed: $e');
    }
  }

  /// Reklamlar kaldırıldığında çağrılır (IAP sonrası)
  void setAdsRemoved(bool removed) {
    _adsRemoved = removed;
    if (_adsRemoved) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _rewardedAd?.dispose();
      _rewardedAd = null;
      debugPrint('[AdService] Ads removed - all cached ads disposed');
    }
  }

  // ─── Interstitial (Geçiş) Reklam ─────────────────────────

  void _loadInterstitialAd() {
    if (_adsRemoved || !_isInitialized || _isLoadingInterstitial) return;
    if (interstitialAdUnitId.isEmpty) return;

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial failed: ${error.message} (code: ${error.code})');
          _interstitialAd = null;
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  /// Level tamamlandığında çağrılır.
  /// İlk [adFreeInitialLevels] level reklamsız.
  /// Sonrasında her [interstitialFrequency] level'da bir interstitial gösterir.
  /// Reklam kapandığında veya reklam gösterilmediğinde [onAdClosed] callback'i çalışır.
  void onLevelCompleted({VoidCallback? onAdClosed}) {
    _totalCompletedLevels++;
    _completedLevelsSinceLastAd++;

    if (_adsRemoved) {
      onAdClosed?.call();
      return;
    }

    // İlk X level reklamsız
    if (_totalCompletedLevels <= AppConstants.adFreeInitialLevels) {
      onAdClosed?.call();
      return;
    }

    // Her N level'da bir göster
    if (_completedLevelsSinceLastAd >= AppConstants.interstitialFrequency) {
      _completedLevelsSinceLastAd = 0;
      if (_interstitialAd != null) {
        showInterstitial(onDismissed: onAdClosed);
      } else {
        // Reklam hazır değilse oyunu bloklama, arka planda yüklemeyi tetikle
        _loadInterstitialAd();
        onAdClosed?.call();
      }
    } else {
      onAdClosed?.call();
    }
  }

  /// Interstitial reklam göster
  void showInterstitial({VoidCallback? onDismissed}) {
    if (_adsRemoved || _interstitialAd == null) {
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Sonrakini önceden yükle
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Interstitial show failed: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ─── Rewarded (Ödüllü) Reklam ────────────────────────────

  void _loadRewardedAd() {
    if (_adsRemoved || !_isInitialized || _isLoadingRewarded) return;
    if (rewardedAdUnitId.isEmpty) return;

    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded failed: ${error.message} (code: ${error.code})');
          _rewardedAd = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  /// Rewarded reklam göster. [onRewarded] callback ile ödül verilir.
  void showRewarded({required VoidCallback onRewarded}) {
    if (_adsRemoved || _rewardedAd == null) {
      // Reklam hazır değilse arka planda yüklemeyi başlat ve kullanıcıyı mağdur etmemek için ödülü ver
      _loadRewardedAd();
      onRewarded();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Sonrakini önceden yükle
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Rewarded show failed: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        // Gösterme başarısız olursa yine ödülü ver
        onRewarded();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount}');
        onRewarded();
      },
    );
    _rewardedAd = null;
  }

  // ─── Toplam tamamlanan level sayısını dışarıdan güncelle ──

  void updateTotalCompletedLevels(int count) {
    _totalCompletedLevels = count;
  }

  // ─── Dispose ──────────────────────────────────────────────

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
