import 'package:flutter/material.dart';

import '../app/themes/app_colors.dart';

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

Future<void> showStepByStepTutorial({
  required BuildContext context,
  required String title,
  required List<TutorialStep> steps,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TutorialCoachMarks(title: title, steps: steps),
  );
}

class _TutorialCoachMarks extends StatefulWidget {
  const _TutorialCoachMarks({required this.title, required this.steps});

  final String title;
  final List<TutorialStep> steps;

  @override
  State<_TutorialCoachMarks> createState() => _TutorialCoachMarksState();
}

class _TutorialCoachMarksState extends State<_TutorialCoachMarks> {
  int _stepIndex = 0;

  void _next() {
    if (_stepIndex == widget.steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _stepIndex++);
  }

  void _previous() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_stepIndex];
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close tutorial',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: Icon(step.icon, color: colors.primary, size: 38),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < widget.steps.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _stepIndex ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == _stepIndex
                            ? colors.primary
                            : colors.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: _stepIndex == 0 ? null : _previous,
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  Text(
                    '${_stepIndex + 1} of ${widget.steps.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _stepIndex == widget.steps.length - 1 ? 'Done' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
