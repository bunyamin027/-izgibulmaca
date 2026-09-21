/// Çizgi Bulmaca — Zorluk Modu Enum
enum Difficulty {
  easy('Kolay', 'Easy'),
  medium('Orta', 'Medium'),
  hard('Zor', 'Hard');

  const Difficulty(this.labelTr, this.labelEn);
  final String labelTr;
  final String labelEn;
}
