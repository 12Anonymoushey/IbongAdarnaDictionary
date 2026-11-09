import 'package:flutter/material.dart';

import '../../app/themes/app_colors.dart';
import '../../data/database_helper.dart';
import '../growth/analytics_service.dart';
import '../pilak/pilak_service.dart';
import '../search/word_card.dart';
import '../search/word_detail_screen.dart';
import '../../services/app_feedback.dart';
import 'kabanata_data.dart';

class MgaKabanataScreen extends StatefulWidget {
  const MgaKabanataScreen({super.key});

  @override
  State<MgaKabanataScreen> createState() => _MgaKabanataScreenState();
}

class _MgaKabanataScreenState extends State<MgaKabanataScreen> {
  @override
  void initState() {
    super.initState();
    _warnAboutAdarnaHearts();
  }

  Future<void> _warnAboutAdarnaHearts() async {
    final service = PilakService.instance;
    try {
      await service.initialize();
    } catch (error) {
      if (mounted) {
        AppFeedback.show('Could not check Adarna hearts: $error');
      }
      return;
    }
    if (!mounted || !service.adarnaModeEnabled || service.adarnaHearts == 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppFeedback.show(
          'Adarna Mode is on: searching or opening a word in this chapter uses one heart.',
        );
      }
    });
  }

  void _openKabanata(BuildContext context, Kabanata kabanata) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => KabanataWordsScreen(kabanata: kabanata),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            'Mga Kabanata',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.sapphire,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Piliin ang kabanata upang makita ang mga salita nito.'),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: kabanataList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final kabanata = kabanataList[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openKabanata(context, kabanata),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.asset(
                          kabanata.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                                color: Color(0xFFE5E7EB),
                                child: Icon(Icons.menu_book_outlined, size: 48),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KABANATA ${kabanata.number}',
                              style: const TextStyle(
                                color: AppColors.crimson,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kabanata.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.sapphire,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class KabanataWordsScreen extends StatefulWidget {
  const KabanataWordsScreen({super.key, required this.kabanata});

  final Kabanata kabanata;

  @override
  State<KabanataWordsScreen> createState() => _KabanataWordsScreenState();
}

class _KabanataWordsScreenState extends State<KabanataWordsScreen> {
  final _searchController = TextEditingController();
  late Future<List<Map<String, Object?>>> _words;
  bool _searching = false;

  PilakService get _pilakService => PilakService.instance;
  bool get _adarnaSearchLocked =>
      _pilakService.adarnaModeEnabled && _pilakService.adarnaHearts == 0;

  @override
  void initState() {
    super.initState();
    _pilakService.addListener(_onPilakChanged);
    _words = DatabaseHelper.instance.getWordsByKabanata(widget.kabanata.number);
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
      _words = DatabaseHelper.instance.getWordsByKabanata(
        widget.kabanata.number,
        query,
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
                content: Text('Hindi ma-save ang search analytics: $error'),
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hindi mahanap ang salita: $error')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hindi mabuksan ang salita: $error')),
        );
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
            SnackBar(
              content: Text('Hindi ma-save ang search analytics: $error'),
            ),
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
      appBar: AppBar(title: Text('Kabanata ${widget.kabanata.number}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kabanata.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.sapphire,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(widget.kabanata.description),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onSubmitted: _submitSearch,
                  onChanged: (value) {
                    if (!_pilakService.adarnaModeEnabled) _search(value);
                  },
                  enabled: !_adarnaSearchLocked && !_searching,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _adarnaSearchLocked
                        ? 'Wala nang puso — kumpletuhin ang quiz para makakuha'
                        : 'Hanap ng salita sa kabanata',
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
              ],
            ),
          ),
          if (_adarnaSearchLocked)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Wala ka nang puso. Makakuha muna ng puso sa quiz bago maghanap.',
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: _words,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Hindi ma-load ang mga salita: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final words = snapshot.data!;
                if (words.isEmpty) {
                  return const Center(
                    child: Text(
                      'Wala pang salitang nakatala sa kabanatang ito.',
                    ),
                  );
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
