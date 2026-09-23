import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_provider.dart';

/// Çizgi Bulmaca — Başarım Tanımı
class AchievementDef {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// Çizgi Bulmaca — Başarımlar Provider
/// Başarım koşullarını kontrol eder ve açılan başarımları kalıcı olarak saklar.
class AchievementProvider extends ChangeNotifier {
  final GameProvider _gameProvider;

  // Açılmış başarım ID'leri
  final Set<String> _unlockedIds = {};

  // Yeni açılan başarımlar (bildirim göstermek için)
  final List<String> _pendingNotifications = [];

  AchievementProvider(this._gameProvider) {
    _loadUnlocked();
    _gameProvider.addListener(_checkAchievements);
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_checkAchievements);
    super.dispose();
  }

  // ─── Başarım Listesi ──────────────────────────────────────

  static const List<AchievementDef> definitions = [
    AchievementDef(
      id: 'first_step',
      title: 'İlk Adım',
      subtitle: 'İlk level\'ı tamamla',
      icon: Icons.play_arrow_rounded,
      color: Color(0xFF3ADEB0),
    ),
    AchievementDef(
      id: 'star_hunter_10',
      title: 'Yıldız Toplayıcı',
      subtitle: '10 yıldız topla',
      icon: Icons.star_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'star_hunter_50',
      title: 'Yıldız Avcısı',
      subtitle: '50 yıldız topla',
      icon: Icons.star_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'star_hunter_100',
      title: 'Yıldız Ustası',
      subtitle: '100 yıldız topla',
      icon: Icons.stars_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'star_hunter_500',
      title: 'Yıldız Efsanesi',
      subtitle: '500 yıldız topla',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'speed_demon',
      title: 'Hız Şeytanı',
      subtitle: 'Bir level\'ı 5 saniyede tamamla',
      icon: Icons.speed_rounded,
      color: Color(0xFFFF6B35),
    ),
    AchievementDef(
      id: 'easy_master_10',
      title: 'Kolay Usta',
      subtitle: 'Kolay modda 10 level tamamla',
      icon: Icons.sentiment_satisfied_rounded,
      color: Color(0xFF3ADEB0),
    ),
    AchievementDef(
      id: 'easy_master_50',
      title: 'Kolay Uzman',
      subtitle: 'Kolay modda 50 level tamamla',
      icon: Icons.sentiment_satisfied_rounded,
      color: Color(0xFF3ADEB0),
    ),
    AchievementDef(
      id: 'medium_master_10',
      title: 'Orta Usta',
      subtitle: 'Orta modda 10 level tamamla',
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFAA33),
    ),
    AchievementDef(
      id: 'medium_master_50',
      title: 'Orta Uzman',
      subtitle: 'Orta modda 50 level tamamla',
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFAA33),
    ),
    AchievementDef(
      id: 'hard_master_10',
      title: 'Zor Usta',
      subtitle: 'Zor modda 10 level tamamla',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE040FB),
    ),
    AchievementDef(
      id: 'hard_master_50',
      title: 'Usta Çözücü',
      subtitle: 'Zor modda 50 level tamamla',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE040FB),
    ),
    AchievementDef(
      id: 'marathon_25',
      title: 'Maraton Koşucusu',
      subtitle: 'Toplam 25 level tamamla',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF2196F3),
    ),
    AchievementDef(
      id: 'marathon_100',
      title: 'Maraton Şampiyonu',
      subtitle: 'Toplam 100 level tamamla',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF2196F3),
    ),
    AchievementDef(
      id: 'hint_user',
      title: 'Akıllı Hamle',
      subtitle: 'İlk ipucunu kullan',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFF6C4CF5),
    ),
    AchievementDef(
      id: 'perfect_3',
      title: 'Mükemmeliyetçi',
      subtitle: 'Arka arkaya 3 level\'da 3 yıldız al',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFE91E8C),
    ),
  ];

  // ─── Getters ──────────────────────────────────────────────

  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);
  int get unlockedCount => _unlockedIds.length;
  int get totalCount => definitions.length;

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  /// Bildirim gösterilmeyi bekleyen başarımları tüketir
  List<AchievementDef> consumePendingNotifications() {
    final pending = _pendingNotifications
        .map((id) => definitions.firstWhere((d) => d.id == id))
        .toList();
    _pendingNotifications.clear();
    return pending;
  }

  bool get hasPendingNotifications => _pendingNotifications.isNotEmpty;

  // ─── Başarım Kontrolü ─────────────────────────────────────

  void _checkAchievements() {
    final gp = _gameProvider;
    final totalCompleted = gp.completedLevelsCount(0) +
        gp.completedLevelsCount(1) +
        gp.completedLevelsCount(2);

    // İlk Adım
    if (totalCompleted >= 1) _unlock('first_step');

    // Yıldız Toplayıcı
    if (gp.totalStars >= 10) _unlock('star_hunter_10');
    if (gp.totalStars >= 50) _unlock('star_hunter_50');
    if (gp.totalStars >= 100) _unlock('star_hunter_100');
    if (gp.totalStars >= 500) _unlock('star_hunter_500');

    // Kolay Usta
    if (gp.completedLevelsCount(0) >= 10) _unlock('easy_master_10');
    if (gp.completedLevelsCount(0) >= 50) _unlock('easy_master_50');

    // Orta Usta
    if (gp.completedLevelsCount(1) >= 10) _unlock('medium_master_10');
    if (gp.completedLevelsCount(1) >= 50) _unlock('medium_master_50');

    // Zor Usta
    if (gp.completedLevelsCount(2) >= 10) _unlock('hard_master_10');
    if (gp.completedLevelsCount(2) >= 50) _unlock('hard_master_50');

    // Maraton
    if (totalCompleted >= 25) _unlock('marathon_25');
    if (totalCompleted >= 100) _unlock('marathon_100');
  }

  /// Hız Şeytanı — 5 saniye altında tamamlama (game_screen'den çağrılacak)
  void checkSpeedDemon(int timeMs) {
    if (timeMs > 0 && timeMs <= 5000) {
      _unlock('speed_demon');
    }
  }

  /// İpucu kullanımı (game_screen'den çağrılacak)
  void checkHintUsed() {
    _unlock('hint_user');
  }

  /// Arka arkaya 3 mükemmel skor (game_screen'den çağrılacak)
  void checkPerfectStreak(int consecutivePerfects) {
    if (consecutivePerfects >= 3) {
      _unlock('perfect_3');
    }
  }

  // ─── Internal ─────────────────────────────────────────────

  void _unlock(String id) {
    if (_unlockedIds.contains(id)) return;
    _unlockedIds.add(id);
    _pendingNotifications.add(id);
    notifyListeners();
    _saveUnlocked();
  }

  Future<void> _saveUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('achievements_unlocked', _unlockedIds.toList());
  }

  Future<void> _loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('achievements_unlocked');
    if (list != null) {
      _unlockedIds.addAll(list);
      notifyListeners();
    }
  }
}
