import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cizgi_bulmaca/core/services/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameProvider Progression and Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state unlocks Level 1 and has 0 stars', () {
      final provider = GameProvider();
      expect(provider.isLevelUnlocked(0, 1), true);
      expect(provider.isLevelUnlocked(0, 2), false);
      expect(provider.lastUnlockedLevel(0), 1);
      expect(provider.totalStars, 0);
    });

    test('Progressing through levels 1 to 4 correctly unlocks level 5 and tracks lastPlayedLevel', () async {
      final provider = GameProvider();

      // Complete Level 1
      await provider.completeLevel(
        difficulty: 0,
        levelId: 1,
        stars: 3,
        moves: 3,
        timeMs: 1200,
      );
      expect(provider.isLevelUnlocked(0, 2), true);
      expect(provider.lastUnlockedLevel(0), 2);
      expect(provider.lastPlayedLevel, 2);
      expect(provider.totalStars, 3);

      // Complete Level 2
      await provider.completeLevel(
        difficulty: 0,
        levelId: 2,
        stars: 3,
        moves: 5,
        timeMs: 2000,
      );
      expect(provider.isLevelUnlocked(0, 3), true);
      expect(provider.lastUnlockedLevel(0), 3);
      expect(provider.lastPlayedLevel, 3);
      expect(provider.totalStars, 6);

      // Complete Level 3
      await provider.completeLevel(
        difficulty: 0,
        levelId: 3,
        stars: 2,
        moves: 8,
        timeMs: 3500,
      );
      expect(provider.isLevelUnlocked(0, 4), true);
      expect(provider.lastUnlockedLevel(0), 4);
      expect(provider.lastPlayedLevel, 4);
      expect(provider.totalStars, 8);

      // Complete Level 4
      await provider.completeLevel(
        difficulty: 0,
        levelId: 4,
        stars: 3,
        moves: 7,
        timeMs: 4000,
      );
      expect(provider.isLevelUnlocked(0, 5), true);
      expect(provider.lastUnlockedLevel(0), 5);
      expect(provider.lastPlayedLevel, 5);
      expect(provider.totalStars, 11);

      // Verify that a new GameProvider instance restores this exact progress from storage
      final reloadedProvider = GameProvider();
      await reloadedProvider.isReady;

      expect(reloadedProvider.isLevelUnlocked(0, 5), true);
      expect(reloadedProvider.lastUnlockedLevel(0), 5);
      expect(reloadedProvider.lastPlayedLevel, 5);
      expect(reloadedProvider.totalStars, 11);
      expect(reloadedProvider.completedLevelsCount(0), 4);
    });

    test('Manual setLastPlayed updates and persists last played level', () async {
      final provider = GameProvider();
      await provider.setLastPlayed(1, 7);

      expect(provider.lastPlayedDifficulty, 1);
      expect(provider.lastPlayedLevel, 7);

      final reloadedProvider = GameProvider();
      await reloadedProvider.isReady;

      expect(reloadedProvider.lastPlayedDifficulty, 1);
      expect(reloadedProvider.lastPlayedLevel, 7);
    });

    test('Hint count starts at default, decrements on use, increases on addHints and persists', () async {
      final provider = GameProvider();
      await provider.isReady;

      expect(provider.hintCount, 5);

      final used1 = await provider.useHint();
      expect(used1, true);
      expect(provider.hintCount, 4);

      await provider.addHints(3);
      expect(provider.hintCount, 7);

      final reloadedProvider = GameProvider();
      await reloadedProvider.isReady;

      expect(reloadedProvider.hintCount, 7);
    });
  });
}
