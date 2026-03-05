import 'dart:math';

/// The core Morse Code engine - handles encoding/decoding and word generation
class MorseEngine {
  MorseEngine._();
  static final instance = MorseEngine._();

  /// International Morse Code dictionary for A-Z and 0-9
  static const Map<String, String> _charToMorse = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
  };

  /// Reverse mapping for decoding morse to characters
  static final Map<String, String> _morseToChar = {
    for (final entry in _charToMorse.entries) entry.value: entry.key,
  };

  /// 50 common words for sentence generation
  static const List<String> _wordList = [
    'HELLO',
    'WORLD',
    'MORSE',
    'CODE',
    'RADIO',
    'SIGNAL',
    'LOVE',
    'PEACE',
    'HELP',
    'STOP',
    'START',
    'END',
    'OKAY',
    'YES',
    'NO',
    'PLEASE',
    'THANKS',
    'SORRY',
    'GOOD',
    'BAD',
    'DAY',
    'NIGHT',
    'SUN',
    'MOON',
    'STAR',
    'SHIP',
    'BOAT',
    'SEA',
    'SKY',
    'LAND',
    'HOME',
    'WORK',
    'PLAY',
    'RUN',
    'WALK',
    'FAST',
    'SLOW',
    'BIG',
    'SMALL',
    'HOT',
    'COLD',
    'NEW',
    'OLD',
    'FIRE',
    'WATER',
    'EARTH',
    'WIND',
    'TIME',
    'LIFE',
    'HOPE',
  ];

  /// Get all available characters
  List<String> get allCharacters => _charToMorse.keys.toList();

  /// Get all available letters (A-Z only)
  List<String> get allLetters =>
      _charToMorse.keys.where((c) => RegExp(r'[A-Z]').hasMatch(c)).toList();

  /// Get letters grouped by morse code length for progressive learning
  /// Level 1: 1-char (E, T)
  /// Level 2: 2-char same type (I, M, A, N)
  /// Level 3: 2-char mixed (all 2-char)
  /// Level 4: 3-char dots-heavy (S, U, R, W)
  /// Level 5: 3-char dash-heavy (O, G, K, D)
  /// Level 6: 3-char all mixed
  /// Level 7: 4-char first half (H, V, F, L, P, J, B, X, C, Y, Z, Q)
  /// Level 8: All letters
  List<String> getLettersForLevel(int level) {
    switch (level) {
      case 1:
        // 1-character morse codes
        return ['E', 'T'];
      case 2:
        // 2-character same type (dots only or dashes only)
        return ['I', 'M']; // .. and --
      case 3:
        // 2-character mixed
        return ['A', 'N', 'I', 'M']; // .-, -., .., --
      case 4:
        // 3-character dots-heavy
        return ['S', 'U', 'R', 'W']; // ..., ..-, .-.、.--
      case 5:
        // 3-character dash-heavy + previous
        return ['S', 'U', 'R', 'W', 'D', 'K', 'G', 'O'];
      case 6:
        // All 1-3 character morse codes
        return [
          'E',
          'T',
          'I',
          'M',
          'A',
          'N',
          'S',
          'U',
          'R',
          'W',
          'D',
          'K',
          'G',
          'O',
        ];
      case 7:
        // 4-character codes first batch
        return [
          'E',
          'T',
          'I',
          'M',
          'A',
          'N',
          'S',
          'U',
          'R',
          'W',
          'D',
          'K',
          'G',
          'O',
          'H',
          'V',
          'F',
          'L',
          'P',
          'J',
        ];
      case 8:
        // All letters
        return allLetters;
      default:
        return allLetters;
    }
  }

  /// Get the name/description for a level
  String getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Single Dot & Dash';
      case 2:
        return 'Double Same';
      case 3:
        return 'Double Mixed';
      case 4:
        return 'Triple Dots';
      case 5:
        return 'Triple Mixed';
      case 6:
        return 'All Short Codes';
      case 7:
        return 'Adding Quads';
      case 8:
        return 'All Letters';
      default:
        return 'All Letters';
    }
  }

  /// Get total number of levels
  int get totalLevels => 8;

  /// Get a random letter from a specific level
  String getRandomLetterFromLevel(int level) {
    final random = Random();
    final letters = getLettersForLevel(level);
    return letters[random.nextInt(letters.length)];
  }

  /// Get N random letters from a specific level, ensuring no duplicates
  List<String> getRandomLettersFromLevel(
    int count,
    int level, {
    String? mustInclude,
  }) {
    final random = Random();
    final levelLetters = getLettersForLevel(level);
    final result = <String>{};

    if (mustInclude != null) {
      result.add(mustInclude.toUpperCase());
    }

    // If we need more letters than available in level, just use what we have
    final maxCount = count.clamp(1, levelLetters.length);

    while (result.length < maxCount) {
      result.add(levelLetters[random.nextInt(levelLetters.length)]);
    }

    final list = result.toList()..shuffle(random);
    return list;
  }

  /// Convert a single character to Morse code
  String? toMorse(String char) {
    return _charToMorse[char.toUpperCase()];
  }

  /// Convert Morse code to a single character
  String? fromMorse(String code) {
    return _morseToChar[code];
  }

  /// Convert entire text to Morse code
  /// Letters are separated by ' ', words by ' / '
  String textToMorse(String text) {
    final buffer = StringBuffer();
    final words = text.toUpperCase().split(' ');

    for (int w = 0; w < words.length; w++) {
      if (w > 0) buffer.write(' / ');
      final word = words[w];
      for (int i = 0; i < word.length; i++) {
        if (i > 0) buffer.write(' ');
        final morse = toMorse(word[i]);
        if (morse != null) {
          buffer.write(morse);
        }
      }
    }
    return buffer.toString();
  }

  /// Generate a sentence of 3 random words
  String generateSentence() {
    final random = Random();
    final words = <String>[];
    final availableWords = List<String>.from(_wordList);

    for (int i = 0; i < 2 && availableWords.isNotEmpty; i++) {
      final index = random.nextInt(availableWords.length);
      words.add(availableWords.removeAt(index));
    }

    return words.join(' ');
  }

  /// Get a random letter (A-Z)
  String getRandomLetter() {
    final random = Random();
    return allLetters[random.nextInt(allLetters.length)];
  }

  /// Get N random letters, ensuring no duplicates
  List<String> getRandomLetters(int count, {String? mustInclude}) {
    final random = Random();
    final result = <String>{};

    if (mustInclude != null) {
      result.add(mustInclude.toUpperCase());
    }

    while (result.length < count) {
      result.add(allLetters[random.nextInt(allLetters.length)]);
    }

    final list = result.toList()..shuffle(random);
    return list;
  }

  /// Parse morse input and validate against expected morse code
  /// Returns true if the input matches the expected pattern
  bool validateMorseInput(String input, String expectedMorse) {
    return input == expectedMorse;
  }

  /// Get Morse code timing in milliseconds based on WPM
  /// Using standard "PARIS" calibration
  MorseTiming getTiming(double wpm) {
    // At PARIS standard, one word = 50 units
    // WPM = words per minute
    final unitMs = (60 * 1000) / (wpm * 50);
    return MorseTiming(
      dot: unitMs.round(),
      dash: (unitMs * 3).round(),
      symbolGap: unitMs.round(),
      letterGap: (unitMs * 6).round(),
      wordGap: (unitMs * 10).round(),
    );
  }
}

/// Timing values for Morse code playback in milliseconds
class MorseTiming {
  final int dot;
  final int dash;
  final int symbolGap;
  final int letterGap;
  final int wordGap;

  const MorseTiming({
    required this.dot,
    required this.dash,
    required this.symbolGap,
    required this.letterGap,
    required this.wordGap,
  });
}
