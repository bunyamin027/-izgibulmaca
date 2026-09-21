import 'dart:math';
import 'dart:ui';
import '../../models/level_model.dart';

/// Çizgi Bulmaca — Level Deposu & Seviye Üreticisi
/// Tüm seviyelerin (1-200) Euler çizgisi (tek hamlede çizilebilir) kuralına
/// %100 uygun olmasını matematiksel olarak garanti eder.
class LevelRepository {
  LevelRepository._();

  /// Belirli bir zorluk ve level numarası için LevelModel döner
  static LevelModel getLevel(int difficulty, int levelId) {
    if (difficulty == 0 && levelId <= _easyHandcrafted.length) {
      return _easyHandcrafted[levelId - 1];
    }
    if (difficulty == 1 && levelId <= _mediumHandcrafted.length) {
      return _mediumHandcrafted[levelId - 1];
    }
    if (difficulty == 2 && levelId <= _hardHandcrafted.length) {
      return _hardHandcrafted[levelId - 1];
    }

    // El yapımı seviye sınırını aşanlar için matematiksel Euler üreticisi
    return _generateProceduralLevel(difficulty, levelId);
  }

  // ──────────────────────────────────────────────────────────
  // 1. KOLAY MOD — El Yapımı İkonik Seviyeler (Euler Garantili)
  // ──────────────────────────────────────────────────────────

  static final List<LevelModel> _easyHandcrafted = [
    // Seviye 1: Üçgen (3 düğüm, 3 kenar - tüm dereceler 2)
    const LevelModel(
      id: 1,
      name: 'Üçgen',
      nodes: [
        Offset(0.5, 0.2),
        Offset(0.2, 0.75),
        Offset(0.8, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 0],
      ],
      difficulty: 0,
      parMoves: 3,
    ),

    // Seviye 2: Kum Saati / Papyon (5 düğüm, 6 kenar - tüm dereceler çift)
    const LevelModel(
      id: 2,
      name: 'Kum Saati',
      nodes: [
        Offset(0.25, 0.25),
        Offset(0.75, 0.25),
        Offset(0.5, 0.5),
        Offset(0.25, 0.75),
        Offset(0.75, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 0], // Üst üçgen
        [2, 3], [3, 4], [4, 2], // Alt üçgen
      ],
      difficulty: 0,
      parMoves: 6,
    ),

    // Seviye 3: Kare + Çapraz (4 düğüm, 5 kenar - 2 tek derece)
    const LevelModel(
      id: 3,
      name: 'Kare Çapraz',
      nodes: [
        Offset(0.25, 0.25),
        Offset(0.75, 0.25),
        Offset(0.75, 0.75),
        Offset(0.25, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 0], [0, 2],
      ],
      difficulty: 0,
      parMoves: 5,
    ),

    // Seviye 4: Kelebek (6 düğüm, 7 kenar - 2 tek derece)
    const LevelModel(
      id: 4,
      name: 'Kelebek',
      nodes: [
        Offset(0.2, 0.25),
        Offset(0.35, 0.5),
        Offset(0.2, 0.75),
        Offset(0.65, 0.5),
        Offset(0.8, 0.25),
        Offset(0.8, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 0], // Sol kanat
        [1, 3],                 // Gövde köprüsü
        [3, 4], [4, 5], [5, 3], // Sağ kanat
      ],
      difficulty: 0,
      parMoves: 7,
    ),

    // Seviye 5: Klasik Ev (5 düğüm, 8 kenar - 2 tek derece: alt köşeler)
    const LevelModel(
      id: 5,
      name: 'Ev',
      nodes: [
        Offset(0.5, 0.15), // Çatı
        Offset(0.2, 0.45), // Sol üst
        Offset(0.8, 0.45), // Sağ üst
        Offset(0.2, 0.8),  // Sol alt
        Offset(0.8, 0.8),  // Sağ alt
      ],
      edges: [
        [0, 1], [0, 2], [1, 2],
        [1, 3], [2, 4], [3, 4],
        [1, 4], [2, 3],
      ],
      difficulty: 0,
      parMoves: 8,
    ),

    // Seviye 6: Mektup Zarfı (5 düğüm, 8 kenar)
    const LevelModel(
      id: 6,
      name: 'Mektup Zarfı',
      nodes: [
        Offset(0.2, 0.4),  // Sol üst
        Offset(0.8, 0.4),  // Sağ üst
        Offset(0.8, 0.8),  // Sağ alt
        Offset(0.2, 0.8),  // Sol alt
        Offset(0.5, 0.15), // Kapak ucu
      ],
      edges: [
        [0, 4], [4, 1],
        [0, 1], [1, 2], [2, 3], [3, 0],
        [0, 2], [1, 3],
      ],
      difficulty: 0,
      parMoves: 8,
    ),

    // Seviye 7: Sevimli Balık (6 düğüm, 8 kenar)
    const LevelModel(
      id: 7,
      name: 'Balık',
      nodes: [
        Offset(0.15, 0.5),  // Burun
        Offset(0.45, 0.28), // Üst sırt
        Offset(0.45, 0.72), // Karın
        Offset(0.65, 0.5),  // Kuyruk sokumu
        Offset(0.85, 0.3),  // Kuyruk üst
        Offset(0.85, 0.7),  // Kuyruk alt
      ],
      edges: [
        [0, 1], [1, 2], [2, 0],
        [1, 3], [3, 2],
        [3, 4], [4, 5], [5, 3],
      ],
      difficulty: 0,
      parMoves: 8,
    ),

    // Seviye 8: Yıldız (5 düğüm, 10 kenar - tüm dereceler 4)
    const LevelModel(
      id: 8,
      name: 'Yıldız',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.82, 0.38),
        Offset(0.7, 0.78),
        Offset(0.3, 0.78),
        Offset(0.18, 0.38),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 0], // Dış halka
        [0, 2], [2, 4], [4, 1], [1, 3], [3, 0], // İç yıldız
      ],
      difficulty: 0,
      parMoves: 10,
    ),

    // Seviye 9: Elmas Kristal (6 düğüm, 12 kenar - tüm dereceler 4)
    const LevelModel(
      id: 9,
      name: 'Kristal Elmas',
      nodes: [
        Offset(0.5, 0.15),  // Tepe 0
        Offset(0.2, 0.5),   // Sol 1
        Offset(0.5, 0.38),  // Orta üst 2
        Offset(0.8, 0.5),   // Sağ 3
        Offset(0.5, 0.62),  // Orta alt 4
        Offset(0.5, 0.85),  // Dip 5
      ],
      edges: [
        [0, 1], [0, 2], [0, 3], [0, 4], // Tepe piramidi
        [1, 2], [2, 3], [3, 4], [4, 1], // Orta halka
        [5, 1], [5, 2], [5, 3], [5, 4], // Taban piramidi
      ],
      difficulty: 0,
      parMoves: 12,
    ),

    // Seviye 10: Roket (7 düğüm, 12 kenar)
    const LevelModel(
      id: 10,
      name: 'Uzay Roketi',
      nodes: [
        Offset(0.5, 0.12), // Burun
        Offset(0.35, 0.35),
        Offset(0.65, 0.35),
        Offset(0.35, 0.68),
        Offset(0.65, 0.68),
        Offset(0.15, 0.85), // Sol kanat
        Offset(0.85, 0.85), // Sağ kanat
      ],
      edges: [
        [0, 1], [1, 2], [2, 0],
        [1, 3], [3, 4], [4, 2],
        [1, 4], [2, 3],
        [3, 5], [5, 4],
        [4, 6], [6, 3],
      ],
      difficulty: 0,
      parMoves: 12,
    ),

    // Seviye 11: Altıgen Yıldız (6 düğüm, 12 kenar - tüm dereceler 4)
    const LevelModel(
      id: 11,
      name: 'Altıgen Yıldız',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.8, 0.32),
        Offset(0.8, 0.68),
        Offset(0.5, 0.85),
        Offset(0.2, 0.68),
        Offset(0.2, 0.32),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0], // Dış altıgen
        [0, 2], [2, 4], [4, 0],                         // 1. Üçgen
        [1, 3], [3, 5], [5, 1],                         // 2. Üçgen
      ],
      difficulty: 0,
      parMoves: 12,
    ),

    // Seviye 12: Yelkenli Gemi (6 düğüm, 9 kenar - 2 tek derece)
    const LevelModel(
      id: 12,
      name: 'Yelkenli',
      nodes: [
        Offset(0.5, 0.18),  // Direk tepesi 0
        Offset(0.2, 0.6),   // Sol yelken ucu 1
        Offset(0.5, 0.6),   // Direk tabanı 2
        Offset(0.8, 0.6),   // Sağ yelken ucu 3
        Offset(0.25, 0.82), // Gövde sol alt 4
        Offset(0.75, 0.82), // Gövde sağ alt 5
      ],
      edges: [
        [0, 1], [0, 2], [0, 3], // Direk ve dış yelkenler
        [1, 2], [2, 3],         // Yelken tabanları
        [1, 3],                 // Yatay kiriş
        [1, 4], [4, 5], [5, 3], // Gövde
      ],
      difficulty: 0,
      parMoves: 9,
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // 2. ORTA MOD — El Yapımı Seviyeler
  // ──────────────────────────────────────────────────────────

  static final List<LevelModel> _mediumHandcrafted = [
    const LevelModel(
      id: 1,
      name: 'Elmas Kafes',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.2, 0.5),
        Offset(0.8, 0.5),
        Offset(0.5, 0.85),
        Offset(0.5, 0.5),
      ],
      edges: [
        [0, 1], [0, 2], [1, 3], [2, 3],
        [0, 4], [3, 4], [1, 4], [2, 4],
        [1, 2],
      ],
      difficulty: 1,
      parMoves: 9,
    ),
    const LevelModel(
      id: 2,
      name: 'Kale Kulesi',
      nodes: [
        Offset(0.5, 0.15), // Çatı tepe 0
        Offset(0.3, 0.35), // Sol kule üst 1
        Offset(0.7, 0.35), // Sağ kule üst 2
        Offset(0.3, 0.65), // Sol gövde 3
        Offset(0.7, 0.65), // Sağ gövde 4
        Offset(0.2, 0.85), // Sol taban 5
        Offset(0.8, 0.85), // Sağ taban 6
      ],
      edges: [
        [0, 1], [0, 2], [1, 2],
        [1, 3], [2, 4], [3, 4], [1, 4], [2, 3],
        [3, 5], [5, 6], [6, 4],
      ],
      difficulty: 1,
      parMoves: 11,
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // 3. ZOR MOD — El Yapımı Seviyeler
  // ──────────────────────────────────────────────────────────

  static final List<LevelModel> _hardHandcrafted = [
    const LevelModel(
      id: 1,
      name: 'Usta Düğümü',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.8, 0.3),
        Offset(0.85, 0.65),
        Offset(0.65, 0.85),
        Offset(0.35, 0.85),
        Offset(0.15, 0.65),
        Offset(0.2, 0.3),
        Offset(0.5, 0.5),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 0],
        [0, 7], [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7],
        [0, 3], [1, 4], [2, 5],
      ],
      difficulty: 2,
      parMoves: 17,
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // 4. MATEMATİKSEL EULER PROSEDÜREL SEVİYE ÜRETİCİSİ
  // Seviye 13-200 ve sonrası için %100 çözülebilir grafikler üretir.
  // ──────────────────────────────────────────────────────────

  static LevelModel _generateProceduralLevel(int difficulty, int levelId) {
    final rng = Random(levelId * 31337 + difficulty * 7919);

    // Düğüm sayısı: Kolay modda 4-7, Orta modda 6-9, Zor modda 8-11
    final minNodes = 4 + difficulty * 2;
    final maxNodes = 6 + difficulty * 3;
    final nodeCount = minNodes + (levelId % (maxNodes - minNodes + 1));

    // Düğümleri estetik geometrik çember/elips formunda oluştur
    final List<Offset> nodes = [];
    final center = const Offset(0.5, 0.5);
    final radius = 0.32 + (rng.nextDouble() * 0.05);

    // Düğümleri dairesel açıyla yerleştir
    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi * i / nodeCount) - (pi / 2);
      final jitter = (rng.nextDouble() - 0.5) * 0.06;
      final r = radius + jitter;
      final x = (center.dx + r * cos(angle)).clamp(0.15, 0.85);
      final y = (center.dy + r * sin(angle)).clamp(0.18, 0.82);
      nodes.add(Offset(x, y));
    }

    // 1. Temel Döngü (Euler Circuit): Her düğümün derecesi 2 (ÇİFT)
    final Set<String> edgeSet = {};
    void addEdge(int u, int v) {
      if (u == v) return;
      final a = min(u, v);
      final b = max(u, v);
      edgeSet.add('$a-$b');
    }

    bool hasEdge(int u, int v) {
      final a = min(u, v);
      final b = max(u, v);
      return edgeSet.contains('$a-$b');
    }

    for (int i = 0; i < nodeCount; i++) {
      addEdge(i, (i + 1) % nodeCount);
    }

    // 2. Ek Döngüler (Üçgenler eklemek her düğümün derecesini +2 artırır, çift kalır)
    final extraTriangles = 1 + difficulty + (levelId % 3);
    for (int t = 0; t < extraTriangles; t++) {
      final a = rng.nextInt(nodeCount);
      int b = (a + 1 + rng.nextInt(nodeCount - 1)) % nodeCount;
      int c = (b + 1 + rng.nextInt(nodeCount - 1)) % nodeCount;
      if (a != b && b != c && c != a) {
        if (!hasEdge(a, b) && !hasEdge(b, c) && !hasEdge(c, a)) {
          addEdge(a, b);
          addEdge(b, c);
          addEdge(c, a);
        }
      }
    }

    // 3. Tek dereceli düğüm ekleme (isteğe bağlı 1 kiriş ile tam 2 tek derece oluşturma)
    if (levelId % 2 == 1) {
      for (int i = 0; i < nodeCount; i++) {
        final j = (i + 2 + rng.nextInt(max(1, nodeCount - 3))) % nodeCount;
        if (!hasEdge(i, j)) {
          addEdge(i, j);
          break;
        }
      }
    }

    // Kenarları listeye dönüştür
    final List<List<int>> edges = edgeSet.map((e) {
      final parts = e.split('-');
      return [int.parse(parts[0]), int.parse(parts[1])];
    }).toList();

    // İsim havuzu
    final names = [
      'Göktaşı', 'Kalkan', 'Pusula', 'Fener', 'Rüzgar Gülü',
      'Taç', 'Girdap', 'Piramit', 'Köprü', 'Akrep',
      'Kartal', 'Uçurtma', 'Labirent', 'Sonsuzluk', 'Geometri',
    ];
    final levelName = names[(levelId + difficulty * 5) % names.length];

    return LevelModel(
      id: levelId,
      name: '$levelName #$levelId',
      nodes: nodes,
      edges: edges,
      difficulty: difficulty,
      parMoves: edges.length,
    );
  }
}
