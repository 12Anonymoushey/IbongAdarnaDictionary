import 'package:flutter/material.dart';

import '../../app/themes/app_colors.dart';
import '../../data/database_helper.dart';
import '../../services/app_feedback.dart';

class WordCard extends StatefulWidget {
  const WordCard({super.key, required this.word, required this.onTap});

  final Map<String, Object?> word;
  final VoidCallback onTap;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  late bool _isSaved;
  bool _isUpdatingSave = false;

  @override
  void initState() {
    super.initState();
    _isSaved = (widget.word['is_saved'] as int? ?? 0) == 1;
  }

  @override
  void didUpdateWidget(covariant WordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word['is_saved'] != widget.word['is_saved']) {
      _isSaved = (widget.word['is_saved'] as int? ?? 0) == 1;
    }
  }

  Future<void> _toggleSaved() async {
    if (_isUpdatingSave) return;
    setState(() => _isUpdatingSave = true);
    final nextValue = !_isSaved;
    try {
      await DatabaseHelper.instance.setWordSaved(
        widget.word['id'] as int,
        nextValue,
      );
      if (mounted) {
        setState(() => _isSaved = nextValue);
        AppFeedback.show(
          nextValue
              ? 'Saved "${widget.word['term']}".'
              : 'Removed "${widget.word['term']}" from saved words.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.show('Could not update saved word: $error');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingSave = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.word['image_path'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          height: 128,
          child: Row(
            children: [
              SizedBox(
                width: 116,
                height: double.infinity,
                child: imagePath == null || imagePath.isEmpty
                    ? _imageFallback()
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _imageFallback(),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.word['term'] as String? ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          widget.word['definition'] as String? ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        'Tap for full definition',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: _isSaved ? 'Remove saved word' : 'Save word',
                onPressed: _isUpdatingSave ? null : _toggleSaved,
                icon: Icon(
                  _isSaved ? Icons.favorite : Icons.favorite_border,
                  color: _isSaved ? AppColors.crimson : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 36,
        color: Colors.grey,
      ),
    ),
  );
}
