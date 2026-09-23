import 'package:flutter/services.dart';

/// Çizgi Bulmaca — Haptic Feedback Servisi
/// Titreşim geri bildirimlerini merkezi olarak yönetir.
/// SettingsProvider'daki hapticEnabled ayarına uyar.
class HapticService {
  HapticService._();

  static bool _enabled = true;

  /// Haptic aktif/deaktif durumunu güncelle
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Düğüm seçme — çok hafif titreşim
  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Kenar çizme — hafif titreşim
  static void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Level sıfırlama — orta titreşim
  static void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Level tamamlama — güçlü titreşim
  static void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
