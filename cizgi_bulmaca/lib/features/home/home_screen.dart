import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/game_provider.dart';
import '../../core/services/level_repository.dart';
import '../../core/services/settings_provider.dart';
import '../../models/difficulty.dart';

/// Çizgi Bulmaca — Ana Sayfa / Mod Seçim Ekranı
/// Kaldığın Yerden Devam Et hero kartı + Kolay, Orta, Zor mod kartları.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _titleTapCount = 0;
  DateTime? _lastTitleTapTime;

  void _onTitleTapped() {
    final now = DateTime.now();
    if (_lastTitleTapTime == null ||
        now.difference(_lastTitleTapTime!) > const Duration(seconds: 2)) {
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    _lastTitleTapTime = now;

    if (_titleTapCount >= 8) {
      _titleTapCount = 0;
      HapticFeedback.heavyImpact();
      final settingsProvider = context.read<SettingsProvider>();
      final isCurrentlyActive = settingsProvider.adsRemoved;
      final newStatus = !isCurrentlyActive;
      settingsProvider.setAdsRemoved(newStatus);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus ? Icons.workspace_premium_rounded : Icons.info_outline_rounded,
                color: newStatus ? AppColors.accent : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  newStatus
                      ? '👑 Geliştirici Modu: Premium Aktif Edildi!'
                      : 'ℹ️ Geliştirici Modu: Premium Kapatıldı (Test Modu)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: newStatus ? const Color(0xFF221F38) : Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final continueDiff = gameProvider.lastPlayedDifficulty;
    final continueLevel = gameProvider.lastPlayedLevel > 0
        ? gameProvider.lastPlayedLevel
        : gameProvider.lastUnlockedLevel(continueDiff);
    final continueLevelModel = LevelRepository.getLevel(continueDiff, continueLevel);
    final continueDifficultyModel = Difficulty.values[continueDiff.clamp(0, 2)];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Yıldız sayacı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${gameProvider.totalStars}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Başlık (8 kere tıklanınca Premium açar)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTitleTapped,
                    child: Text(
                      AppConstants.appName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Menü butonları
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/store'),
                        icon: const Icon(Icons.store_rounded),
                        tooltip: 'Mağaza',
                      ),
                      IconButton(
                        onPressed: () => context.push('/profile'),
                        icon: const Icon(Icons.person_rounded),
                        tooltip: 'Profil',
                      ),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_rounded),
                        tooltip: 'Ayarlar',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Hero: Kaldığın Yerden Devam Et ───
              _ContinueHeroCard(
                difficulty: continueDifficultyModel,
                levelNumber: continueLevel,
                levelName: continueLevelModel.name,
                onPlay: () => context.push('/game/$continueLevel?d=$continueDiff'),
              ),

              const SizedBox(height: 32),

              // Mod Seçim Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zorluk Modları',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '600+ Seviye',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mod Kartları
              _DifficultyCard(
                difficulty: Difficulty.easy,
                gradient: AppColors.easyGradient,
                icon: Icons.sentiment_satisfied_rounded,
                levelCount: AppConstants.easyLevelCount,
                unlockedLevel: gameProvider.lastUnlockedLevel(0),
                completedCount: gameProvider.completedLevelsCount(0),
                progress: gameProvider.progressForDifficulty(0),
                onTap: () => context.push('/levels/0'),
                onPlay: () => context.push('/game/${gameProvider.lastUnlockedLevel(0)}?d=0'),
              ),
              const SizedBox(height: 14),

              _DifficultyCard(
                difficulty: Difficulty.medium,
                gradient: AppColors.mediumGradient,
                icon: Icons.psychology_rounded,
                levelCount: AppConstants.mediumLevelCount,
                unlockedLevel: gameProvider.lastUnlockedLevel(1),
                completedCount: gameProvider.completedLevelsCount(1),
                progress: gameProvider.progressForDifficulty(1),
                onTap: () => context.push('/levels/1'),
                onPlay: () => context.push('/game/${gameProvider.lastUnlockedLevel(1)}?d=1'),
              ),
              const SizedBox(height: 14),

              _DifficultyCard(
                difficulty: Difficulty.hard,
                gradient: AppColors.hardGradient,
                icon: Icons.local_fire_department_rounded,
                levelCount: AppConstants.hardLevelCount,
                unlockedLevel: gameProvider.lastUnlockedLevel(2),
                completedCount: gameProvider.completedLevelsCount(2),
                progress: gameProvider.progressForDifficulty(2),
                onTap: () => context.push('/levels/2'),
                onPlay: () => context.push('/game/${gameProvider.lastUnlockedLevel(2)}?d=2'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kaldığın Yerden Devam Et Hero Kartı
class _ContinueHeroCard extends StatelessWidget {
  final Difficulty difficulty;
  final int levelNumber;
  final String levelName;
  final VoidCallback onPlay;

  const _ContinueHeroCard({
    required this.difficulty,
    required this.levelNumber,
    required this.levelName,
    required this.onPlay,
  });

  LinearGradient get _gradient {
    switch (difficulty) {
      case Difficulty.easy:
        return AppColors.easyGradient;
      case Difficulty.medium:
        return AppColors.mediumGradient;
      case Difficulty.hard:
        return AppColors.hardGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: _gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Küçük etiket
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'KALDIĞIN YERDEN DEVAM ET',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seviye ve Başlık
                  Text(
                    'Seviye $levelNumber',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${difficulty.labelTr} • $levelName',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Oyna Butonu
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 38,
                color: _gradient.colors.first,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zorluk modu kartı widget'ı
class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final LinearGradient gradient;
  final IconData icon;
  final int levelCount;
  final int unlockedLevel;
  final int completedCount;
  final double progress; // 0.0 - 1.0
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _DifficultyCard({
    required this.difficulty,
    required this.gradient,
    required this.icon,
    required this.levelCount,
    required this.unlockedLevel,
    required this.completedCount,
    required this.progress,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: Row(
            children: [
              // İkon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),

              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      difficulty.labelTr,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Seviye $unlockedLevel / $levelCount • $completedCount tamamlandı',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Oyna / Harita Butonu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Harita',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
