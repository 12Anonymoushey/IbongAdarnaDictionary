import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../../services/app_feedback.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late Future<bool> _speakSetting;

  @override
  void initState() {
    super.initState();
    _speakSetting = DatabaseHelper.instance.getSpeakWordOfDaySetting();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: FutureBuilder<bool>(
        future: _speakSetting,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Could not load settings: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Speak word of the day'),
            subtitle: const Text('Read the daily word aloud when Home opens.'),
            value: snapshot.data!,
            onChanged: (value) async {
              try {
                await DatabaseHelper.instance.setSpeakWordOfDaySetting(value);
                if (mounted) {
                  setState(
                    () => _speakSetting = DatabaseHelper.instance
                        .getSpeakWordOfDaySetting(),
                  );
                  AppFeedback.show(
                    value
                        ? 'Automatic word-of-the-day speech is on.'
                        : 'Automatic word-of-the-day speech is off.',
                  );
                }
              } catch (error) {
                if (mounted) {
                  AppFeedback.show('Could not update setting: $error');
                }
              }
            },
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
