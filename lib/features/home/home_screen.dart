import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../../services/speech_service.dart';
import '../growth/analytics_service.dart';
import '../search/search_screen.dart';
import '../search/word_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, Object?>?> _wordOfDay;

  @override
  void initState() {
    super.initState();
    _wordOfDay = DatabaseHelper.instance.getWordOfTheDay();
    _speakIfEnabled();
  }

  Future<void> _speakIfEnabled() async {
    final speakAutomatically = await DatabaseHelper.instance
        .getSpeakWordOfDaySetting();
    if (!speakAutomatically || !mounted) return;
    final word = await _wordOfDay;
    if (word != null && mounted) {
      await _speak(word['term'] as String? ?? '');
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

  Future<void> _openWord(Map<String, Object?> word) async {
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, Object?>?>(
        future: _wordOfDay,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the word of the day: ${snapshot.error}',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final word = snapshot.data;
          if (word == null) {
            return const Center(
              child: Text('There are no dictionary entries yet.'),
            );
          }
          final imagePath = word['image_path'] as String?;
          final term = word['term'] as String? ?? '';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 3,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () => _openWord(word),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imagePath != null && imagePath.isNotEmpty)
                        Image.asset(
                          imagePath,
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imageFallback(context),
                        )
                      else
                        _imageFallback(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              term,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word['definition'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Divider(height: 28),
                            Row(
                              children: [
                                Text(
                                  'Word of the day',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Listen to word',
                                  icon: Icon(
                                    Icons.volume_up_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () => _speak(term),
                                ),
                                IconButton.filled(
                                  tooltip: 'Search words',
                                  icon: const Icon(Icons.search),
                                  onPressed: () => Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const SearchScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _imageFallback(BuildContext context) => Container(
    height: 190,
    width: double.infinity,
    color: Theme.of(context).colorScheme.primaryContainer,
    child: const Icon(Icons.menu_book_outlined, size: 72),
  );
}
