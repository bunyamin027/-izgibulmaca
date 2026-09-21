import 'package:flutter_test/flutter_test.dart';
import 'package:cizgi_bulmaca/core/services/euler_solver.dart';
import 'package:cizgi_bulmaca/core/services/level_repository.dart';

void main() {
  group('EulerSolver Tests', () {
    test('findSolution finds valid Eulerian trails for handcrafted levels', () {
      for (int levelId = 1; levelId <= 12; levelId++) {
        final level = LevelRepository.getLevel(0, levelId);
        final solution = EulerSolver.findSolution(level.nodes.length, level.edges);

        expect(solution, isNotNull, reason: 'Level $levelId must have a valid solution');
        expect(solution!.length, level.edges.length + 1);

        // Verify that consecutive nodes in the solution correspond to valid edges
        final usedEdges = <String>{};
        for (int i = 0; i < solution.length - 1; i++) {
          final u = solution[i];
          final v = solution[i + 1];
          final edgeKey = u < v ? '$u-$v' : '$v-$u';

          final edgeExists = level.edges.any((e) =>
              (e[0] == u && e[1] == v) || (e[0] == v && e[1] == u));
          expect(edgeExists, true, reason: 'Edge $edgeKey must exist in Level $levelId');
          expect(usedEdges.contains(edgeKey), false, reason: 'Edge $edgeKey must not be reused');
          usedEdges.add(edgeKey);
        }
        expect(usedEdges.length, level.edges.length);
      }
    });

    test('getNextHintStep on empty board provides initial step', () {
      final level = LevelRepository.getLevel(0, 1); // Triangle: 0-1, 1-2, 2-0
      final hint = EulerSolver.getNextHintStep(
        nodeCount: level.nodes.length,
        edges: level.edges,
        visitedNodes: [],
        drawnEdges: [],
        activeNode: null,
      );

      expect(hint, isNotNull);
      expect(hint!.didRollback, false);
      expect(hint.rollbackVisitedNodes, [hint.fromNode]);
      expect(hint.rollbackDrawnEdges, isEmpty);
      expect(
        level.edges.any((e) =>
            (e[0] == hint.fromNode && e[1] == hint.toNode) ||
            (e[0] == hint.toNode && e[1] == hint.fromNode)),
        true,
      );
    });

    test('getNextHintStep with valid continuation provides the next correct edge', () {
      final level = LevelRepository.getLevel(0, 1); // Triangle
      // Start at 0, move to 1
      final visitedNodes = [0, 1];
      final drawnEdges = [[0, 1]];

      final hint = EulerSolver.getNextHintStep(
        nodeCount: level.nodes.length,
        edges: level.edges,
        visitedNodes: visitedNodes,
        drawnEdges: drawnEdges,
        activeNode: 1,
      );

      expect(hint, isNotNull);
      expect(hint!.fromNode, 1);
      expect(hint.toNode, 2);
      expect(hint.didRollback, false);
    });

    test('getNextHintStep with dead-end rolls back invalid moves and finds correct path', () {
      // Ev (House: 5 nodes, 8 edges)
      // Level 5 has 2 odd-degree vertices (3 and 4). Starting at 0 makes a complete solution impossible.
      final level = LevelRepository.getLevel(0, 5); // Ev
      // Deliberately simulate an invalid start from node 0 to node 1:
      final visitedNodes = [0, 1];
      final drawnEdges = [[0, 1]];

      final hint = EulerSolver.getNextHintStep(
        nodeCount: level.nodes.length,
        edges: level.edges,
        visitedNodes: visitedNodes,
        drawnEdges: drawnEdges,
        activeNode: 1,
      );

      expect(hint, isNotNull);
      expect(hint!.didRollback, true);
      expect(
        level.edges.any((e) =>
            (e[0] == hint.fromNode && e[1] == hint.toNode) ||
            (e[0] == hint.toNode && e[1] == hint.fromNode)),
        true,
      );
    });
  });
}
