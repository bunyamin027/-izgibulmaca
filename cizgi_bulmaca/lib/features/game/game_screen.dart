import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/game_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameProvider>().setLastPlayed(widget.difficulty, widget.levelId);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GameProvider>().setLastPlayed(widget.difficulty, widget.levelId);
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initLevel() {
    _currentLevel = LevelRepository.getLevel(widget.difficulty, widget.levelId);
    _nodes = _currentLevel.nodes;
    _edges = _currentLevel.edges;
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

  // ─── Dokunma Olayları ────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;

    final localPos = details.localPosition;
    final hitNode = _findNodeAt(localPos);

    if (hitNode != null) {
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
        _drawnEdges.add([_activeNode!, hitNode]);
        _visitedNodes.add(hitNode);
        _activeNode = hitNode;
        _moveCount++;

        if (_drawnEdges.length == _edges.length) {
          _isCompleted = true;
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
    setState(() {
      _visitedNodes.clear();
      _drawnEdges.clear();
      _activeNode = null;
      _moveCount = 0;
      _isCompleted = false;
      _isDragging = false;
      _currentDragPos = null;
      _lastHintEdge = null;
    });
  }

  void _onHintPressed() {
    if (_isCompleted) return;

    final gameProvider = context.read<GameProvider>();
    if (gameProvider.hintCount <= 0) {
      _showNoHintsDialog();
      return;
    }

    _applyHint();
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
              context.read<GameProvider>().addHints(3);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('+3 İpucu hesabına eklendi! 🎉'),
                  duration: Duration(seconds: 2),
                ),
              );
              _applyHint();
            },
            icon: const Icon(Icons.stars_rounded, size: 20),
            label: const Text('+3 İpucu Al', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _applyHint() {
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

    // İpucu hakkını düşür
    context.read<GameProvider>().useHint();

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

      // Tamamlandı mı?
      if (_drawnEdges.length == _edges.length) {
        _isCompleted = true;
        _isDragging = false;
        _currentDragPos = null;
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

    // İlerlemeyi kaydet
    context.read<GameProvider>().completeLevel(
      difficulty: widget.difficulty,
      levelId: widget.levelId,
      stars: stars,
      moves: _moveCount,
      timeMs: 0, // TODO: süre ölçümü
    );

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
            Text(
              '$_moveCount hamle',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.secondary,
              ),
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
                return GestureDetector(
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
                        ),
                      );
                    },
                  ),
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
