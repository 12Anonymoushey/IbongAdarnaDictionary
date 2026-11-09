import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../growth/analytics_service.dart';
import '../pilak/pilak_service.dart';
import '../../services/app_feedback.dart';
import 'word_card.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, Object?>>> _words;
  bool _advancedFiltersUnlocked = false;
  bool _loadingFilters = false;
  bool _searching = false;
  String? _filterError;
  List<Object> _kabanataOptions = [];
  List<Object> _partOfSpeechOptions = [];
  int? _selectedKabanata;
  String? _selectedPartOfSpeech;
  bool _adarnaWarningShown = false;

  PilakService get _pilakService => PilakService.instance;
  bool get _adarnaSearchLocked =>
      _pilakService.adarnaModeEnabled && _pilakService.adarnaHearts == 0;

  @override
  void initState() {
    super.initState();
    _words = DatabaseHelper.instance.getWords();
    _pilakService.addListener(_onPilakChanged);
    _loadAdvancedFilters();
  }

  void _onPilakChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pilakService.removeListener(_onPilakChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query, {bool allowLastHeartSearch = false}) {
    if (_adarnaSearchLocked && !allowLastHeartSearch) return;
    setState(() {
      _words = DatabaseHelper.instance.getFilteredWords(
        query: query,
        kabanata: _selectedKabanata,
        partOfSpeech: _selectedPartOfSpeech,
      );
    });
  }

  Future<void> _submitSearch(String query) async {
    if (_searching) return;
    if (query.trim().isNotEmpty) {
      setState(() => _searching = true);
      try {
        final service = _pilakService;
        await service.initialize();
        if (service.adarnaModeEnabled &&
            !await service.consumeAdarnaSearchHeart()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Wala ka nang puso. Makakuha muna ng puso sa quiz.',
                ),
              ),
            );
          }
          return;
        }
        try {
          await AnalyticsService.instance.recordVocabularyInteraction(query);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not save search analytics: $error'),
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not search words: $error')),
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    }
    if (mounted) {
      _search(query, allowLastHeartSearch: query.trim().isNotEmpty);
    }
  }

  Future<void> _loadAdvancedFilters() async {
    setState(() => _loadingFilters = true);
    try {
      await PilakService.instance.initialize();
      if (!mounted) return;
      _showAdarnaSearchWarning();
      if (!PilakService.instance.owns('advanced_sql_filters')) return;
      final options = await DatabaseHelper.instance.getWordFilterOptions();
      if (!mounted) return;
      setState(() {
        _advancedFiltersUnlocked = true;
        _kabanataOptions = options['kabanata']!;
        _partOfSpeechOptions = options['part_of_speech']!;
        _words = DatabaseHelper.instance.getFilteredWords(
          query: _searchController.text,
        );
      });
    } catch (error) {
      if (mounted) setState(() => _filterError = '$error');
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  void _showAdarnaSearchWarning() {
    if (_adarnaWarningShown ||
        !_pilakService.adarnaModeEnabled ||
        _pilakService.adarnaHearts == 0) {
      return;
    }
    _adarnaWarningShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppFeedback.show(
          'Adarna Mode is on: searching or opening a word uses one heart.',
        );
      }
    });
  }

  void _applyFilters() => _search(_searchController.text);

  Future<void> _openWord(Map<String, Object?> word) async {
    try {
      final service = _pilakService;
      await service.initialize();
      if (service.adarnaModeEnabled &&
          !await service.consumeAdarnaSearchHeart()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Wala ka nang puso. Makakuha muna ng puso sa quiz.',
              ),
            ),
          );
        }
        return;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open word: $error')));
      }
      return;
    }

    final term = word['term'] as String?;
    if (term != null) {
      try {
        await AnalyticsService.instance.recordVocabularyInteraction(term);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save search analytics: $error')),
          );
        }
      }
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => WordDetailScreen(word: word),
      ),
    );
    if (mounted) _search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search words')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onSubmitted: _submitSearch,
              onChanged: (value) {
                if (!_pilakService.adarnaModeEnabled) _search(value);
              },
              enabled: !_adarnaSearchLocked && !_searching,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _adarnaSearchLocked
                    ? 'No hearts remaining — earn one in a quiz'
                    : 'Search words or definitions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Search words',
                      onPressed: _adarnaSearchLocked || _searching
                          ? null
                          : () => _submitSearch(_searchController.text),
                      icon: _searching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward),
                    ),
                    IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_adarnaSearchLocked)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Wala ka nang puso. Makakuha muna ng puso sa quiz bago maghanap.',
              ),
            ),
          if (_loadingFilters)
            const LinearProgressIndicator(minHeight: 2)
          else if (_filterError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Could not load word filters: $_filterError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (_advancedFiltersUnlocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedKabanata,
                    decoration: const InputDecoration(
                      labelText: 'Kabanata',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Lahat ng kabanata'),
                      ),
                      for (final option in _kabanataOptions)
                        DropdownMenuItem<int?>(
                          value: option as int,
                          child: Text('Kabanata $option'),
                        ),
                    ],
                    onChanged: (value) {
                      _selectedKabanata = value;
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedPartOfSpeech,
                    decoration: const InputDecoration(
                      labelText: 'Bahagi ng pananalita',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Lahat ng bahagi ng pananalita'),
                      ),
                      for (final option in _partOfSpeechOptions)
                        DropdownMenuItem<String?>(
                          value: option as String,
                          child: Text(option),
                        ),
                    ],
                    onChanged: (value) {
                      _selectedPartOfSpeech = value;
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: _words,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load words: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final words = snapshot.data!;
                if (words.isEmpty) {
                  return const Center(child: Text('No matching words found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: words.length,
                  itemBuilder: (context, index) => WordCard(
                    word: words[index],
                    onTap: () => _openWord(words[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
