import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/settings_provider.dart';

/// Çizgi Bulmaca — Zorluk Modu Enum
enum Difficulty {
  easy('Kolay', 'Easy'),
  medium('Orta', 'Medium'),
  hard('Zor', 'Hard');

  const Difficulty(this.labelTr, this.labelEn);
  final String labelTr;
  final String labelEn;

  /// Aktif BuildContext ve SettingsProvider'a göre reaktif isim döndürür
  String localized(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return locale == 'en' ? labelEn : labelTr;
  }

  /// Belirli bir locale koduna göre isim döndürür
  String localizedFor(String locale) {
    return locale == 'en' ? labelEn : labelTr;
  }
}

