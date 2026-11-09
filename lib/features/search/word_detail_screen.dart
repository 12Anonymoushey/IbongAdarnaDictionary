import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/themes/app_colors.dart';
import '../../data/database_helper.dart';
import '../kabanata/kabanata_data.dart';
import '../../services/speech_service.dart';
import '../../services/app_feedback.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, required this.word});

  final Map<String, Object?> word;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = (widget.word['is_saved'] as int? ?? 0) == 1;
  }

  Future<void> _toggleSaved() async {
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
              ? 'Saved "$_wordTerm".'
              : 'Removed "$_wordTerm" from saved words.',
        );
      }
    } catch (error) {
      if (mounted) AppFeedback.show('Could not update saved word: $error');
    }
  }

  String get _wordTerm => widget.word['term'] as String? ?? '';

  Future<void> _shareWord() async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          subject: _wordTerm,
          text: '$_wordTerm\n\n${widget.word['definition'] as String? ?? ''}',
        ),
      );
      if (result.status == ShareResultStatus.success) {
        AppFeedback.show('Shared "$_wordTerm" successfully.');
      }
    } catch (error) {
      if (mounted) AppFeedback.show('Could not share "$_wordTerm": $error');
    }
  }

  Future<void> _speak(String text) async {
    try {
      await SpeechService.instance.speak(text);
    } on SpeechException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.word['image_path'] as String?;
    final term = _wordTerm;
    final partOfSpeech = _metadataValue('part_of_speech');
    final definition = widget.word['definition'] as String? ?? '';
    final kabanataValue = widget.word['kabanata'];
    final kabanataNumber = kabanataValue is int
        ? kabanataValue
        : int.tryParse('$kabanataValue');
    final kabanata = kabanataByNumber(kabanataNumber);
    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _WordHero(
            term: term,
            saved: _isSaved,
            onSave: _toggleSaved,
            onShare: _shareWord,
          ),
          if (imagePath != null && imagePath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: AppColors.sapphire.withValues(alpha: 0.08),
                    child: const Icon(Icons.menu_book_outlined, size: 64),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (partOfSpeech.isNotEmpty) ...[
                  Text(
                    partOfSpeech,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _PronunciationRow(term: term, onSpeak: () => _speak(term)),
                const SizedBox(height: 20),
                Text(
                  'Kahulugan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.sapphire,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  definition,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.midnight, height: 1.55),
                ),
                if (_metadataValue('sample_sentence').isNotEmpty)
                  _WordMetadata(
                    title: 'Halimbawa',
                    value: _metadataValue('sample_sentence'),
                    italic: true,
                  ),
                if (_metadataValue('synonyms').isNotEmpty)
                  _WordMetadata(
                    title: 'Kasingkahulugan',
                    value: _metadataValue('synonyms'),
                  ),
                if (_metadataValue('antonyms').isNotEmpty)
                  _WordMetadata(
                    title: 'Kasalungat',
                    value: _metadataValue('antonyms'),
                  ),
                if (kabanataNumber != null)
                  _WordMetadata(
                    title: 'Kabanata',
                    value: kabanata == null
                        ? 'Kabanata $kabanataNumber'
                        : kabanata.label,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _metadataValue(String key) {
    final value = widget.word[key];
    return value is String ? value.trim() : '';
  }
}

class _WordMetadata extends StatelessWidget {
  const _WordMetadata({
    required this.title,
    required this.value,
    this.italic = false,
  });

  final String title;
  final String value;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.sapphire,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              color: AppColors.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordHero extends StatelessWidget {
  const _WordHero({
    required this.term,
    required this.saved,
    required this.onSave,
    required this.onShare,
  });

  final String term;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, AppColors.midnight],
        ),
      ),
      child: Column(
        children: [
          Text(
            term,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroAction(
                tooltip: saved ? 'Remove saved word' : 'Save word',
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                onPressed: onSave,
              ),
              const SizedBox(width: 20),
              _HeroAction(
                tooltip: 'Share word',
                icon: Icons.share_outlined,
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
          shape: const CircleBorder(),
          minimumSize: const Size(44, 44),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _PronunciationRow extends StatelessWidget {
  const _PronunciationRow({required this.term, required this.onSpeak});

  final String term;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Bigkas',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.midnight.withValues(alpha: 0.72)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            term,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.midnight, letterSpacing: 0.3),
          ),
        ),
        IconButton(
          tooltip: 'Listen to pronunciation',
          visualDensity: VisualDensity.compact,
          onPressed: onSpeak,
          icon: const Icon(Icons.volume_up_outlined),
          color: AppColors.sapphire,
        ),
      ],
    );
  }
}
