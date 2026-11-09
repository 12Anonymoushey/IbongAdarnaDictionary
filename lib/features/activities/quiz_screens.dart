import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/themes/app_colors.dart';
import '../../data/database_helper.dart';
import '../../services/app_feedback.dart';
import '../pilak/pilak_service.dart';
import '../kabanata/kabanata_data.dart';
import 'quiz_builder.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key, required this.selectedMode});

  final String selectedMode;

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countController = TextEditingController(text: '5');
  final _searchController = TextEditingController();
  final List<_FreestyleEntry> _freestyleEntries = [_FreestyleEntry()];
  late final QuizMode _mode;
  late final Future<List<Map<String, Object?>>> _dictionaryWords;
  QuizWordSource _source = QuizWordSource.freestyle;
  final Set<int> _selectedWordIds = {};
  int _selectedKabanata = 1;
  String _searchQuery = '';
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _mode = _parseMode(widget.selectedMode);
    _nameController.text = widget.selectedMode;
    _dictionaryWords = _loadDictionaryWords();
  }

  Future<List<Map<String, Object?>>> _loadDictionaryWords() async {
    await PilakService.instance.initialize();
    return DatabaseHelper.instance.getWords();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _searchController.dispose();
    for (final entry in _freestyleEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  List<QuizQuestion>? _createQuestions(
    List<Map<String, Object?>> dictionaryWords,
  ) {
    if (!_formKey.currentState!.validate()) return null;
    List<Map<String, Object?>> quizWords;
    switch (_source) {
      case QuizWordSource.freestyle:
        quizWords = [
          for (final entry in _freestyleEntries)
            {
              'term': entry.termController.text.trim(),
              'definition': entry.definitionController.text.trim(),
            },
        ];
        final terms = quizWords
            .map(
              (word) => (word['term'] as String)
                  .trim()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .toLowerCase(),
            )
            .toList();
        if (terms.toSet().length != terms.length) {
          _showMessage('Each freestyle word must be unique.');
          return null;
        }
      case QuizWordSource.chooseWords:
        final count = int.parse(_countController.text.trim());
        if (_selectedWordIds.length != count) {
          _showMessage('Select exactly $count words to continue.');
          return null;
        }
        quizWords = dictionaryWords
            .where((word) => _selectedWordIds.contains(word['id'] as int))
            .toList();
      case QuizWordSource.randomWords:
        final count = int.parse(_countController.text.trim());
        try {
          quizWords = QuizBuilder.randomWords(dictionaryWords, count);
        } on RangeError {
          _showMessage('Choose a number between 1 and the available words.');
          return null;
        }
      case QuizWordSource.kabanataQuiz:
        quizWords = _chapterQuizWords(dictionaryWords);
        if (quizWords.isEmpty) {
          _showMessage(
            'Wala pang salitang nakatala sa Kabanata $_selectedKabanata.',
          );
          return null;
        }
    }

    try {
      return QuizBuilder.build(
        mode: _mode,
        words: quizWords,
        dictionaryWords: dictionaryWords,
      );
    } on ArgumentError catch (error) {
      _showMessage(
        error.message?.toString() ?? 'The quiz could not be created.',
      );
      return null;
    }
  }

  String get _quizName => _source == QuizWordSource.kabanataQuiz
      ? '${_nameController.text.trim()} - Kabanata $_selectedKabanata'
      : _nameController.text.trim();

  Future<void> _startQuiz(List<Map<String, Object?>> dictionaryWords) async {
    if (_isStarting) return;
    final questions = _createQuestions(dictionaryWords);
    if (questions == null) return;
    setState(() => _isStarting = true);
    AppFeedback.show('Quiz created. Starting $_quizName.');
    try {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => QuizPlayScreen(
            name: _quizName,
            mode: _mode,
            source: _source,
            questions: questions,
            kabanataNumber: _source == QuizWordSource.kabanataQuiz
                ? _selectedKabanata
                : null,
          ),
        ),
      );
      if (completed == true && mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _saveQuizForLater(
    List<Map<String, Object?>> dictionaryWords,
  ) async {
    if (_isStarting) return;
    final questions = _createQuestions(dictionaryWords);
    if (questions == null) return;
    setState(() => _isStarting = true);
    try {
      await DatabaseHelper.instance.saveQuizDraft(
        name: _quizName,
        mode: _mode.name,
        source: _source.name,
        kabanataNumber: _source == QuizWordSource.kabanataQuiz
            ? _selectedKabanata
            : null,
        questions: jsonEncode(
          questions.map((question) => question.toJson()).toList(),
        ),
      );
      if (mounted) {
        AppFeedback.show('Quiz "$_quizName" saved for later.');
        Navigator.pop(context, true);
      }
    } catch (error) {
      _showMessage('Could not save this quiz for later: $error');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create ${widget.selectedMode} quiz')),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _dictionaryWords,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load dictionary words: ${snapshot.error}',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = QuizBuilder.uniqueWords(snapshot.data!);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Quiz name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name for your quiz.'
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose how to add quiz words',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.sapphire,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final source in QuizWordSource.values.where(
                  (source) =>
                      source != QuizWordSource.kabanataQuiz ||
                      PilakService.instance.owns('custom_quiz_architect'),
                ))
                  _SourceOption(
                    source: source,
                    selected: source == _source,
                    onTap: () => setState(() => _source = source),
                  ),
                const SizedBox(height: 12),
                if (_source == QuizWordSource.freestyle)
                  _buildFreestyleEditor()
                else if (_source == QuizWordSource.chooseWords)
                  _buildWordPicker(words)
                else if (_source == QuizWordSource.kabanataQuiz)
                  _buildKabanataQuiz(words)
                else
                  _buildRandomCount(words.length),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isStarting
                      ? null
                      : () => _saveQuizForLater(words),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save for later'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _isStarting ? null : () => _startQuiz(words),
                  icon: _isStarting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isStarting ? 'Preparing quiz...' : 'Start now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFreestyleEditor() {
    final minimumEntries = _mode == QuizMode.multipleChoice ? 2 : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _mode == QuizMode.multipleChoice
              ? 'Add at least two term/definition pairs. Wrong choices are picked from the dictionary.'
              : 'Add the words and definitions you want to study.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _freestyleEntries.length; index++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Word ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_freestyleEntries.length > minimumEntries)
                        IconButton(
                          tooltip: 'Remove word',
                          onPressed: () =>
                              setState(() => _removeFreestyleEntry(index)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  TextFormField(
                    controller: _freestyleEntries[index].termController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Word or answer',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _source == QuizWordSource.freestyle &&
                            (value == null || value.trim().isEmpty)
                        ? 'Enter a word.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _freestyleEntries[index].definitionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Definition or clue',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        _source == QuizWordSource.freestyle &&
                            (value == null || value.trim().isEmpty)
                        ? 'Enter a definition or clue.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () =>
              setState(() => _freestyleEntries.add(_FreestyleEntry())),
          icon: const Icon(Icons.add),
          label: const Text('Add another word'),
        ),
      ],
    );
  }

  Widget _buildRandomCount(int availableCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Random words are selected from the full dictionary without repeats. '
          '$availableCount words available.',
        ),
        const SizedBox(height: 12),
        _countField(availableCount),
      ],
    );
  }

  Widget _buildKabanataQuiz(List<Map<String, Object?>> words) {
    final kabanata = kabanataByNumber(_selectedKabanata)!;
    final chapterWords = _chapterQuizWords(words);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _selectedKabanata,
          decoration: const InputDecoration(
            labelText: 'Pumili ng kabanata',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final item in kabanataList)
              DropdownMenuItem(
                value: item.number,
                child: Text(
                  'Kabanata ${item.number}: ${item.title}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedKabanata = value);
            }
          },
        ),
        const SizedBox(height: 12),
        Text(kabanata.description),
        const SizedBox(height: 6),
        Text(
          chapterWords.isEmpty
              ? 'Wala pang salitang nakatala sa kabanatang ito.'
              : '${chapterWords.length} salitang kasama sa pagsusulit.',
          style: TextStyle(
            color: chapterWords.isEmpty
                ? AppColors.crimson
                : AppColors.sapphire,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Map<String, Object?>> _chapterQuizWords(
    List<Map<String, Object?>> words,
  ) {
    final chapterWords = QuizBuilder.wordsForKabanata(words, _selectedKabanata);
    return chapterWords.length > 20
        ? chapterWords.take(20).toList()
        : chapterWords;
  }

  Widget _buildWordPicker(List<Map<String, Object?>> words) {
    final count = int.tryParse(_countController.text) ?? 0;
    final filteredWords = words.where((word) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final term = (word['term'] as String? ?? '').toLowerCase();
      final definition = (word['definition'] as String? ?? '').toLowerCase();
      return term.contains(query) || definition.contains(query);
    }).toList();
    final targetIsValid = count > 0 && count <= words.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Set a word count, then select that many dictionary entries.',
        ),
        const SizedBox(height: 12),
        _countField(words.length),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            labelText: 'Search dictionary',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          targetIsValid
              ? '${_selectedWordIds.length} of $count selected'
              : 'Choose a count from 1 to ${words.length}.',
          style: TextStyle(
            color: _selectedWordIds.length == count && targetIsValid
                ? AppColors.sapphire
                : AppColors.crimson,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (filteredWords.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No dictionary words match your search.'),
          )
        else
          SizedBox(
            height: 340,
            child: ListView.builder(
              itemCount: filteredWords.length,
              itemBuilder: (context, index) {
                final word = filteredWords[index];
                final id = word['id'] as int;
                final selected = _selectedWordIds.contains(id);
                final canSelect =
                    targetIsValid &&
                    (_selectedWordIds.length < count || selected);
                return CheckboxListTile(
                  value: selected,
                  title: Text(word['term'] as String? ?? ''),
                  subtitle: Text(
                    word['definition'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.crimson,
                  onChanged: canSelect
                      ? (value) => setState(() {
                          if (value == true) {
                            _selectedWordIds.add(id);
                          } else {
                            _selectedWordIds.remove(id);
                          }
                        })
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _countField(int availableCount) {
    return TextFormField(
      controller: _countController,
      keyboardType: TextInputType.number,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: 'Number of words (1-$availableCount)',
        border: const OutlineInputBorder(),
        helperText: _source == QuizWordSource.chooseWords
            ? 'Currently selected: ${_selectedWordIds.length}'
            : null,
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < 1 || parsed > availableCount) {
          return 'Enter a number from 1 to $availableCount.';
        }
        if (_source == QuizWordSource.chooseWords &&
            _selectedWordIds.length > parsed) {
          return 'Reduce the selected words to $parsed.';
        }
        return null;
      },
    );
  }

  void _removeFreestyleEntry(int index) {
    final entry = _freestyleEntries.removeAt(index);
    entry.dispose();
  }
}

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({
    super.key,
    required this.name,
    required this.mode,
    required this.source,
    required this.questions,
    this.kabanataNumber,
    this.onSaveResult,
  });

  final String name;
  final QuizMode mode;
  final QuizWordSource source;
  final List<QuizQuestion> questions;
  final int? kabanataNumber;
  final Future<void> Function(int score, int maxScore, String details)?
  onSaveResult;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final _answerController = TextEditingController();
  final List<bool?> _results = [];
  int _questionIndex = 0;
  String? _selectedOption;
  bool _submitted = false;
  bool _revealed = false;
  bool _savingResult = false;
  bool _completed = false;
  Object? _saveError;
  int _earnedPilak = 0;

  QuizQuestion get _question => widget.questions[_questionIndex];
  int get _score => _results.where((result) => result == true).length;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (_submitted) return;
    final response = widget.mode == QuizMode.multipleChoice
        ? _selectedOption
        : _answerController.text.trim();
    if (response == null || response.isEmpty) return;

    final correct = QuizBuilder.answerMatches(response, _question.answer);
    setState(() {
      _submitted = true;
      _results.add(correct);
    });
  }

  Future<void> _nextQuestion() async {
    if (!_submitted || _savingResult) return;
    if (_questionIndex == widget.questions.length - 1) {
      await _saveResult();
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedOption = null;
      _answerController.clear();
      _submitted = false;
      _revealed = false;
    });
  }

  Future<void> _markFlashcard(bool known) async {
    if (_submitted || _savingResult) return;
    setState(() {
      _submitted = true;
      _results.add(known);
    });
  }

  Future<void> _saveResult() async {
    if (_savingResult || _completed) return;
    setState(() {
      _savingResult = true;
      _saveError = null;
    });
    final answers = [
      for (var index = 0; index < widget.questions.length; index++)
        {
          'prompt': widget.questions[index].prompt,
          'answer': widget.questions[index].answer,
          'correct': _results[index],
        },
    ];
    try {
      final details = jsonEncode({
        'quizMode': widget.mode.name,
        'wordSource': widget.source.name,
        if (widget.kabanataNumber != null) 'kabanata': widget.kabanataNumber,
        'questions': answers,
      });
      final saveResult = widget.onSaveResult;
      if (saveResult == null) {
        _earnedPilak = await PilakService.instance.completeQuiz(
          activityType: widget.name,
          score: _score,
          maxScore: widget.questions.length,
          details: details,
        );
      } else {
        await saveResult(_score, widget.questions.length, details);
      }
      if (mounted) setState(() => _completed = true);
    } catch (error) {
      if (mounted) setState(() => _saveError = error);
    } finally {
      if (mounted) setState(() => _savingResult = false);
    }
  }

  void _retakeQuiz() {
    _answerController.clear();
    setState(() {
      _results.clear();
      _questionIndex = 0;
      _selectedOption = null;
      _submitted = false;
      _revealed = false;
      _completed = false;
      _saveError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompletion();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${_questionIndex + 1}/${widget.questions.length}'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(
              value: (_questionIndex + 1) / widget.questions.length,
              color: AppColors.crimson,
            ),
            const SizedBox(height: 24),
            Text(
              widget.mode == QuizMode.flashcards
                  ? 'What is the definition?'
                  : 'What word matches this definition?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.sapphire,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppColors.parchment,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.mode == QuizMode.flashcards && _revealed
                      ? _question.answer
                      : _question.prompt,
                  style: const TextStyle(fontSize: 20, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.mode == QuizMode.multipleChoice)
              ..._question.options.map(_buildOption)
            else if (widget.mode == QuizMode.identification)
              TextField(
                controller: _answerController,
                enabled: !_submitted,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submitAnswer(),
                decoration: const InputDecoration(
                  labelText: 'Type your answer',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text(
                _revealed
                    ? 'Answer revealed. Did you know this word?'
                    : 'Tap “Reveal answer” when you are ready.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (widget.mode == QuizMode.flashcards && _submitted)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _results.last == true
                      ? 'Marked as known.'
                      : 'Marked to review.',
                  style: TextStyle(
                    color: _results.last == true
                        ? Colors.green.shade800
                        : AppColors.crimson,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_submitted && widget.mode != QuizMode.flashcards)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _results.last == true
                      ? 'Correct!'
                      : 'Answer: ${_question.answer}',
                  style: TextStyle(
                    color: _results.last == true
                        ? Colors.green.shade800
                        : AppColors.crimson,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Could not save your quiz: $_saveError',
                  style: const TextStyle(color: AppColors.crimson),
                ),
              ),
            const SizedBox(height: 24),
            if (widget.mode == QuizMode.flashcards && !_revealed)
              FilledButton(
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Reveal answer'),
              )
            else if (widget.mode == QuizMode.flashcards && !_submitted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markFlashcard(false),
                      child: const Text('Review again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _markFlashcard(true),
                      child: const Text('I knew it'),
                    ),
                  ),
                ],
              )
            else if (widget.mode == QuizMode.flashcards)
              FilledButton(
                onPressed: _savingResult ? null : _nextQuestion,
                child: _savingResult
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _questionIndex == widget.questions.length - 1
                            ? 'Finish quiz'
                            : 'Next flashcard',
                      ),
              )
            else if (!_submitted)
              FilledButton(
                onPressed:
                    widget.mode == QuizMode.multipleChoice &&
                        _selectedOption == null
                    ? null
                    : _submitAnswer,
                child: const Text('Check answer'),
              )
            else
              FilledButton(
                onPressed: _savingResult ? null : _nextQuestion,
                child: _savingResult
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _questionIndex == widget.questions.length - 1
                            ? 'Finish quiz'
                            : 'Next question',
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String option) {
    final isCorrectAnswer =
        _submitted && QuizBuilder.answerMatches(option, _question.answer);
    final isIncorrectSelection =
        _submitted && option == _selectedOption && !isCorrectAnswer;
    final color = isCorrectAnswer
        ? Colors.green.shade100
        : isIncorrectSelection
        ? AppColors.crimson.withValues(alpha: 0.14)
        : null;
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          option == _selectedOption
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: option == _selectedOption
              ? AppColors.crimson
              : AppColors.sapphire,
        ),
        title: Text(option),
        onTap: _submitted
            ? null
            : () => setState(() => _selectedOption = option),
      ),
    );
  }

  Widget _buildCompletion() {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz complete')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: AppColors.gold, size: 72),
              const SizedBox(height: 16),
              Text(
                '$_score / ${widget.questions.length}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sapphire,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your quiz result was saved to Activities. Each attempt is recorded separately.',
                textAlign: TextAlign.center,
              ),
              if (widget.onSaveResult == null) ...[
                const SizedBox(height: 8),
                Text(
                  '+$_earnedPilak Pilak',
                  style: const TextStyle(
                    color: AppColors.sapphire,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _retakeQuiz,
                icon: const Icon(Icons.replay),
                label: const Text('Retake quiz'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final QuizWordSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon) = switch (source) {
      QuizWordSource.freestyle => (
        'Freestyle',
        'Enter your own words and definitions.',
        Icons.edit_note,
      ),
      QuizWordSource.chooseWords => (
        'Choose Words',
        'Pick dictionary words and search the list.',
        Icons.checklist,
      ),
      QuizWordSource.randomWords => (
        'Randomize',
        'Generate a quiz from random dictionary words.',
        Icons.shuffle,
      ),
      QuizWordSource.kabanataQuiz => (
        'Kabanata Quiz',
        'Sagutan ang lahat ng salita mula sa napiling kabanata.',
        Icons.auto_stories_outlined,
      ),
    };
    return Card(
      color: selected ? AppColors.sapphire.withValues(alpha: 0.08) : null,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: AppColors.sapphire),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? AppColors.crimson : AppColors.sapphire,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _FreestyleEntry {
  final TextEditingController termController = TextEditingController();
  final TextEditingController definitionController = TextEditingController();

  void dispose() {
    termController.dispose();
    definitionController.dispose();
  }
}

QuizMode _parseMode(String mode) => switch (mode) {
  'Multiple Choice' => QuizMode.multipleChoice,
  'Identification' => QuizMode.identification,
  'Flashcards' || 'Cards' => QuizMode.flashcards,
  _ => throw ArgumentError.value(mode, 'mode', 'Unknown quiz mode.'),
};
