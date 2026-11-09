import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../../services/app_feedback.dart';
import 'activity_form_screen.dart';
import 'quiz_builder.dart';
import 'quiz_screens.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late Future<List<Map<String, Object?>>> _activities;
  late Future<List<Map<String, Object?>>> _quizDrafts;
  String _category = 'All';
  bool _sortByScore = false;
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _activities = DatabaseHelper.instance.getActivities();
    _quizDrafts = DatabaseHelper.instance.getQuizDrafts();
  }

  Future<void> _resumeQuizDraft(Map<String, Object?> draft) async {
    try {
      final decodedQuestions = jsonDecode(draft['questions'] as String);
      if (decodedQuestions is! List) {
        throw const FormatException('Saved quiz questions are invalid.');
      }
      final questions = decodedQuestions
          .map(
            (question) => QuizQuestion.fromJson(
              Map<String, Object?>.from(question as Map),
            ),
          )
          .toList();
      final mode = QuizMode.values.byName(draft['mode'] as String);
      final source = QuizWordSource.values.byName(draft['source'] as String);
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => QuizPlayScreen(
            name: draft['name'] as String,
            mode: mode,
            source: source,
            questions: questions,
            kabanataNumber: draft['kabanata_number'] as int?,
          ),
        ),
      );
      if (result == true && mounted) {
        await DatabaseHelper.instance.deleteQuizDraft(draft['id'] as int);
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open this saved quiz: $error')),
        );
      }
    }
  }

  Future<void> _deleteQuizDraft(Map<String, Object?> draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved quiz?'),
        content: Text('Delete "${draft['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteQuizDraft(draft['id'] as int);
      AppFeedback.show('Quiz "${draft['name']}" deleted.');
      if (mounted) setState(_reload);
    }
  }

  Widget _buildQuizDraftCard(Map<String, Object?> draft) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.bookmark_outline)),
      title: Text(
        draft['name'] as String,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_quizModeLabel(draft['mode'] as String)} · '
        '${_quizSourceLabel(draft['source'] as String)}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          if (action == 'delete') _deleteQuizDraft(draft);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => _resumeQuizDraft(draft),
    ),
  );

  Widget _buildActivityCard(Map<String, Object?> activity) {
    final score = activity['score'] as int? ?? 0;
    final maxScore = activity['max_score'] as int? ?? 100;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: const Icon(Icons.edit_note_outlined),
        ),
        title: Text(
          activity['type'] as String? ?? 'Activity',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$score / $maxScore points · '
          '${_formatDate(activity['date'] as String?)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              _openForm(activity: activity);
            } else if (action == 'delete') {
              _deleteActivity(activity);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _openForm(activity: activity),
      ),
    );
  }

  String _quizModeLabel(String mode) => switch (mode) {
    'multipleChoice' => 'Multiple Choice',
    'identification' => 'Identification',
    'flashcards' => 'Flashcards',
    _ => mode,
  };

  String _quizSourceLabel(String source) => switch (source) {
    'freestyle' => 'Freestyle',
    'chooseWords' => 'Choose Words',
    'randomWords' => 'Randomize',
    'kabanataQuiz' => 'Kabanata Quiz',
    _ => source,
  };

  Future<void> _openForm({Map<String, Object?>? activity}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => ActivityInputsScreen(
          selectedMode: activity?['type'] as String? ?? 'Multiple Choice',
          activity: activity,
        ),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _deleteActivity(Map<String, Object?> activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text('Delete "${activity['type']}" from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteActivity(activity['id'] as int);
      final details = activity['details'] as String? ?? '';
      AppFeedback.show(
        details.contains('"quizMode"')
            ? 'Quiz "${activity['type']}" deleted from history.'
            : 'Activity "${activity['type']}" deleted.',
      );
      AppFeedback.showBadges(
        DatabaseHelper.instance.takeNewlyUnlockedRewards(),
      );
      if (mounted) setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search activities',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _query = value),
              )
            : const Text('Activities'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search activities',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              _query = '';
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<Map<String, Object?>>>(
                    future: _activities,
                    builder: (context, snapshot) {
                      final types =
                          snapshot.data
                              ?.map((item) => item['type'] as String? ?? '')
                              .toSet()
                              .toList()
                            ?..sort();
                      return DropdownButtonFormField<String>(
                        initialValue: types?.contains(_category) == true
                            ? _category
                            : 'All',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All categories'),
                          ),
                          for (final type in types ?? <String>[])
                            DropdownMenuItem(value: type, child: Text(type)),
                        ],
                        onChanged: (value) =>
                            setState(() => _category = value ?? 'All'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: _sortByScore ? 'Sort by date' : 'Sort by score',
                  onPressed: () => setState(() => _sortByScore = !_sortByScore),
                  icon: Icon(
                    _sortByScore ? Icons.score_outlined : Icons.swap_vert,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: _activities,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load activities: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.where((activity) {
                  final type = activity['type'] as String? ?? '';
                  final details = activity['details'] as String? ?? '';
                  final matchesType = _category == 'All' || type == _category;
                  final matchesQuery =
                      _query.isEmpty ||
                      type.toLowerCase().contains(_query.toLowerCase()) ||
                      details.toLowerCase().contains(_query.toLowerCase());
                  return matchesType && matchesQuery;
                }).toList();
                if (_sortByScore) {
                  items.sort((a, b) {
                    final left =
                        (a['score'] as int? ?? 0) /
                        ((a['max_score'] as int? ?? 100).clamp(1, 1000000));
                    final right =
                        (b['score'] as int? ?? 0) /
                        ((b['max_score'] as int? ?? 100).clamp(1, 1000000));
                    return right.compareTo(left);
                  });
                }
                return FutureBuilder<List<Map<String, Object?>>>(
                  future: _quizDrafts,
                  builder: (context, draftsSnapshot) {
                    if (draftsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load saved quizzes: ${draftsSnapshot.error}',
                        ),
                      );
                    }
                    if (!draftsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final drafts = draftsSnapshot.data!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      children: [
                        if (drafts.isNotEmpty) ...[
                          Text(
                            'Saved quizzes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          for (final draft in drafts)
                            _buildQuizDraftCard(draft),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Activity history',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No activities yet. Add one to start tracking.',
                              ),
                            ),
                          )
                        else
                          for (final activity in items)
                            _buildActivityCard(activity),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add activity',
        onPressed: () => _showChooseModeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return 'Date unavailable';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showChooseModeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => ChooseModeDialog(
        onCompleted: () {
          if (mounted) setState(_reload);
        },
      ),
    );
  }
}
