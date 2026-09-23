import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Çizgi Bulmaca — Ses Efektleri Servisi
/// Oyun içi ses efektlerini yönetir.
/// SettingsProvider'daki soundEnabled ayarına uyar.
///
/// Ses dosyaları assets/sounds/ altında yer alır.
/// Hata durumlarında sessizce geçer, oyunu asla bloklamaz.
class SoundService {
  SoundService._() {
    _initPlayer();
  }

  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;

  bool _enabled = true;
  final AudioPlayer _player = AudioPlayer();

  void _initPlayer() {
    try {
      _player.setReleaseMode(ReleaseMode.stop);
      _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('[SoundService] Init error: $e');
    }
  }

  /// Ses aktif/deaktif durumunu güncelle
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Düğüm bağlama sesi
  Future<void> playNodeConnect() async {
    await _playSound('sounds/connect.wav');
  }

  /// Level tamamlama sesi
  Future<void> playLevelComplete() async {
    await _playSound('sounds/complete.wav');
  }

  /// İpucu kullanma sesi
  Future<void> playHint() async {
    await _playSound('sounds/hint.wav');
  }

  /// Hata / yanlış hamle sesi
  Future<void> playError() async {
    await _playSound('sounds/error.wav');
  }

  /// Yıldız kazanma sesi
  Future<void> playStar() async {
    await _playSound('sounds/hint.wav');
  }

  /// Buton tıklama sesi
  Future<void> playTap() async {
    await _playSound('sounds/tap.wav');
  }

  // ─── Internal ─────────────────────────────────────────────

  Future<void> _playSound(String assetPath) async {
    if (!_enabled) return;

    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath), volume: 0.7);
    } catch (e) {
      // Ses çalma hatası — sessizce geç, oyunu asla bloklamaz
      debugPrint('[SoundService] Play error ($assetPath): $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
