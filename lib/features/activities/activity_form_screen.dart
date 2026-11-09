import 'package:flutter/material.dart';

import '../../app/themes/app_colors.dart';
import '../../data/database_helper.dart';
import '../../services/app_feedback.dart';
import 'quiz_screens.dart';

class ChooseModeDialog extends StatelessWidget {
  const ChooseModeDialog({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(context, 'Multiple Choice', Icons.list_alt),
          _modeButton(context, 'Identification', Icons.text_fields),
          _modeButton(context, 'Flashcards', Icons.style),
        ],
      ),
    );
  }

  Widget _modeButton(BuildContext context, String mode, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.sapphire),
      title: Text(mode),
      onTap: () {
        Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (context) => QuizSetupScreen(selectedMode: mode),
          ),
        ).then((completed) {
          if (!context.mounted) return;
          Navigator.pop(context);
          if (completed == true) onCompleted?.call();
        });
      },
    );
  }
}

class ActivityInputsScreen extends StatefulWidget {
  const ActivityInputsScreen({
    super.key,
    required this.selectedMode,
    this.activity,
  });

  final String selectedMode;
  final Map<String, Object?>? activity;

  @override
  State<ActivityInputsScreen> createState() => _ActivityInputsScreenState();
}

class _ActivityInputsScreenState extends State<ActivityInputsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeController;
  late final TextEditingController _scoreController;
  late final TextEditingController _maxScoreController;
  late final TextEditingController _detailsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _typeController = TextEditingController(
      text: activity?['type'] as String? ?? widget.selectedMode,
    );
    _scoreController = TextEditingController(
      text: '${activity?['score'] as int? ?? 0}',
    );
    _maxScoreController = TextEditingController(
      text: '${activity?['max_score'] as int? ?? 100}',
    );
    _detailsController = TextEditingController(
      text: activity?['details'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _scoreController.dispose();
    _maxScoreController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    final score = int.parse(_scoreController.text.trim());
    final maxScore = int.parse(_maxScoreController.text.trim());
    final activityId = widget.activity?['id'] as int?;
    try {
      if (activityId == null) {
        await DatabaseHelper.instance.insertActivity(
          type: _typeController.text,
          score: score,
          maxScore: maxScore,
          details: _detailsController.text,
        );
      } else {
        await DatabaseHelper.instance.updateActivity(
          id: activityId,
          type: _typeController.text,
          score: score,
          maxScore: maxScore,
          details: _detailsController.text,
          date: DateTime.tryParse(widget.activity?['date'] as String? ?? ''),
        );
      }
      final previousDetails = widget.activity?['details'];
      final isQuiz =
          previousDetails is String && previousDetails.contains('"quizMode"');
      AppFeedback.show(
        activityId == null
            ? 'Activity created.'
            : isQuiz
            ? 'Quiz updated.'
            : 'Activity updated.',
      );
      AppFeedback.showBadges(
        DatabaseHelper.instance.takeNewlyUnlockedRewards(),
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit activity' : widget.selectedMode),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Activity name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an activity name.'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Score',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final score = int.tryParse(value ?? '');
                      if (score == null || score < 0) {
                        return 'Enter a valid score.';
                      }
                      final max = int.tryParse(_maxScoreController.text);
                      if (max != null && score > max) {
                        return 'Score cannot exceed max.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxScoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum score',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final max = int.tryParse(value ?? '');
                      if (max == null || max <= 0) {
                        return 'Enter a positive maximum.';
                      }
                      final score = int.tryParse(_scoreController.text);
                      if (score != null && score > max) {
                        return 'Max must be ≥ score.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Activity notes or questions',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'SAVE CHANGES' : 'SAVE ACTIVITY'),
            ),
          ],
        ),
      ),
    );
  }
}
