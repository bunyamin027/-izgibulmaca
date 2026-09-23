import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/settings_provider.dart';
import '../../core/services/iap_service.dart';

/// Çizgi Bulmaca — Ayarlar Ekranı
/// Tema rengi seçici, koyu/açık mod, dil, ses/haptic, Gizlilik/Koşullar linkleri.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        children: [
          // ─── Görünüm ──────────────────────────────
          _SectionHeader(title: 'Görünüm'),
          const SizedBox(height: 8),

          // Koyu/Açık Mod
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Koyu Mod',
            trailing: Switch.adaptive(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Tema Rengi
          _SettingsTile(
            icon: Icons.palette_rounded,
            title: 'Tema Rengi',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showColorPicker(context, themeProvider),
          ),

          const SizedBox(height: 24),

          // ─── Genel ────────────────────────────────
          _SectionHeader(title: 'Genel'),
          const SizedBox(height: 8),

          // Ses
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Ses Efektleri',
            trailing: Switch.adaptive(
              value: settingsProvider.soundEnabled,
              onChanged: (v) => settingsProvider.setSoundEnabled(v),
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Titreşim
          _SettingsTile(
            icon: Icons.vibration_rounded,
            title: 'Titreşim',
            trailing: Switch.adaptive(
              value: settingsProvider.hapticEnabled,
              onChanged: (v) => settingsProvider.setHapticEnabled(v),
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // ─── Satın Alma ───────────────────────────
          _SectionHeader(title: 'Satın Alma'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.remove_circle_outline_rounded,
            title: 'Reklamları Kaldır',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/store'),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.restore_rounded,
            title: 'Satın Alımları Geri Yükle',
            onTap: () {
              context.read<IapService>().restorePurchases();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Satın alımlar kontrol ediliyor...')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ─── Hakkında ─────────────────────────────
          _SectionHeader(title: 'Hakkında'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Gizlilik Politikası',
            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.description_rounded,
            title: 'Kullanım Koşulları (EULA)',
            onTap: () => _launchUrl(AppConstants.termsOfUseUrl),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.mail_outline_rounded,
            title: 'Destek ve Geri Bildirim',
            trailing: Text(
              AppConstants.supportEmail,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            onTap: () => _launchUrl('mailto:${AppConstants.supportEmail}?subject=Cizgi%20Bulmaca%20Destek'),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Versiyon',
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logo & Telif
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 44,
                    height: 44,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '© 2026 Kahramanapp • Tüm Hakları Saklıdır',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tema Rengi Seç', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: AppColors.themePresets.map((color) {
                  final isSelected = provider.primaryColor == color;
                  return GestureDetector(
                    onTap: () {
                      provider.setPrimaryColor(color);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS + 4,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: AppTextStyles.titleMedium),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
