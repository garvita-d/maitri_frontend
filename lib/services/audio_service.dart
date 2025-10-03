import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  stt.SpeechToText? _speech;
  FlutterTts? _tts;
  bool _isListening = false;
  bool _isSpeaking = false;

  /// Start listening for voice input
  static Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (_instance._isListening) {
      debugPrint('Already listening');
      return false;
    }

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        onError?.call('Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _instance._speech ??= stt.SpeechToText();

      final available = await _instance._speech!.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          onError?.call(error.errorMsg);
          _instance._isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _instance._isListening = false;
          }
        },
      );

      if (!available) {
        onError?.call('Speech recognition not available');
        return false;
      }

      // Start listening
      await _instance._speech!.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _instance._isListening = false;
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: false,
        localeId: 'en_US',
        cancelOnError: true,
      );

      _instance._isListening = true;
      debugPrint('Audio service: Started listening');
      return true;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (!_instance._isListening) return;

    try {
      await _instance._speech?.stop();
      _instance._isListening = false;
      debugPrint('Audio service: Stopped listening');
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  /// Text-to-speech
  static Future<void> speak(
    String text, {
    String language = 'en-US',
    double rate = 0.5,
    double pitch = 1.0,
  }) async {
    if (_instance._isSpeaking) {
      await stop();
    }

    try {
      _instance._tts ??= FlutterTts();

      await _instance._tts!.setLanguage(language);
      await _instance._tts!.setSpeechRate(rate);
      await _instance._tts!.setPitch(pitch);
      await _instance._tts!.setVolume(1.0);

      _instance._tts!.setStartHandler(() {
        _instance._isSpeaking = true;
      });

      _instance._tts!.setCompletionHandler(() {
        _instance._isSpeaking = false;
      });

      _instance._tts!.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _instance._isSpeaking = false;
      });

      await _instance._tts!.speak(text);
    } catch (e) {
      debugPrint('Error in text-to-speech: $e');
      _instance._isSpeaking = false;
    }
  }

  /// Stop speaking
  static Future<void> stop() async {
    if (!_instance._isSpeaking) return;

    try {
      await _instance._tts?.stop();
      _instance._isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  static bool get isListening => _instance._isListening;
  static bool get isSpeaking => _instance._isSpeaking;
}
