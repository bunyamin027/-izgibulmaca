import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/app_constants.dart';
import 'settings_provider.dart';
import 'ad_service.dart';

/// Çizgi Bulmaca — In-App Purchase Servisi
/// Apple App Store / Google Play için "Reklamları Kaldır" satın alma akışı.
class IapService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final SettingsProvider _settingsProvider;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isPurchasing = false;
  ProductDetails? _product;
  String? _errorMessage;

  IapService(this._settingsProvider) {
    _init();
  }

  // ─── Getters ──────────────────────────────────────────────

  bool get isAvailable => _isAvailable;
  bool get isPurchasing => _isPurchasing;
  ProductDetails? get product => _product;
  String? get errorMessage => _errorMessage;
  bool get adsRemoved => _settingsProvider.adsRemoved;

  /// Ürün fiyatı (App Store'dan çekilen)
  String get priceLabel => _product?.price ?? '₺79,99';

  // ─── Initialization ──────────────────────────────────────

  Future<void> _init() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('[IapService] Store not available');
      return;
    }

    // Satın alma stream'ini dinle
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('[IapService] Purchase stream error: $error');
      },
    );

    // Ürünleri sorgula
    await _queryProducts();
  }

  Future<void> _queryProducts() async {
    final response = await _iap.queryProductDetails(
      {AppConstants.iapRemoveAds},
    );

    if (response.error != null) {
      debugPrint('[IapService] Query error: ${response.error!.message}');
      _errorMessage = 'Ürün bilgileri alınamadı';
      notifyListeners();
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IapService] Product not found: ${response.notFoundIDs}');
    }

    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
      debugPrint('[IapService] Product loaded: ${_product!.id} - ${_product!.price}');
    }

    notifyListeners();
  }

  /// Ürün bilgilerini mağazadan tekrar sorgular
  Future<void> refreshProducts() async {
    if (!_isAvailable) {
      _isAvailable = await _iap.isAvailable();
    }
    if (_isAvailable) {
      await _queryProducts();
    }
  }

  // ─── Satın Alma ──────────────────────────────────────────

  /// "Reklamları Kaldır" satın alma akışını başlatır
  Future<void> purchaseRemoveAds() async {
    if (_product == null) {
      await refreshProducts();
      if (_product == null) {
        _errorMessage = 'Ürün bilgisi yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
        notifyListeners();
        return;
      }
    }

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: _product!);

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[IapService] Purchase error: $e');
      _isPurchasing = false;
      _errorMessage = 'Satın alma başlatılamadı';
      notifyListeners();
    }
  }

  /// Önceki satın alımları geri yükler
  Future<void> restorePurchases() async {
    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[IapService] Restore error: $e');
      _isPurchasing = false;
      _errorMessage = 'Geri yükleme başarısız oldu';
      notifyListeners();
    }
  }

  // ─── Purchase Stream Handler ─────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;

        case PurchaseStatus.error:
          debugPrint('[IapService] Purchase error: ${purchase.error?.message}');
          _isPurchasing = false;
          _errorMessage = 'Satın alma hatası oluştu';
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _errorMessage = null; // İptal edilen satın alma hata değil
          notifyListeners();
          break;

        case PurchaseStatus.pending:
          // Bekleyen satın alma — loading state devam
          break;
      }

      // Bekleyen işlemi tamamla (Apple için gerekli)
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _verifyAndDeliver(PurchaseDetails purchase) {
    if (purchase.productID == AppConstants.iapRemoveAds) {
      // Reklamları kaldır
      _settingsProvider.setAdsRemoved(true);
      AdService.instance.setAdsRemoved(true);
      _isPurchasing = false;
      _errorMessage = null;
      notifyListeners();
      debugPrint('[IapService] Ads removed successfully!');
    }
  }

  // ─── Dispose ──────────────────────────────────────────────

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
