import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/settings_provider.dart';

/// Çizgi Bulmaca — Onboarding Ekranı
/// 3 ekranlık kaydırmalı tanıtım (ilk açılışta).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> _getPages(AppStrings l10n) => [
    _OnboardingPage(
      icon: Icons.gesture,
      title: l10n.onboarding1Title,
      subtitle: l10n.onboarding1Subtitle,
      gradient: AppColors.primaryGradient,
    ),
    _OnboardingPage(
      icon: Icons.tune,
      title: l10n.onboarding2Title,
      subtitle: l10n.onboarding2Subtitle,
      gradient: AppColors.easyGradient,
    ),
    _OnboardingPage(
      icon: Icons.star_rounded,
      title: l10n.onboarding3Title,
      subtitle: l10n.onboarding3Subtitle,
      gradient: AppColors.hardGradient,
    ),
  ];

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: AppConstants.pageTransition,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    context.read<SettingsProvider>().setOnboardingCompleted(true);
    context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _getPages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Geç butonu
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l10n.skip,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Sayfalar
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingXL,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkon (gradient container içinde)
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: page.gradient,
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Başlık
                        Text(
                          page.title,
                          style: AppTextStyles.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Açıklama
                        Text(
                          page.subtitle,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicator + İleri butonu
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicator
                  Row(
                    children: List.generate(pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: AppConstants.shortAnimation,
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // İleri butonu
                  ElevatedButton(
                    onPressed: () => _nextPage(pages.length),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _currentPage < pages.length - 1 ? l10n.next : l10n.start,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
