import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'analytics_service.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  late Future<GrowthAnalytics> _analytics;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _analytics = AnalyticsService.instance.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth & Progress'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh progress',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<GrowthAnalytics>(
        future: _analytics,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load analytics: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final analytics = snapshot.data!;
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _InferenceCard(text: analytics.generalInference),
                const TabBar(
                  tabs: [
                    Tab(text: 'Quizzes'),
                    Tab(text: 'Reading & Activity'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _QuizAnalytics(analytics: analytics),
                      _ReadingAnalytics(analytics: analytics),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InferenceCard extends StatelessWidget {
  const _InferenceCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuizAnalytics extends StatelessWidget {
  const _QuizAnalytics({required this.analytics});

  final GrowthAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final labels = _lastSevenLabels();
    final maxScore = _safeMax(analytics.quizScoresLastSevenDays);
    final maxPilak = mathMaxInt(analytics.quizPilakByWeek);
    final maxDecay = _safeMax(analytics.decayPilakByAttempt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SummaryRow(
          items: [
            _SummaryData(
              'Average score',
              '${(analytics.averageQuizScore * 100).round()}%',
              Icons.track_changes,
            ),
            _SummaryData(
              'Quizzes',
              '${analytics.quizCount}',
              Icons.quiz_outlined,
            ),
          ],
        ),
        _AnalyticsCard(
          title: 'Recent performance',
          inference: analytics.quizInference,
          chart: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxScore,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: labels,
                leftSuffix: '%',
                maxY: maxScore,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < 7; index++)
                      FlSpot(
                        index.toDouble(),
                        analytics.quizScoresLastSevenDays[index],
                      ),
                  ],
                  isCurved: true,
                  color: primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        _AnalyticsCard(
          title: 'Kabanata mastery',
          inference: 'Lower averages highlight chapters that may need review.',
          chart: BarChart(
            BarChartData(
              maxY: 100,
              minY: 0,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: analytics.chapterRangeLabels,
                leftSuffix: '%',
                maxY: 100,
              ),
              barGroups: [
                for (var index = 0; index < 5; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: analytics.chapterRangeAverages[index],
                        color: analytics.chapterRangeAverages[index] < 60
                            ? theme.colorScheme.error
                            : primary,
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        _AnalyticsCard(
          title: 'Accuracy ratio',
          inference:
              'Based on answers saved in completed quiz activity records.',
          chart: _AccuracyPie(analytics: analytics),
          legend: const ['Correct', 'Incorrect'],
          colors: [primary, theme.colorScheme.error],
        ),
        _AnalyticsCard(
          title: 'Pilak earned from quizzes',
          inference: 'Compares recorded quiz rewards for the last two weeks.',
          chart: BarChart(
            BarChartData(
              maxY: maxPilak.toDouble(),
              minY: 0,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: const ['Last week', 'This week'],
                leftSuffix: '',
                maxY: maxPilak.toDouble(),
              ),
              barGroups: [
                for (var index = 0; index < 2; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: analytics.quizPilakByWeek[index].toDouble(),
                        color: index == 0 ? secondary : primary,
                        width: 36,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          legend: const ['Quiz Pilak'],
          colors: [primary],
        ),
        _AnalyticsCard(
          title: 'Repeat-attempt Pilak decay',
          inference: 'The quiz formula lowers rewards with each attempt; the fourth attempt yields zero.',
          chart: LineChart(
            LineChartData(
              minX: 0,
              maxX: 3,
              minY: 0,
              maxY: maxDecay,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: const ['1st', '2nd', '3rd', '4th+'],
                leftSuffix: '',
                maxY: maxDecay,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < 4; index++)
                      FlSpot(
                        index.toDouble(),
                        analytics.decayPilakByAttempt[index],
                      ),
                  ],
                  isCurved: false,
                  color: secondary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
          legend: const ['Average Pilak'],
          colors: [secondary],
        ),
      ],
    );
  }
}

class _ReadingAnalytics extends StatelessWidget {
  const _ReadingAnalytics({required this.analytics});

  final GrowthAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final labels = _lastSevenLabels();
    final maxMinutes = _safeMax(analytics.readingMinutesLastSevenDays);
    final maxSearches = analytics.searchVolumeLastSevenDays.fold<int>(
      1,
      (a, b) => a > b ? a : b,
    );
    final maxStreak = mathMaxInt([
      analytics.longestStreak,
      analytics.currentStreak,
    ]).toDouble();
    final maxBalance = _safeMax(analytics.pilakBalanceLastThirtyDays);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SummaryRow(
          items: [
            _SummaryData(
              'Reading minutes',
              '${analytics.totalReadingMinutes}',
              Icons.menu_book_outlined,
            ),
            _SummaryData(
              'Pilak balance',
              '${analytics.currentBalance}',
              Icons.monetization_on_outlined,
            ),
          ],
        ),
        _AnalyticsCard(
          title: 'Active reading time',
          inference: analytics.hasReadingTimer ? analytics.readingInference : 'No active-reading timer is currently connected; the chart will fill when reading minutes are recorded.',
          chart: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxMinutes,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: labels,
                leftSuffix: 'm',
                maxY: maxMinutes,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < 7; index++)
                      FlSpot(
                        index.toDouble(),
                        analytics.readingMinutesLastSevenDays[index],
                      ),
                  ],
                  isCurved: true,
                  color: primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
          legend: const ['Minutes'],
          colors: [primary],
        ),
        _AnalyticsCard(
          title: 'Vocabulary search volume',
          inference: analytics.readingInference,
          chart: BarChart(
            BarChartData(
              maxY: maxSearches.toDouble(),
              minY: 0,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: labels,
                leftSuffix: '',
                maxY: maxSearches.toDouble(),
              ),
              barGroups: [
                for (var index = 0; index < 7; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: analytics.searchVolumeLastSevenDays[index]
                            .toDouble(),
                        color: primary,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          legend: const ['Unique searched terms'],
          colors: [primary],
        ),
        _AnalyticsCard(
          title: 'Time distribution',
          inference: 'Event-based estimate (dictionary searches, completed quizzes, purchases); elapsed time is not tracked for all sections.',
          chart: _DistributionPie(analytics: analytics),
          legend: const ['Dictionary', 'Quizzes', 'Marketplace'],
          colors: [primary, secondary, theme.colorScheme.tertiary],
        ),
        _AnalyticsCard(
          title: 'Login streak history',
          inference: 'Compare your current consecutive login streak with your all-time best.',
          chart: BarChart(
            BarChartData(
              maxY: maxStreak * 1.15,
              minY: 0,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: const ['Current', 'Longest'],
                leftSuffix: '',
                maxY: maxStreak * 1.15,
              ),
              barGroups: [
                for (var index = 0; index < 2; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: index == 0
                            ? analytics.currentStreak.toDouble()
                            : analytics.longestStreak.toDouble(),
                        color: index == 0 ? primary : secondary,
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          legend: const ['Current streak', 'Longest streak'],
          colors: [primary, secondary],
        ),
        _SummaryRow(
          items: [
            _SummaryData(
              'Current streak',
              '${analytics.currentStreak} days',
              Icons.local_fire_department,
            ),
            _SummaryData(
              'Longest streak',
              '${analytics.longestStreak} days',
              Icons.emoji_events_outlined,
            ),
          ],
        ),
        _AnalyticsCard(
          title: 'Total Pilak accumulation',
          inference: 'Balance history is recorded from new Pilak transactions onward; older transactions cannot be reconstructed.',
          chart: LineChart(
            LineChartData(
              minX: 0,
              maxX: 29,
              minY: 0,
              maxY: maxBalance,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _axisTitles(
                labels: _lastThirtyLabels(),
                leftSuffix: '',
                maxY: maxBalance,
                interval: 7,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (
                      var index = 0;
                      index < analytics.pilakBalanceLastThirtyDays.length;
                      index++
                    )
                      FlSpot(
                        index.toDouble(),
                        analytics.pilakBalanceLastThirtyDays[index],
                      ),
                  ],
                  isCurved: true,
                  color: secondary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: secondary.withValues(alpha: 0.16),
                  ),
                ),
              ],
            ),
          ),
          legend: const ['Pilak balance'],
          colors: [secondary],
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.inference,
    required this.chart,
    this.legend,
    this.colors,
  });

  final String title;
  final String inference;
  final Widget chart;
  final List<String>? legend;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            inference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          AspectRatio(aspectRatio: 1.65, child: chart),
          if (legend != null && colors != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (var index = 0; index < legend!.length; index++)
                  _LegendItem(label: legend![index], color: colors![index]),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _SummaryData {
  const _SummaryData(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.items});

  final List<_SummaryData> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      items[index].icon,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items[index].title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[index].value,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _AccuracyPie extends StatelessWidget {
  const _AccuracyPie({required this.analytics});

  final GrowthAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final correct = analytics.correctAnswers.toDouble();
    final incorrect = analytics.incorrectAnswers.toDouble();
    final total = correct + incorrect;
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 42,
            sections: total == 0
                ? [
                    PieChartSectionData(
                      value: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      title: '',
                      radius: 32,
                    ),
                  ]
                : [
                    PieChartSectionData(
                      value: correct,
                      color: Theme.of(context).colorScheme.primary,
                      title: '${(correct / total * 100).round()}%',
                      radius: 32,
                    ),
                    PieChartSectionData(
                      value: incorrect,
                      color: Theme.of(context).colorScheme.error,
                      title: '${(incorrect / total * 100).round()}%',
                      radius: 32,
                    ),
                  ],
          ),
        ),
        if (total == 0)
          const Text('No quiz data', textAlign: TextAlign.center)
        else
          Text(
            '$correctAnswersLabel\nanswers',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  String get correctAnswersLabel =>
      '${analytics.correctAnswers + analytics.incorrectAnswers}';
}

class _DistributionPie extends StatelessWidget {
  const _DistributionPie({required this.analytics});

  final GrowthAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final values = analytics.activityDistribution;
    final total = values.fold<int>(0, (a, b) => a + b);
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 42,
            sections: total == 0
                ? [
                    PieChartSectionData(
                      value: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      title: '',
                      radius: 32,
                    ),
                  ]
                : [
                    for (var index = 0; index < values.length; index++)
                      if (values[index] > 0)
                        PieChartSectionData(
                          value: values[index].toDouble(),
                          color: colors[index],
                          title: '${(values[index] / total * 100).round()}%',
                          radius: 32,
                        ),
                  ],
          ),
        ),
        if (total == 0) const Text('No activity yet'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 10),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

FlTitlesData _axisTitles({
  required List<String> labels,
  required String leftSuffix,
  required double maxY,
  double? interval,
}) {
  final safeInterval = interval ?? (maxY <= 10 ? 2 : maxY / 4);
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 38,
        interval: safeInterval,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(
            '${value.round()}$leftSuffix',
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: labels.length > 10 ? 7 : 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= labels.length) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(
              labels[index],
              style: const TextStyle(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    ),
  );
}

List<String> _lastSevenLabels() {
  final today = DateTime.now();
  return List.generate(7, (index) {
    final day = today.subtract(Duration(days: 6 - index));
    return '${day.month}/${day.day}';
  });
}

List<String> _lastThirtyLabels() {
  final today = DateTime.now();
  return List.generate(30, (index) {
    if (index % 7 != 0 && index != 29) return '';
    final day = today.subtract(Duration(days: 29 - index));
    return '${day.month}/${day.day}';
  });
}

double _safeMax(List<double> values) {
  final maximum = values.fold<double>(1, (a, b) => a > b ? a : b);
  return maximum == 0 ? 1 : maximum * 1.15;
}

int mathMaxInt(List<int> values) =>
    values.fold<int>(1, (a, b) => a > b ? a : b);
