import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        children: [
          // ─── Görünüm ──────────────────────────────
          _SectionHeader(title: l10n.appearance),
          const SizedBox(height: 8),

          // Koyu/Açık Mod
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: l10n.darkMode,
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
            title: l10n.themeColor,
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showColorPicker(context, themeProvider, l10n),
          ),

          const SizedBox(height: 24),

          // ─── Genel ────────────────────────────────
          _SectionHeader(title: l10n.general),
          const SizedBox(height: 8),

          // Dil Seçimi
          _SettingsTile(
            icon: Icons.language_rounded,
            title: l10n.language,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  settingsProvider.locale == 'en' ? 'English' : 'Türkçe',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ],
            ),
            onTap: () => _showLanguagePicker(context, settingsProvider, l10n),
          ),
          const SizedBox(height: 8),

          // Ses
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: l10n.soundEffects,
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
            title: l10n.haptic,
            trailing: Switch.adaptive(
              value: settingsProvider.hapticEnabled,
              onChanged: (v) => settingsProvider.setHapticEnabled(v),
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // ─── Satın Alma ───────────────────────────
          _SectionHeader(title: l10n.purchases),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.remove_circle_outline_rounded,
            title: l10n.removeAds,
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/store'),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.restore_rounded,
            title: l10n.restorePurchases,
            onTap: () {
              context.read<IapService>().restorePurchases();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.checkingPurchases)),
              );
            },
          ),

          const SizedBox(height: 24),

          // ─── Hakkında ─────────────────────────────
          _SectionHeader(title: l10n.about),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: l10n.privacyPolicy,
            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.description_rounded,
            title: l10n.termsOfUse,
            onTap: () => _launchUrl(AppConstants.termsOfUseUrl),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.mail_outline_rounded,
            title: l10n.supportAndFeedback,
            trailing: Text(
              AppConstants.supportEmail,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            onTap: () => _launchUrl(
              'mailto:${AppConstants.supportEmail}?subject=${Uri.encodeComponent('${l10n.appName} Destek / Support')}',
            ),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: l10n.version,
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                  l10n.appName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '© 2026 Kahramanapp • All Rights Reserved',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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

  void _showLanguagePicker(
    BuildContext context,
    SettingsProvider settingsProvider,
    AppStrings l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder: (ctx) {
        final currentLocale = settingsProvider.locale;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectLanguage,
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 20),

              // Türkçe Seçeneği
              _LanguageOptionTile(
                flag: '🇹🇷',
                title: 'Türkçe',
                subtitle: 'Turkish',
                isSelected: currentLocale == 'tr',
                onTap: () {
                  settingsProvider.setLocale('tr');
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 12),

              // İngilizce Seçeneği
              _LanguageOptionTile(
                flag: '🇬🇧',
                title: 'English',
                subtitle: 'İngilizce',
                isSelected: currentLocale == 'en',
                onTap: () {
                  settingsProvider.setLocale('en');
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider provider, AppStrings l10n) {
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
              Text(l10n.themeColor, style: AppTextStyles.headlineSmall),
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

class _LanguageOptionTile extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? primaryColor : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 24),
          ],
        ),
      ),
    );
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
