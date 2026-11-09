import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dictionary/features/growth/analytics_service.dart';

void main() {
  test('weekly inference compares quiz volume and average scores', () {
    expect(
      AnalyticsService.compareLastSevenDays(
        currentCount: 6,
        previousCount: 4,
        currentAverage: 0.8,
        previousAverage: 0.7,
        streak: 3,
      ),
      contains('🔥'),
    );
    expect(
      AnalyticsService.compareLastSevenDays(
        currentCount: 2,
        previousCount: 2,
        currentAverage: 0.8,
        previousAverage: 0.7,
        streak: 3,
        currentReadingMinutes: 24,
        previousReadingMinutes: 20,
      ),
      '🔥 You read 20% more this week and increased your average quiz score!',
    );
    expect(
      AnalyticsService.compareLastSevenDays(
        currentCount: 0,
        previousCount: 0,
        currentAverage: 0,
        previousAverage: 0,
        streak: 0,
      ),
      contains('Complete a quiz'),
    );
  });

  test('vocabulary interactions are unique per local day', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AnalyticsService.instance;
    await service.recordVocabularyInteraction('  Ibong   Adarna ');
    await service.recordVocabularyInteraction('ibong adarna');

    final preferences = await SharedPreferences.getInstance();
    final history = jsonDecode(
      preferences.getString('dictionary_search_history')!,
    ) as Map<String, dynamic>;
    final today = DateTime.now();
    final key =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    expect(history[key], ['ibong adarna']);
  });
}
