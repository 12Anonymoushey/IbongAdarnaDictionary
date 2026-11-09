import 'dart:io';

import 'package:flutter/services.dart';

class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();
  static const MethodChannel _channel = MethodChannel('dictionary/speech');

  Future<void> speak(String text) async {
    if (!Platform.isAndroid) return;
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    try {
      final accepted = await _channel.invokeMethod<bool>('speak', {
        'text': trimmedText,
      });
      if (accepted != true) {
        throw const SpeechException(
          'The text-to-speech engine did not accept the word.',
        );
      }
    } on PlatformException catch (error) {
      throw SpeechException(
        error.message ??
            'Text-to-speech is unavailable. Check your device speech settings.',
      );
    } on MissingPluginException {
      throw const SpeechException(
        'Text-to-speech is unavailable on this device.',
      );
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      throw SpeechException(error.message ?? 'Could not stop text-to-speech.');
    } on MissingPluginException {
      throw const SpeechException(
        'Text-to-speech is unavailable on this device.',
      );
    }
  }
}

class SpeechException implements Exception {
  const SpeechException(this.message);

  final String message;

  @override
  String toString() => message;
}
