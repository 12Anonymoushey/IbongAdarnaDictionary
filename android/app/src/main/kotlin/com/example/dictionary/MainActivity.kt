package com.example.dictionary

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private data class PendingSpeech(
        val text: String,
        val result: MethodChannel.Result,
    )

    private val pendingSpeech = mutableListOf<PendingSpeech>()
    private var textToSpeech: TextToSpeech? = null
    private var speechReady = false
    private var speechInitializationFailed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dictionary/speech")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text")?.trim()
                        if (text.isNullOrEmpty()) {
                            result.error("invalid_text", "Speech text must not be empty.", null)
                        } else if (speechInitializationFailed) {
                            result.error(
                                "tts_initialization_failed",
                                "Could not initialize the Android text-to-speech engine.",
                                null,
                            )
                        } else if (speechReady) {
                            speak(text, result)
                        } else {
                            pendingSpeech.add(PendingSpeech(text, result))
                        }
                    }
                    "stop" -> {
                        textToSpeech?.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        textToSpeech = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                speechReady = true
                pendingSpeech.toList().forEach { pending ->
                    speak(pending.text, pending.result)
                }
            } else {
                speechInitializationFailed = true
                pendingSpeech.toList().forEach { pending ->
                    pending.result.error(
                        "tts_initialization_failed",
                        "Could not initialize the Android text-to-speech engine.",
                        null,
                    )
                }
            }
            pendingSpeech.clear()
        }
    }

    private fun speak(text: String, result: MethodChannel.Result) {
        val status = textToSpeech?.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            UUID.randomUUID().toString(),
        )
        if (status == TextToSpeech.SUCCESS) {
            result.success(true)
        } else {
            result.error(
                "tts_speak_failed",
                "The Android text-to-speech engine could not speak the word.",
                null,
            )
        }
    }

    override fun onDestroy() {
        pendingSpeech.forEach { pending ->
            pending.result.error("activity_destroyed", "Speech activity was closed.", null)
        }
        pendingSpeech.clear()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        speechReady = false
        speechInitializationFailed = false
        super.onDestroy()
    }
}
