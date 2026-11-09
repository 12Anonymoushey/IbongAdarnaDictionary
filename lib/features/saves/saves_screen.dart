import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../growth/analytics_service.dart';
import '../search/word_card.dart';
import '../search/word_detail_screen.dart';

class SavesScreen extends StatefulWidget {
  const SavesScreen({super.key});

  @override
  State<SavesScreen> createState() => _SavesScreenState();
}

class _SavesScreenState extends State<SavesScreen> {
  late Future<List<Map<String, Object?>>> _savedWords;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _savedWords = DatabaseHelper.instance.getSavedWords();
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
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Words'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh saved words',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_reload),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _savedWords,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load saved words: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = snapshot.data!;
          if (words.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Words you bookmark will appear here.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: words.length,
            itemBuilder: (context, index) => WordCard(
              word: words[index],
              onTap: () => _openWord(words[index]),
            ),
          );
        },
      ),
    );
  }
}
