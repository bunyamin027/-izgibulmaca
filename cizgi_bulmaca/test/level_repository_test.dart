import 'package:flutter_test/flutter_test.dart';
import 'package:cizgi_bulmaca/core/services/level_repository.dart';

void main() {
  group('LevelRepository Euler Theorem Tests', () {
    bool isEulerian(List nodes, List<List<int>> edges) {
      final degrees = List<int>.filled(nodes.length, 0);
      final adj = <int, Set<int>>{for (int i = 0; i < nodes.length; i++) i: {}};

      for (final edge in edges) {
        final u = edge[0];
        final v = edge[1];
        degrees[u]++;
        degrees[v]++;
        adj[u]!.add(v);
        adj[v]!.add(u);
      }

      final oddCount = degrees.where((d) => d % 2 != 0).length;

      // Connectivity
      final start = degrees.indexWhere((d) => d > 0);
      if (start == -1) return false;

      final visited = <int>{};
      final stack = [start];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        if (!visited.contains(cur)) {
          visited.add(cur);
          for (final neighbor in adj[cur]!) {
            if (!visited.contains(neighbor)) {
              stack.add(neighbor);
            }
          }
        }
      }

      final connected = degrees.asMap().entries.every((e) => e.value == 0 || visited.contains(e.key));
      return (oddCount == 0 || oddCount == 2) && connected;
    }

    test('Handcrafted levels (1-12) for Easy difficulty are 100% Eulerian and solvable', () {
      for (int levelId = 1; levelId <= 12; levelId++) {
        final level = LevelRepository.getLevel(0, levelId);
        expect(level.nodes.isNotEmpty, true);
        expect(level.edges.isNotEmpty, true);
        expect(isEulerian(level.nodes, level.edges), true,
            reason: 'Level $levelId (${level.name}) must be Eulerian');
      }
    });

    test('Procedural levels (13-50) for all difficulties are 100% Eulerian', () {
      for (int diff = 0; diff < 3; diff++) {
        for (int levelId = 13; levelId <= 50; levelId++) {
          final level = LevelRepository.getLevel(diff, levelId);
          expect(isEulerian(level.nodes, level.edges), true,
              reason: 'Diff $diff Level $levelId must be Eulerian');
        }
      }
    });

    test('Milestone levels (100, 200) are 100% Eulerian', () {
      for (int diff = 0; diff < 3; diff++) {
        for (final levelId in [100, 200]) {
          final level = LevelRepository.getLevel(diff, levelId);
          expect(isEulerian(level.nodes, level.edges), true,
              reason: 'Diff $diff Level $levelId must be Eulerian');
        }
      }
    });
  });
}
