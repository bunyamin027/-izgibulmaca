import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/game_provider.dart';
import '../../core/services/settings_provider.dart';
import '../../core/services/achievement_provider.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/level_repository.dart';
import '../../core/services/euler_solver.dart';
import '../../models/level_model.dart';

/// Çizgi Bulmaca — Oynanış Ekranı
/// Parmağını kaldırmadan düğümler arasında çizgi çiz.
class GameScreen extends StatefulWidget {
  final int levelId;
  final int difficulty;

  const GameScreen({super.key, required this.levelId, this.difficulty = 0});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // Level verileri
  late LevelModel _currentLevel;
  late List<Offset> _nodes;       // Normalize edilmiş koordinatlar (0-1)
  late List<List<int>> _edges;    // Kenar bağlantıları
  
  // Oyun durumu
  final List<int> _visitedNodes = [];
  final List<List<int>> _drawnEdges = [];
  int? _activeNode;
  int _moveCount = 0;
  bool _isCompleted = false;
  bool _isDragging = false;
  Offset? _currentDragPos;        // Sürükleme sırasındaki parmak pozisyonu
  List<int>? _lastHintEdge;       // İpucu ile çizilen son kenar
  List<int> _validStartNodes = []; // Seviyenin geçerli başlangıç düğümleri
  List<List<int>>? _ghostEdges;   // Kılavuz / önizleme adımları
  Timer? _ghostTimer;             // Kılavuz otomatik kapanma zamanlayıcısı

  // Süre ölçümü
  final Stopwatch _stopwatch = Stopwatch();
  int _elapsedMs = 0;

  // Mükemmel seri takibi
  static int _consecutivePerfects = 0;

  // Çizim alanı boyutları (LayoutBuilder'dan)
  Size _canvasSize = Size.zero;

  // Node hit radius (piksel)
  static const double _nodeHitRadius = 36.0;

  // Animasyon
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _stopwatch.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameProvider>().setLastPlayed(widget.difficulty, widget.levelId);
        _syncSettings();
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelId != widget.levelId || oldWidget.difficulty != widget.difficulty) {
      _resetLevel();
      _initLevel();
      _stopwatch.reset();
      _stopwatch.start();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GameProvider>().setLastPlayed(widget.difficulty, widget.levelId);
        }
      });
    }
  }

  @override
  void dispose() {
    _ghostTimer?.cancel();
    _pulseController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _initLevel() {
    _currentLevel = LevelRepository.getLevel(widget.difficulty, widget.levelId);
    _nodes = _currentLevel.nodes;
    _edges = _currentLevel.edges;
    _validStartNodes = EulerSolver.getValidStartNodes(_nodes.length, _edges);
    _ghostEdges = null;
    _ghostTimer?.cancel();
  }

  /// Ses ve haptic ayarlarını provider'dan senkronize et
  void _syncSettings() {
    final settings = context.read<SettingsProvider>();
    HapticService.setEnabled(settings.hapticEnabled);
    SoundService.instance.setEnabled(settings.soundEnabled);
  }

  /// Normalize edilmiş koordinatı piksel pozisyonuna çevir
  Offset _nodeToPixel(Offset node) {
    // Canvas'ın kare bölgesini ortala
    final side = min(_canvasSize.width, _canvasSize.height) * 0.85;
    final offsetX = (_canvasSize.width - side) / 2;
    final offsetY = (_canvasSize.height - side) / 2;
    return Offset(
      offsetX + node.dx * side,
      offsetY + node.dy * side,
    );
  }

  /// Verilen piksel pozisyonuna en yakın düğümü bul (hit radius içinde)
  int? _findNodeAt(Offset position) {
    for (int i = 0; i < _nodes.length; i++) {
      final nodePos = _nodeToPixel(_nodes[i]);
      final distance = (position - nodePos).distance;
      if (distance <= _nodeHitRadius) {
        return i;
      }
    }
    return null;
  }

  /// Geçen süreyi formatla (MM:SS)
  String get _formattedTime {
    final ms = _stopwatch.elapsedMilliseconds;
    final seconds = (ms ~/ 1000) % 60;
    final minutes = (ms ~/ 1000) ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── Dokunma Olayları ────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;

    final localPos = details.localPosition;
    final hitNode = _findNodeAt(localPos);

    if (hitNode != null) {
      // Hafif haptic feedback
      HapticService.selection();

      setState(() {
        _lastHintEdge = null;
        if (_visitedNodes.isEmpty) {
          // İlk düğüm: çizime başla
          _visitedNodes.add(hitNode);
          _activeNode = hitNode;
          _isDragging = true;
          _currentDragPos = _nodeToPixel(_nodes[hitNode]);
        } else if (hitNode == _activeNode) {
          // Aynı aktif düğümden devam et
          _isDragging = true;
          _currentDragPos = _nodeToPixel(_nodes[hitNode]);
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isCompleted || _activeNode == null) return;

    final localPos = details.localPosition;
    setState(() {
      _currentDragPos = localPos;
    });

    // Bir düğümün üzerine gelindi mi?
    final hitNode = _findNodeAt(localPos);
    if (hitNode != null && hitNode != _activeNode) {
      if (_isAdjacent(_activeNode!, hitNode) &&
          !_isEdgeDrawn(_activeNode!, hitNode)) {
        // Kenar çizme haptic
        HapticService.light();
        SoundService.instance.playNodeConnect();

        setState(() {
          _drawnEdges.add([_activeNode!, hitNode]);
          _visitedNodes.add(hitNode);
          _activeNode = hitNode;
          _moveCount++;
          _currentDragPos = _nodeToPixel(_nodes[hitNode]);

          // Tüm kenarlar çizildi mi?
          if (_drawnEdges.length == _edges.length) {
            _isCompleted = true;
            _isDragging = false;
            _currentDragPos = null;
            _stopwatch.stop();
            _elapsedMs = _stopwatch.elapsedMilliseconds;
            // Güçlü haptic
            HapticService.heavy();
            SoundService.instance.playLevelComplete();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _showCompletionDialog();
            });
          }
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _currentDragPos = null;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (_isCompleted) return;

    final localPos = details.localPosition;
    final hitNode = _findNodeAt(localPos);

    if (hitNode == null) return;

    // Hafif haptic
    HapticService.selection();

    setState(() {
      _lastHintEdge = null;
      if (_visitedNodes.isEmpty) {
        // İlk düğüm seçimi
        _visitedNodes.add(hitNode);
        _activeNode = hitNode;
      } else if (_activeNode != null &&
          hitNode != _activeNode &&
          _isAdjacent(_activeNode!, hitNode) &&
          !_isEdgeDrawn(_activeNode!, hitNode)) {
        // Tıklayarak da bağlantı yapılabilir
        HapticService.light();
        SoundService.instance.playNodeConnect();
        _drawnEdges.add([_activeNode!, hitNode]);
        _visitedNodes.add(hitNode);
        _activeNode = hitNode;
        _moveCount++;

        if (_drawnEdges.length == _edges.length) {
          _isCompleted = true;
          _stopwatch.stop();
          _elapsedMs = _stopwatch.elapsedMilliseconds;
          HapticService.heavy();
          SoundService.instance.playLevelComplete();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _showCompletionDialog();
          });
        }
      }
    });
  }

  bool _isAdjacent(int a, int b) {
    return _edges.any(
      (edge) =>
          (edge[0] == a && edge[1] == b) || (edge[0] == b && edge[1] == a),
    );
  }

  bool _isEdgeDrawn(int a, int b) {
    return _drawnEdges.any(
      (edge) =>
          (edge[0] == a && edge[1] == b) || (edge[0] == b && edge[1] == a),
    );
  }

  void _undoLastMove() {
    if (_drawnEdges.isNotEmpty) {
      HapticService.selection();
      setState(() {
        _lastHintEdge = null;
        _drawnEdges.removeLast();
        _visitedNodes.removeLast();
        _activeNode = _visitedNodes.isNotEmpty ? _visitedNodes.last : null;
        _moveCount = _moveCount > 0 ? _moveCount - 1 : 0;
      });
    }
  }

  void _resetLevel() {
    HapticService.medium();
    SoundService.instance.playTap();
    _ghostTimer?.cancel();
    setState(() {
      _visitedNodes.clear();
      _drawnEdges.clear();
      _activeNode = null;
      _moveCount = 0;
      _isCompleted = false;
      _isDragging = false;
      _currentDragPos = null;
      _lastHintEdge = null;
      _ghostEdges = null;
      _stopwatch.reset();
      _stopwatch.start();
    });
  }

  void _onHintPressed() {
    if (_isCompleted) return;

    final gameProvider = context.read<GameProvider>();
    if (gameProvider.hintCount <= 0) {
      HapticService.medium();
      SoundService.instance.playError();
      _showNoHintsDialog();
      return;
    }

    _handleSmartHint();
  }

  void _showNoHintsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 28),
            const SizedBox(width: 8),
            Text('İpucun Bitti', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(
          'Tüm ipuçlarını kullandın! Ücretsiz 3 ipucu kazanarak devam edebilirsin.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              AdService.instance.showRewarded(
                onRewarded: () {
                  context.read<GameProvider>().addHints(3);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('+3 İpucu hesabına eklendi! 🎉'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _handleSmartHint();
                },
              );
            },
            icon: const Icon(Icons.play_circle_rounded, size: 20),
            label: const Text('Reklam İzle → +3 İpucu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Akıllı ipucu analizi ve yönlendirmesi
  void _handleSmartHint() {
    final hintResult = EulerSolver.getNextHintStep(
      nodeCount: _nodes.length,
      edges: _edges,
      visitedNodes: _visitedNodes,
      drawnEdges: _drawnEdges,
      activeNode: _activeNode,
    );

    if (hintResult == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu seviye için şu an ipucu bulunamadı!'),
        ),
      );
      return;
    }

    // Durum: Kullanıcı birden fazla hamle yapmış ve ya başlangıç noktası yanlış ya da derin çıkmazda
    // Kullanıcının emeğini sessizce silip başa atmak yerine akıllı seçenekler sun
    if (hintResult.isMajorDeadlock && _drawnEdges.length >= 2) {
      _showDeadlockAssistantDialog(hintResult);
      return;
    }

    // Normal akış veya küçük düzeltme (1-2 hamle): Adımı uygula
    _executeHintStep(hintResult);
  }

  /// Derin çıkmaz sokak veya yanlış başlangıçta kullanıcıya yardımcı olan akıllı modal
  void _showDeadlockAssistantDialog(HintStepResult hintResult) {
    final drawnCount = _drawnEdges.length;
    final totalEdges = _edges.length;
    final isWrongStart = hintResult.isWrongStart;
    final fullSol = hintResult.fullSolution;

    // Kullanıcının ilerlemesine göre doğru rotada otomatik çizilecek adım sayısı
    final autoStepsCount = min(
      fullSol.length - 1,
      max(3, min(8, drawnCount)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akıllı İpucu Rehberi',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$drawnCount / $totalEdges çizgi çizildi',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: (isWrongStart ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: (isWrongStart ? AppColors.error : AppColors.primary)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isWrongStart ? Icons.info_outline_rounded : Icons.alt_route_rounded,
                        size: 20,
                        color: isWrongStart ? AppColors.error : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isWrongStart
                              ? 'Bu bulmaca matematiksel olarak yalnızca sarı halkalı başlangıç düğümlerinden başlanarak tek seferde bitirilebilir. Mevcut başlangıç noktanızla tüm çizgileri tamamlamak mümkün değil.'
                              : 'Çizdiğiniz yol önceki bir ayrımda çıkmaza girdi. Tüm çizgileri tamamlamak için rotanın düzeltilmesi gerekiyor.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Seçenek 1: Çözüm Yolunu Önizle (Tahtayı silmez!)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _activateGhostPreview(hintResult);
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 20),
                  label: const Text(
                    'Çözüm Yolunu Önizle (Çizimini Korur)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 10),

                // Seçenek 2: Doğru Rotaya Geç ve Otomatik İlerlet
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _jumpToCorrectPath(hintResult, autoStepsCount);
                  },
                  icon: const Icon(Icons.fast_forward_rounded, size: 20),
                  label: Text(
                    'Doğru Rotaya Geç (İlk $autoStepsCount Çizgiyi Tamamla)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Vazgeç (İpucu Harcama)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Çözüm yolunu tahtayı silmeden 10 saniye boyunca parlayan numaralı kılavuz olarak gösterir
  void _activateGhostPreview(HintStepResult hintResult) {
    context.read<GameProvider>().useHint();
    context.read<AchievementProvider>().checkHintUsed();

    HapticService.light();
    SoundService.instance.playHint();

    final fullSol = hintResult.fullSolution;
    final ghost = <List<int>>[];
    for (int i = 0; i < fullSol.length - 1; i++) {
      ghost.add([fullSol[i], fullSol[i + 1]]);
    }

    setState(() {
      _ghostEdges = ghost;
      _ghostTimer?.cancel();
      _ghostTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _ghostEdges = null);
      });
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.visibility_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tam çözüm yolu 10 sn boyunca numaralı adımlarla gösteriliyor!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Kapat',
          textColor: AppColors.accent,
          onPressed: () {
            _ghostTimer?.cancel();
            setState(() => _ghostEdges = null);
          },
        ),
      ),
    );
  }

  /// Doğru rotaya geçerek kullanıcının ilerleme seviyesine kadar olan adımları hazır çizer
  void _jumpToCorrectPath(HintStepResult hintResult, int stepsToDraw) {
    context.read<GameProvider>().useHint();
    context.read<AchievementProvider>().checkHintUsed();

    HapticService.medium();
    SoundService.instance.playHint();

    final fullSol = hintResult.fullSolution;
    final validSteps = min(stepsToDraw, fullSol.length - 1);

    setState(() {
      _ghostTimer?.cancel();
      _ghostEdges = null;

      _visitedNodes.clear();
      _drawnEdges.clear();

      _visitedNodes.add(fullSol[0]);
      for (int i = 0; i < validSteps; i++) {
        final u = fullSol[i];
        final v = fullSol[i + 1];
        _drawnEdges.add([u, v]);
        _visitedNodes.add(v);
      }
      _activeNode = _visitedNodes.last;
      _lastHintEdge = _drawnEdges.isNotEmpty ? _drawnEdges.last : null;
      _moveCount = _drawnEdges.length;

      // Sonraki adımları kılavuz olarak göster
      if (validSteps < fullSol.length - 1) {
        final upcoming = <List<int>>[];
        for (int i = validSteps; i < min(validSteps + 3, fullSol.length - 1); i++) {
          upcoming.add([fullSol[i], fullSol[i + 1]]);
        }
        _ghostEdges = upcoming;
        _ghostTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _ghostEdges = null);
        });
      }

      if (_drawnEdges.length == _edges.length) {
        _isCompleted = true;
        _isDragging = false;
        _currentDragPos = null;
        _stopwatch.stop();
        _elapsedMs = _stopwatch.elapsedMilliseconds;
        HapticService.heavy();
        SoundService.instance.playLevelComplete();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showCompletionDialog();
        });
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Doğru rotaya geçildi ve ilk $validSteps adım çizildi! 🚀',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Tek adımlık doğrudan ipucunu uygular
  void _executeHintStep(HintStepResult hintResult) {
    context.read<GameProvider>().useHint();
    context.read<AchievementProvider>().checkHintUsed();

    HapticService.light();
    SoundService.instance.playHint();

    setState(() {
      if (hintResult.didRollback) {
        _visitedNodes.clear();
        _visitedNodes.addAll(hintResult.rollbackVisitedNodes);
        _drawnEdges.clear();
        _drawnEdges.addAll(hintResult.rollbackDrawnEdges);
      } else if (_visitedNodes.isEmpty) {
        _visitedNodes.add(hintResult.fromNode);
      }

      final newEdge = [hintResult.fromNode, hintResult.toNode];
      _drawnEdges.add(newEdge);
      _visitedNodes.add(hintResult.toNode);
      _activeNode = hintResult.toNode;
      _lastHintEdge = newEdge;
      _moveCount++;

      // Sonraki kılavuz adımları göster (varsa)
      if (hintResult.upcomingSteps.length > 1) {
        _ghostEdges = hintResult.upcomingSteps.sublist(1);
        _ghostTimer?.cancel();
        _ghostTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _ghostEdges = null);
        });
      }

      // Tamamlandı mı?
      if (_drawnEdges.length == _edges.length) {
        _isCompleted = true;
        _isDragging = false;
        _currentDragPos = null;
        _stopwatch.stop();
        _elapsedMs = _stopwatch.elapsedMilliseconds;
        HapticService.heavy();
        SoundService.instance.playLevelComplete();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showCompletionDialog();
        });
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hintResult.message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCompletionDialog() {
    // Basit yıldız hesabı
    final parMoves = _edges.length; // Minimum hamle = kenar sayısı
    int stars;
    if (_moveCount <= parMoves) {
      stars = 3;
    } else if (_moveCount <= parMoves + 2) {
      stars = 2;
    } else {
      stars = 1;
    }

    // Mükemmel seri takibi
    if (stars == 3) {
      _consecutivePerfects++;
    } else {
      _consecutivePerfects = 0;
    }

    // İlerlemeyi kaydet
    context.read<GameProvider>().completeLevel(
      difficulty: widget.difficulty,
      levelId: widget.levelId,
      stars: stars,
      moves: _moveCount,
      timeMs: _elapsedMs,
    );

    // Başarım kontrolleri
    final achievementProvider = context.read<AchievementProvider>();
    achievementProvider.checkSpeedDemon(_elapsedMs);
    achievementProvider.checkPerfectStreak(_consecutivePerfects);

    // Reklam (her 3 level'da bir)
    AdService.instance.onLevelCompleted();

    // Süre formatı
    final seconds = (_elapsedMs ~/ 1000) % 60;
    final minutes = (_elapsedMs ~/ 1000) ~/ 60;
    final timeStr = '${minutes > 0 ? '$minutes dk ' : ''}$seconds sn';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Text(
          'Tebrikler! 🎉',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yıldızlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 44,
                    color: i < stars
                        ? AppColors.accent
                        : AppColors.nodeDefault,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Seviye ${widget.levelId} • ${_currentLevel.name}',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 18, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '$_moveCount hamle',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement('/game/${widget.levelId + 1}?d=${widget.difficulty}');
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );

    // Başarım bildirimlerini göster (diyalog kapandıktan kısa süre sonra)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _showAchievementNotifications();
    });
  }

  void _showAchievementNotifications() {
    final achievementProvider = context.read<AchievementProvider>();
    if (!achievementProvider.hasPendingNotifications) return;

    final pending = achievementProvider.consumePendingNotifications();
    for (final achievement in pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(achievement.icon, color: achievement.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 ${achievement.title}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      achievement.subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye ${widget.levelId}', style: AppTextStyles.titleMedium),
            Text(
              _currentLevel.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          // Süre sayacı
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text(
                        _formattedTime,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Hamle sayacı
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_moveCount',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Kenar bilgisi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_drawnEdges.length} / ${_edges.length} çizgi',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),

          // Çizim Alanı
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapUp: _onTapUp,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: _canvasSize,
                              painter: _GamePainter(
                                nodes: _nodes,
                                edges: _edges,
                                drawnEdges: _drawnEdges,
                                lastHintEdge: _lastHintEdge,
                                activeNode: _activeNode,
                                visitedNodes: _visitedNodes,
                                isDragging: _isDragging,
                                dragPosition: _currentDragPos,
                                canvasSize: _canvasSize,
                                isDark: Theme.of(context).brightness == Brightness.dark,
                                pulseValue: _pulseController.value,
                                ghostEdges: _ghostEdges,
                                validStartNodes: _validStartNodes,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Kılavuz / Önizleme aktifken üstte bilgilendirme çipi
                    if (_ghostEdges != null)
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _ghostEdges!.length > 2
                                      ? 'Çözüm Kılavuzu: Numaraları sırayla takip et'
                                      : 'İpucu: Sonraki adımlar parlıyor',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    _ghostTimer?.cancel();
                                    setState(() => _ghostEdges = null);
                                  },
                                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Alt Buton Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.undo_rounded,
                    label: 'Geri Al',
                    onTap: _undoLastMove,
                  ),
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Sıfırla',
                    onTap: _resetLevel,
                  ),
                  _ActionButton(
                    icon: Icons.lightbulb_rounded,
                    label: 'İpucu',
                    badge: '${context.watch<GameProvider>().hintCount}',
                    onTap: _onHintPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aksiyon butonu widget'ı (isteğe bağlı bildirim rozeti destekli)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badge!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

/// Oyun alanı çizici — tüm düğüm ve kenarları çizer
class _GamePainter extends CustomPainter {
  final List<Offset> nodes;
  final List<List<int>> edges;
  final List<List<int>> drawnEdges;
  final List<int>? lastHintEdge;
  final int? activeNode;
  final List<int> visitedNodes;
  final bool isDragging;
  final Offset? dragPosition;
  final Size canvasSize;
  final bool isDark;
  final double pulseValue;

  final List<List<int>>? ghostEdges;
  final List<int>? validStartNodes;

  _GamePainter({
    required this.nodes,
    required this.edges,
    required this.drawnEdges,
    this.lastHintEdge,
    this.activeNode,
    required this.visitedNodes,
    required this.isDragging,
    this.dragPosition,
    required this.canvasSize,
    required this.isDark,
    required this.pulseValue,
    this.ghostEdges,
    this.validStartNodes,
  });

  Offset _nodeToPixel(Offset node) {
    final side = min(canvasSize.width, canvasSize.height) * 0.85;
    final offsetX = (canvasSize.width - side) / 2;
    final offsetY = (canvasSize.height - side) / 2;
    return Offset(
      offsetX + node.dx * side,
      offsetY + node.dy * side,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Çizilmemiş kenarlar (soluk çizgiler)
    final undrawnPaint = Paint()
      ..color = isDark
          ? AppColors.nodeDefault.withValues(alpha: 0.2)
          : AppColors.nodeDefault.withValues(alpha: 0.15)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      if (!_isEdgeInDrawn(edge[0], edge[1])) {
        final from = _nodeToPixel(nodes[edge[0]]);
        final to = _nodeToPixel(nodes[edge[1]]);
        canvas.drawLine(from, to, undrawnPaint);
      }
    }

    // 2) Çizilmiş kenarlar (renkli, kalın)
    final drawnPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (final edge in drawnEdges) {
      final isHint = lastHintEdge != null &&
          ((edge[0] == lastHintEdge![0] && edge[1] == lastHintEdge![1]) ||
              (edge[0] == lastHintEdge![1] && edge[1] == lastHintEdge![0]));

      final edgePaint = isHint
          ? (Paint()
            ..color = AppColors.accent
            ..strokeWidth = 6.5
            ..strokeCap = StrokeCap.round)
          : drawnPaint;

      final from = _nodeToPixel(nodes[edge[0]]);
      final to = _nodeToPixel(nodes[edge[1]]);
      canvas.drawLine(from, to, edgePaint);
    }

    // 2.5) Hayalet / Önizleme Kılavuz Çizgileri (Çözüm rotasını gösterir)
    if (ghostEdges != null && ghostEdges!.isNotEmpty) {
      for (int i = 0; i < ghostEdges!.length; i++) {
        final gEdge = ghostEdges![i];
        final from = _nodeToPixel(nodes[gEdge[0]]);
        final to = _nodeToPixel(nodes[gEdge[1]]);

        // Kılavuz neon çizgi
        final ghostLinePaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.8)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(from, to, ghostLinePaint);

        // Adım numarası rozeti (çizginin ortasında)
        final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
        final badgeBg = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final badgeBorder = Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(mid, 10.0, badgeBg);
        canvas.drawCircle(mid, 10.0, badgeBorder);

        final textSpan = TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // 3) Sürükleme çizgisi (aktif düğümden parmağa)
    if (isDragging && activeNode != null && dragPosition != null) {
      final dragLinePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.6)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      final from = _nodeToPixel(nodes[activeNode!]);
      canvas.drawLine(from, dragPosition!, dragLinePaint);
    }

    // 4) Düğüm noktaları
    for (int i = 0; i < nodes.length; i++) {
      final pos = _nodeToPixel(nodes[i]);
      final isActive = i == activeNode;
      final isVisited = visitedNodes.contains(i);

      // Başlangıç düğümü kılavuz halkası (Henüz başlanmamış ve sadece 2 geçerli başlangıç düğümü varsa)
      if (visitedNodes.isEmpty &&
          validStartNodes != null &&
          validStartNodes!.contains(i) &&
          validStartNodes!.length == 2) {
        final startPulseRadius = 18.0 + pulseValue * 10.0;
        final startPulsePaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.45 * (1.0 - pulseValue))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(pos, startPulseRadius, startPulsePaint);
      }

      // Aktif düğüm pulse efekti
      if (isActive && !isDragging) {
        final pulseRadius = 22.0 + pulseValue * 8.0;
        final pulsePaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.15 + pulseValue * 0.1)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, pulseRadius, pulsePaint);
      }

      // Dış daire
      final outerRadius = isActive ? 18.0 : 14.0;
      final outerPaint = Paint()
        ..color = isActive
            ? AppColors.primary
            : isVisited
                ? AppColors.secondary
                : (isDark ? AppColors.nodeDefault : const Color(0xFFBBB8CC))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, outerRadius, outerPaint);

      // İç daire
      final innerRadius = isActive ? 9.0 : 7.0;
      final innerPaint = Paint()
        ..color = isActive
            ? Colors.white
            : isVisited
                ? Colors.white
                : (isDark ? AppColors.surfaceDark : Colors.white)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, innerRadius, innerPaint);
    }
  }

  bool _isEdgeInDrawn(int a, int b) {
    return drawnEdges.any(
      (e) => (e[0] == a && e[1] == b) || (e[0] == b && e[1] == a),
    );
  }

  @override
  bool shouldRepaint(_GamePainter old) => true;
}
