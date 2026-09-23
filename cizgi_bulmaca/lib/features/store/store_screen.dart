import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/iap_service.dart';

/// Çizgi Bulmaca — Mağaza / Reklamları Kaldır Ekranı
/// Tek IAP kartı, fiyat, Satın Al + Satın Alımları Geri Yükle + Yasal Linkler.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iapService = context.watch<IapService>();
    final alreadyPurchased = iapService.adsRemoved;

    // Ürün henüz yüklenmediyse arka planda mağazadan sorgula
    if (!alreadyPurchased && iapService.product == null && !iapService.isPurchasing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<IapService>().refreshProducts();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Premium Kart
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingXL),
                decoration: BoxDecoration(
                  gradient: alreadyPurchased
                      ? const LinearGradient(
                          colors: [Color(0xFF3ADEB0), Color(0xFF2BC4A0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (alreadyPurchased ? AppColors.secondary : AppColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      alreadyPurchased
                          ? Icons.check_circle_rounded
                          : Icons.workspace_premium_rounded,
                      size: 64,
                      color: alreadyPurchased ? Colors.white : AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      alreadyPurchased ? 'Premium Aktif!' : 'Reklamları Kaldır',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alreadyPurchased
                          ? 'Reklamsız deneyimin aktif. Keyifle oyna!'
                          : 'Reklamlar olmadan kesintisiz oyna.\nTek seferlik ödeme, süresiz erişim.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (!alreadyPurchased) ...[
                      // Özellik listesi
                      const _FeatureRow(icon: Icons.block, text: 'Tüm reklamlar kaldırılır'),
                      const SizedBox(height: 8),
                      const _FeatureRow(icon: Icons.all_inclusive, text: 'Süresiz erişim'),
                      const SizedBox(height: 8),
                      const _FeatureRow(icon: Icons.devices, text: 'Tüm cihazlarınızda geçerli'),

                      const SizedBox(height: 32),

                      // Hata mesajı
                      if (iapService.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            iapService.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Satın Al Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: iapService.isPurchasing
                              ? null
                              : () => iapService.purchaseRemoveAds(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: iapService.isPurchasing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  'Satın Al — ${iapService.priceLabel}',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      // Zaten satın alınmış durumda
                      const _FeatureRow(icon: Icons.check, text: 'Reklamlar kaldırıldı ✓'),
                      const SizedBox(height: 8),
                      const _FeatureRow(icon: Icons.check, text: 'Süresiz erişim aktif ✓'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Geri Yükle Butonu
              if (!alreadyPurchased)
                TextButton.icon(
                  onPressed: iapService.isPurchasing
                      ? null
                      : () {
                          iapService.restorePurchases();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Satın alımlar kontrol ediliyor...'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  label: Text(
                    'Satın Alımları Geri Yükle',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Yasal Linkler: Gizlilik Politikası & Kullanım Koşulları (EULA)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                    child: Text(
                      'Gizlilik Politikası',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _launchUrl(AppConstants.termsOfUseUrl),
                    child: Text(
                      'Kullanım Koşulları (EULA)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
