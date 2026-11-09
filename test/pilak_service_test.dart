import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dictionary/features/pilak/pilak_product.dart';
import 'package:dictionary/features/pilak/pilak_service.dart';

void main() {
  test('currency formulas follow the requested integer math', () {
    expect(calculateQuizPilak(100, 0), 100);
    expect(calculateQuizPilak(100, 1), 67);
    expect(calculateQuizPilak(100, 3), 1);
    expect(calculateQuizPilak(100, 4), 0);
    expect(calculateAdarnaQuizPilak(100, 1, adarnaModeEnabled: true), 134);
    expect(calculateAdarnaQuizPilak(100, 1, adarnaModeEnabled: false), 67);
    expect(calculateReadingPilak(0), 0);
    expect(calculateReadingPilak(1), 15);
    expect(calculateDailyStreakPilak(0), 10);
    expect(calculateDailyStreakPilak(1), 15);
    expect(calculateDailyStreakPilak(14), 80);
    expect(calculateDailyStreakPilak(30), 80);
    expect(() => calculateQuizPilak(-1, 0), throwsArgumentError);
    expect(() => calculateReadingPilak(-1), throwsArgumentError);
    expect(
      shouldEarnAdarnaHeart(score: 3, maxScore: 4, firstTry: true),
      isTrue,
    );
    expect(
      shouldEarnAdarnaHeart(score: 2, maxScore: 4, firstTry: true),
      isFalse,
    );
    expect(
      shouldEarnAdarnaHeart(score: 4, maxScore: 4, firstTry: false),
      isFalse,
    );
  });

  test('marketplace contains all 30 named products with unique IDs', () {
    expect(pilakProducts, hasLength(30));
    expect(pilakProducts.map((product) => product.id).toSet(), hasLength(30));
    expect(
      pilakProducts.where(
        (product) => product.category == PilakProductCategory.theme,
      ),
      hasLength(10),
    );
    expect(
      pilakProducts.where(
        (product) => product.category == PilakProductCategory.feature,
      ),
      hasLength(10),
    );
    expect(
      pilakProducts.where(
        (product) => product.category == PilakProductCategory.material,
      ),
      hasLength(10),
    );
    expect(pilakProductById('teacher_answer_keys')?.price, 10000);
  });

  test(
    'purchases serialize balance, item IDs, and apply themes immediately',
    () async {
      SharedPreferences.setMockInitialValues({
        'pilak_economy_state': jsonEncode({
          'balance': 6000,
          'purchasedItemIds': <String>[],
          'streakDays': 0,
          'quizDecayResetCredits': 0,
        }),
      });

      final service = PilakService.instance;
      await service.initialize();
      expect(service.adarnaHearts, 3);
      await service.setAdarnaModeEnabled(true);
      expect(await service.consumeAdarnaSearchHeart(), isTrue);
      expect(await service.consumeAdarnaSearchHeart(), isTrue);
      expect(await service.consumeAdarnaSearchHeart(), isTrue);
      expect(await service.consumeAdarnaSearchHeart(), isFalse);
      expect(service.adarnaHearts, 0);
      expect(service.adarnaModeEnabled, isTrue);
      expect(await service.purchase('theme_armenya_forest'), isTrue);
      expect(service.balance, 5700);
      expect(service.activeThemeId, 'armenya_forest');
      expect(service.owns('theme_armenya_forest'), isTrue);
      expect(await service.purchase('theme_armenya_forest'), isFalse);

      final firstLogin = DateTime(2026, 1, 1, 10);
      expect(await service.recordDailyLogin(at: firstLogin), 15);
      expect(await service.recordDailyLogin(at: firstLogin), 0);
      expect(
        await service.recordDailyLogin(
          at: firstLogin.add(const Duration(days: 1)),
        ),
        20,
      );
      expect(service.streakDays, 2);
      expect(await service.purchase('streak_freeze'), isTrue);
      expect(await service.purchase('quiz_decay_reset'), isTrue);
      expect(service.quizDecayResetCredits, 1);
      expect(await service.rewardActiveReading(1), 15);
      expect(await service.rewardActiveReading(1), 8);

      final preferences = await SharedPreferences.getInstance();
      final state = jsonDecode(
        preferences.getString('pilak_economy_state')!,
      ) as Map<String, dynamic>;
      expect(state['balance'], 5108);
      expect(state['purchasedItemIds'], [
        'quiz_decay_reset',
        'streak_freeze',
        'theme_armenya_forest',
      ]);
      expect(state['activeThemeId'], 'armenya_forest');
      expect(state['streakDays'], 2);
      expect(state['quizDecayResetCredits'], 1);
      expect(state['readingMinutesToday'], 2);
      expect(state['adarnaModeEnabled'], isTrue);
      expect(state['adarnaHearts'], 0);
      expect(state['pilakTransactions'], isNotEmpty);
      expect(state['readingHistory'], isA<Map<String, dynamic>>());
      expect(state['loginHistory'], ['2026-01-01', '2026-01-02']);
      expect(state['longestStreak'], 2);

      await service.restoreAdarnaHeartsForTesting();
      await service.setBalanceForTesting(12345);
      expect(service.adarnaHearts, 3);
      expect(service.balance, 12345);
      final developerState = jsonDecode(
        preferences.getString('pilak_economy_state')!,
      ) as Map<String, dynamic>;
      expect(developerState['adarnaHearts'], 3);
      expect(developerState['balance'], 12345);
    },
  );
}
