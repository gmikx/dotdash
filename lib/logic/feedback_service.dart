import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'morse_engine.dart';

/// Service class to handle feedback (haptics, sound, flash)
class FeedbackService {
  FeedbackService._();
  static final instance = FeedbackService._();

  final AudioPlayer _dotPlayer = AudioPlayer();
  final AudioPlayer _dashPlayer = AudioPlayer();
  bool _hasVibrator = false;
  bool _initialized = false;
  String? _tempPath;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (e) {
      // print('Error checking vibration support: $e');
      _hasVibrator = false;
    }
    // Set to low latency mode for better responsiveness
    await _dotPlayer.setReleaseMode(ReleaseMode.stop);
    await _dashPlayer.setReleaseMode(ReleaseMode.stop);

    // Prepare audio files - filenames encode params so stale files are auto-ignored
    final tempDir = await getTemporaryDirectory();
    _tempPath = tempDir.path;
    final dotFile = 'dot_600hz_80ms.wav';
    final dashFile = 'dash_600hz_240ms.wav';
    await _cacheSound(dotFile, 80, frequency: 600);
    await _cacheSound(dashFile, 240, frequency: 600);

    // Initial setup for players
    if (_tempPath != null) {
      await _dotPlayer.setSource(DeviceFileSource('$_tempPath/$dotFile'));
      await _dashPlayer.setSource(DeviceFileSource('$_tempPath/$dashFile'));
    }

    _initialized = true;
  }

  Future<void> _cacheSound(
    String filename,
    int durationMs, {
    int frequency = 600,
  }) async {
    if (_tempPath == null) return;
    final file = File('$_tempPath/$filename');
    // Filename encodes params — if file exists with this name, params haven't changed
    if (!await file.exists()) {
      final bytes = _generateWavBytes(durationMs, frequency: frequency);
      await file.writeAsBytes(bytes);
    }
  }

  /// Generate a simple sine wave WAV file in memory
  Uint8List _generateWavBytes(int durationMs, {int frequency = 600}) {
    final int sampleRate = 44100;
    final int numSamples = (durationMs * sampleRate) ~/ 1000;
    final int numChannels = 1;
    final int bytesPerSample = 2; // 16-bit
    final int byteRate = sampleRate * numChannels * bytesPerSample;
    final int blockAlign = numChannels * bytesPerSample;
    final int dataSize = numSamples * blockAlign;
    final int fileSize = 36 + dataSize;

    final head = ByteData(44);

    // RIFF chunk
    _writeString(head, 0, 'RIFF');
    head.setUint32(4, fileSize - 8, Endian.little);
    _writeString(head, 8, 'WAVE');

    // fmt chunk
    _writeString(head, 12, 'fmt ');
    head.setUint32(16, 16, Endian.little); // Subchunk1Size
    head.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    head.setUint16(22, numChannels, Endian.little);
    head.setUint32(24, sampleRate, Endian.little);
    head.setUint32(28, byteRate, Endian.little);
    head.setUint16(32, blockAlign, Endian.little);
    head.setUint16(34, 8 * bytesPerSample, Endian.little); // BitsPerSample

    // data chunk
    _writeString(head, 36, 'data');
    head.setUint32(40, dataSize, Endian.little);

    final Uint8List wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, head.buffer.asUint8List());

    final ByteData data = ByteData.view(wavBytes.buffer);
    const double amplitude = 0.5; // 50% volume

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double sample = amplitude * math.sin(2 * math.pi * frequency * t);
      // Convert to 16-bit signed integer
      data.setInt16(44 + i * 2, (sample * 32767).toInt(), Endian.little);
    }

    return wavBytes;
  }

  void _writeString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  Future<void> _playSound(AudioPlayer player) async {
    if (_tempPath != null) {
      await player.stop();
      await player.resume();
    }
  }

  /// Play a dot vibration/sound pattern
  Future<void> playDot({
    bool haptics = true,
    bool sound = true,
    int durationMs = 80,
  }) async {
    // print('playDot: sound=$sound, haptics=$haptics');
    if (sound) {
      await _playSound(_dotPlayer);
    }

    if (haptics) {
      if (_hasVibrator) {
        // Start vibration but don't await strictly for timing if it's unreliable
        Vibration.vibrate(duration: durationMs);
      }
      // Use selectionClick for a distinct "tap" feeling
      await HapticFeedback.selectionClick();
    }
    // Always wait for the duration to ensure rhythm
    await Future.delayed(Duration(milliseconds: durationMs));
  }

  /// Play a dash vibration/sound pattern
  Future<void> playDash({
    bool haptics = true,
    bool sound = true,
    int durationMs = 240,
  }) async {
    // print('playDash: sound=$sound, haptics=$haptics');
    if (sound) {
      await _playSound(_dashPlayer);
    }

    if (haptics) {
      if (_hasVibrator) {
        Vibration.vibrate(duration: durationMs);
      }
      // Use heavyImpact for a stronger "long" feeling (best approximation)
      await HapticFeedback.heavyImpact();
    }
    await Future.delayed(Duration(milliseconds: durationMs));
  }

  /// Play error feedback
  Future<void> playError({bool haptics = true, bool sound = true}) async {
    // Trigger haptics first to ensure it fires before any potential audio blocking of the thread
    if (haptics) {
      if (_hasVibrator) {
        await Vibration.vibrate(
          pattern: [0, 50, 50, 50, 50, 50],
          amplitude: 128,
        );
      }
      await HapticFeedback.heavyImpact();
    }

    // if (sound) {
    //   await _playSound(_errorPlayer);
    // }
  }

  /// Play success feedback
  Future<void> playSuccess({bool haptics = true, bool sound = true}) async {
    // User requested to remove the high beep for success
    // if (sound) {
    //   await _playSound('success.wav');
    // }

    if (haptics) {
      if (_hasVibrator) {
        await Vibration.vibrate(pattern: [0, 100, 100, 200], amplitude: 200);
      }
      await HapticFeedback.mediumImpact();
    }
  }

  /// Play a complete morse code sequence for a character
  Future<void> playMorseCharacter(
    String char, {
    required bool haptics,
    required bool sound,
    required MorseTiming timing,
  }) async {
    final morse = MorseEngine.instance.toMorse(char);
    if (morse == null) return;

    for (int i = 0; i < morse.length; i++) {
      final symbol = morse[i];
      if (symbol == '.') {
        await playDot(haptics: haptics, sound: sound, durationMs: timing.dot);
        await Future.delayed(Duration(milliseconds: timing.symbolGap));
      } else if (symbol == '-') {
        await playDash(haptics: haptics, sound: sound, durationMs: timing.dash);
        await Future.delayed(Duration(milliseconds: timing.symbolGap));
      }
    }
  }

  /// Play a complete morse code sequence for a word/sentence
  Future<void> playMorseSequence(
    String text, {
    required bool haptics,
    required bool sound,
    required MorseTiming timing,
    void Function(int charIndex, String char)? onCharacter,
    bool Function()? shouldStop,
  }) async {
    final cleanText = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'), '');

    for (int i = 0; i < cleanText.length; i++) {
      if (shouldStop?.call() == true) break;

      final char = cleanText[i];
      onCharacter?.call(i, char);

      if (char == ' ') {
        await Future.delayed(Duration(milliseconds: timing.wordGap));
      } else {
        await playMorseCharacter(
          char,
          haptics: haptics,
          sound: sound,
          timing: timing,
        );
        await Future.delayed(Duration(milliseconds: timing.letterGap));
      }
    }
  }

  /// Light haptic tap feedback
  Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic tap feedback
  Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }
}
