import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// Plays themed sounds for Level 2 code blocks.
/// Music and crying are synthesised as WAV bytes (no asset files needed).
/// Animal sounds use TTS with pitch adjustment per animal.
class SoundService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  SoundService() {
    _tts.setVolume(1.0);
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.1);
  }

  void setLanguage(String langCode) => _tts.setLanguage(langCode);

  Future<void> dispose() async {
    await _player.dispose();
  }

  // Condition and structural blocks — no sound should play for these.
  static const _silent = {
    'start', 'end', 'repeat',
    'ifHappy', 'ifSad', 'ifMoon', 'elseIfSun',
    'ifStreak5', 'elseIfStreak2', 'elseBlock',
    'ifBig', 'ifHasTrunk', 'ifFluffy',
  };

  // ── Public entry point ───────────────────────────────────────────────────

  Future<void> playForBlock(String blockName, {bool isArabic = false}) async {
    if (_silent.contains(blockName)) return;

    switch (blockName) {
      case 'music':
      case 'happy':
        await _playWav(_WavGen.music());
        break;
      case 'cry':
        await _playWav(_WavGen.cry());
        break;
      case 'elephantSound':
        await _playAnimalUrl(
          'https://commons.wikimedia.org/wiki/Special:FilePath/Elephant_voice_-_trumpeting.ogg',
          fallbackText: isArabic ? 'فيل' : 'Elephant',
          pitch: 0.8, rate: 0.35,
        );
        break;
      case 'lionSound':
        await _playAnimalUrl(
          'https://commons.wikimedia.org/wiki/Special:FilePath/Lion_raring-sound1TamilNadu178.ogg',
          fallbackText: isArabic ? 'زئير' : 'Roarrr',
          pitch: 0.5, rate: 0.3,
        );
        break;
      case 'catSound':
        await _playAnimalUrl(
          'https://commons.wikimedia.org/wiki/Special:FilePath/Meow.ogg',
          fallbackText: isArabic ? 'مياو' : 'Meow',
          pitch: 1.6, rate: 0.45,
        );
        break;
      case 'dogSound':
        await _playAnimalUrl(
          'https://commons.wikimedia.org/wiki/Special:FilePath/Barking_of_a_dog.ogg',
          fallbackText: isArabic ? 'هاو هاو' : 'Woof woof',
          pitch: 1.1, rate: 0.5,
        );
        break;
      case 'thenNight':
        await _speak(isArabic ? 'تصبح على خير' : 'Good night!');
        break;
      case 'thenMorning':
        await _speak(isArabic ? 'صباح الخير' : 'Good morning!');
        break;
      case 'cheering':
        await _speak(isArabic ? 'هيا' : 'Yay!');
        break;
      case 'clap':
        await _speak(isArabic ? 'تصفيق' : 'Clap clap!');
        break;
      case 'encourage':
        await _speak(isArabic ? 'استمر' : 'Keep going!');
        break;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _playWav(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes));
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    await _tts.speak(text);
  }

  Future<void> _speakAnimal(String text,
      {required double pitch, required double rate}) async {
    await _tts.stop();
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.speak(text);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
  }

  Future<void> _playAnimalUrl(
    String url, {
    required String fallbackText,
    required double pitch,
    required double rate,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        await _player.stop();
        await _player.play(BytesSource(response.bodyBytes));
        await Future.delayed(const Duration(milliseconds: 1500));
        await _player.stop();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (_) {
      await _speakAnimal(fallbackText, pitch: pitch, rate: rate);
    }
  }
}

// ── WAV synthesiser ──────────────────────────────────────────────────────────

class _WavGen {
  static const _sr = 22050; // sample rate
  static const _vol = 0.6;

  /// Four-note ascending arpeggio: C5 – E5 – G5 – C6
  static Uint8List music() {
    const notes = [523.25, 659.25, 783.99, 1046.50];
    const noteMs = 180;
    final totalSamples = (_sr * noteMs * notes.length / 1000).round();
    final pcm = Int16List(totalSamples);

    for (int n = 0; n < notes.length; n++) {
      final freq = notes[n];
      final start = (_sr * noteMs * n / 1000).round();
      final len = (_sr * noteMs / 1000).round();
      for (int i = 0; i < len; i++) {
        final env = _env(i, len);
        final t = i / _sr;
        final sample = (math.sin(2 * math.pi * freq * t) * 32767 * _vol * env)
            .round()
            .clamp(-32768, 32767);
        if (start + i < totalSamples) pcm[start + i] = sample;
      }
    }
    return _wavHeader(pcm);
  }

  /// Soft descending sigh — single smooth tone, 400→250 Hz, no harsh harmonics.
  /// Sounds like a gentle "aaahh" falling in pitch, appropriate for children.
  static Uint8List cry() {
    const ms  = 900;
    final len = (_sr * ms / 1000).round();
    final pcm = Int16List(len);
    double phase = 0;

    for (int i = 0; i < len; i++) {
      final progress = i / len;

      // Smooth exponential descent: 400 Hz → 250 Hz
      final freq = 400.0 * math.pow(250.0 / 400.0, progress);

      phase += 2 * math.pi * freq / _sr;

      // Soft sine mix — no sawtooth, no noise, just gentle harmonics
      final s = math.sin(phase)     * 0.82 +
                math.sin(2 * phase) * 0.13 +
                math.sin(3 * phase) * 0.05;

      // Slow attack (20 %) and long release (35 %) for a breath-like feel
      final env = _env(i, len, fadeInRatio: 0.20, fadeOutRatio: 0.35);

      pcm[i] = (s * 32767 * _vol * env).round().clamp(-32768, 32767);
    }
    return _wavHeader(pcm);
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static double _env(int i, int total,
      {double fadeInRatio = 0.05, double fadeOutRatio = 0.2}) {
    final fadeIn = (total * fadeInRatio).round();
    final fadeOut = (total * fadeOutRatio).round();
    if (i < fadeIn) return i / fadeIn;
    if (i > total - fadeOut) return (total - i) / fadeOut;
    return 1.0;
  }

  static Uint8List _wavHeader(Int16List pcm) {
    final dataBytes = pcm.length * 2;
    final bd = ByteData(44 + dataBytes);

    void str(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bd.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    bd.setUint32(4, 36 + dataBytes, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little); // PCM
    bd.setUint16(22, 1, Endian.little); // mono
    bd.setUint32(24, _sr, Endian.little);
    bd.setUint32(28, _sr * 2, Endian.little); // byte rate
    bd.setUint16(32, 2, Endian.little); // block align
    bd.setUint16(34, 16, Endian.little); // bits per sample
    str(36, 'data');
    bd.setUint32(40, dataBytes, Endian.little);

    final bytes = bd.buffer.asUint8List();
    final view = ByteData.view(pcm.buffer);
    for (int i = 0; i < pcm.length; i++) {
      bytes[44 + i * 2] = view.getUint8(i * 2);
      bytes[44 + i * 2 + 1] = view.getUint8(i * 2 + 1);
    }
    return bytes;
  }
}
