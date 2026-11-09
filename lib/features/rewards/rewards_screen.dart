import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../pilak/pilak_marketplace_screen.dart';
import '../pilak/pilak_service.dart';
import '../../services/app_feedback.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<Map<String, Object?>>> _rewards;
  late Future<Map<String, Object?>> _stats;
  late Future<void> _pilakInitialization;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pilakInitialization = PilakService.instance.initialize();
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    _rewards = DatabaseHelper.instance.getRewards();
    _stats = DatabaseHelper.instance.getGrowthStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh rewards',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Mga Gantimpala'),
            Tab(text: 'Pamilihan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRewardsTab(), const PilakMarketplaceScreen()],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return FutureBuilder<void>(
      future: _pilakInitialization,
      builder: (context, pilakSnapshot) {
        if (pilakSnapshot.hasError) {
          return Center(
            child: Text('Could not load Pilak balance: ${pilakSnapshot.error}'),
          );
        }
        if (pilakSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<Map<String, Object?>>(
          future: _stats,
          builder: (context, statsSnapshot) {
            if (statsSnapshot.hasError) {
              return Center(
                child: Text('Could not load rewards: ${statsSnapshot.error}'),
              );
            }
            if (!statsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final streak = PilakService.instance.streakDays;
            return FutureBuilder<List<Map<String, Object?>>>(
              future: _rewards,
              builder: (context, rewardSnapshot) {
                if (rewardSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load rewards: ${rewardSnapshot.error}',
                    ),
                  );
                }
                if (!rewardSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rewards = rewardSnapshot.data!;
                AppFeedback.showBadges(
                  DatabaseHelper.instance.takeNewlyUnlockedRewards(),
                );
                final unlockedCount = rewards
                    .where((reward) => reward['unlocked_at'] != null)
                    .length;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFFF4EBE1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_florist,
                                  size: 42,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Daily streak',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$streak ${streak == 1 ? 'day' : 'days'} '
                                        'in a row',
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  avatar: const Icon(
                                    Icons.stars,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  label: Text('$unlockedCount'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (streak % 7) / 7,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${7 - (streak % 7)} days to the next weekly milestone',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Divider(height: 28),
                            ListenableBuilder(
                              listenable: PilakService.instance,
                              builder: (context, child) => Text(
                                'Balanse: ${PilakService.instance.balance} Pilak',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final reward in rewards)
                      _RewardCard(
                        reward: reward,
                        unlocked: reward['unlocked_at'] != null,
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.unlocked});

  final Map<String, Object?> reward;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final title = reward['title'] as String? ?? 'Reward';
    final description = reward['description'] as String? ?? '';
    final threshold = reward['threshold'] as int? ?? 0;
    final metric = reward['metric'] as String? ?? '';
    final targetDescription = switch (metric) {
      'streak' => '$threshold consecutive study days',
      'activity_count' => '$threshold completed activities',
      'total_score' => '$threshold activity points',
      _ => description,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unlocked
              ? Colors.amber.shade100
              : Colors.grey.shade200,
          child: Icon(
            unlocked ? Icons.workspace_premium : Icons.lock_outline,
            color: unlocked ? Colors.amber.shade800 : Colors.grey,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(unlocked ? description : targetDescription),
        trailing: Icon(
          unlocked ? Icons.check_circle : Icons.lock,
          color: unlocked ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
