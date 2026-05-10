import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, String languageCode) async {
    await _tts.stop();
    
    // Set language first
    final String targetLang = languageCode == 'hi' ? 'hi-IN' : 'en-US';
    await _tts.setLanguage(targetLang);
    
    // Try to find a better voice for the language to avoid accent issues
    try {
      List<dynamic> voices = await _tts.getVoices;
      for (var voice in voices) {
        if (voice['locale'].toString().toLowerCase().contains(targetLang.toLowerCase())) {
          await _tts.setVoice(Map<String, String>.from(voice));
          break;
        }
      }
    } catch (e) {
      // Fallback to default engine behavior if getVoices fails
    }

    await _tts.setSpeechRate(0.45); // Slightly slower for better clarity
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
