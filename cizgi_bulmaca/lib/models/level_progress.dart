/// Çizgi Bulmaca — Level İlerleme Modeli
/// Kullanıcının her level'daki ilerleme durumunu tutar.
class LevelProgress {
  final int levelId;
  final bool isCompleted;
  final int stars;         // 0-3 arası
  final int bestMoves;     // En az hamle
  final int bestTimeMs;    // En iyi süre (ms)
  final int attempts;      // Deneme sayısı

  const LevelProgress({
    required this.levelId,
    this.isCompleted = false,
    this.stars = 0,
    this.bestMoves = 0,
    this.bestTimeMs = 0,
    this.attempts = 0,
  });

  LevelProgress copyWith({
    bool? isCompleted,
    int? stars,
    int? bestMoves,
    int? bestTimeMs,
    int? attempts,
  }) {
    return LevelProgress(
      levelId: levelId,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      bestMoves: bestMoves ?? this.bestMoves,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      attempts: attempts ?? this.attempts,
    );
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestMoves: json['bestMoves'] as int? ?? 0,
      bestTimeMs: json['bestTimeMs'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'isCompleted': isCompleted,
        'stars': stars,
        'bestMoves': bestMoves,
        'bestTimeMs': bestTimeMs,
        'attempts': attempts,
      };
}
