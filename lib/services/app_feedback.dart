import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    ScaffoldMessengerState? messenger;
    try {
      messenger = scaffoldMessengerKey.currentState;
    } on FlutterError {
      return;
    }
    if (messenger == null || message.trim().isEmpty) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showBadges(Iterable<String> titles) {
    for (final title in titles) {
      show('Badge earned: $title.');
    }
  }
}
