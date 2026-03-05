import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Difficulty level enum
enum Difficulty {
  easy, // 2 buttons (dot/dash)
  hard, // 1 button (tap pad)
}

/// Feedback options for the app
class FeedbackSettings {
  final bool sound;
  final bool haptics;
  final bool flash;
  final bool screenText;

  const FeedbackSettings({
    this.sound = true,
    this.haptics = true,
    this.flash = false,
    this.screenText = true,
  });

  FeedbackSettings copyWith({
    bool? sound,
    bool? haptics,
    bool? flash,
    bool? screenText,
  }) {
    return FeedbackSettings(
      sound: sound ?? this.sound,
      haptics: haptics ?? this.haptics,
      flash: flash ?? this.flash,
      screenText: screenText ?? this.screenText,
    );
  }

  Map<String, bool> toJson() => {
    'sound': sound,
    'haptics': haptics,
    'flash': flash,
    'screenText': screenText,
  };

  factory FeedbackSettings.fromJson(Map<String, dynamic> json) {
    return FeedbackSettings(
      sound: json['sound'] as bool? ?? true,
      haptics: json['haptics'] as bool? ?? true,
      flash: json['flash'] as bool? ?? false,
      screenText: json['screenText'] as bool? ?? true,
    );
  }
}

/// Complete app settings state
class AppSettings {
  final Difficulty difficulty;
  final double wpm;
  final FeedbackSettings feedback;
  final bool isDarkMode;

  const AppSettings({
    this.difficulty = Difficulty.easy,
    this.wpm = 15.0,
    this.feedback = const FeedbackSettings(),
    this.isDarkMode = true,
  });

  AppSettings copyWith({
    Difficulty? difficulty,
    double? wpm,
    FeedbackSettings? feedback,
    bool? isDarkMode,
  }) {
    return AppSettings(
      difficulty: difficulty ?? this.difficulty,
      wpm: wpm ?? this.wpm,
      feedback: feedback ?? this.feedback,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// Notifier to manage settings with persistence
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  static const _difficultyKey = 'difficulty';
  static const _wpmKey = 'wpm';
  static const _soundKey = 'feedback_sound';
  static const _hapticsKey = 'feedback_haptics';
  static const _flashKey = 'feedback_flash';
  static const _screenTextKey = 'feedback_screenText';
  static const _darkModeKey = 'darkMode';

  void _loadSettings() {
    final difficultyIndex = _prefs.getInt(_difficultyKey) ?? 0;
    final wpm = _prefs.getDouble(_wpmKey) ?? 15.0;
    final sound = _prefs.getBool(_soundKey) ?? true;
    final haptics = _prefs.getBool(_hapticsKey) ?? true;
    final flash = _prefs.getBool(_flashKey) ?? false;
    final screenText = _prefs.getBool(_screenTextKey) ?? true;
    final isDarkMode = _prefs.getBool(_darkModeKey) ?? true;

    state = AppSettings(
      difficulty: Difficulty.values[difficultyIndex.clamp(0, 1)],
      wpm: wpm.clamp(5.0, 30.0),
      feedback: FeedbackSettings(
        sound: sound,
        haptics: haptics,
        flash: flash,
        screenText: screenText,
      ),
      isDarkMode: isDarkMode,
    );
  }

  Future<void> setDifficulty(Difficulty difficulty) async {
    state = state.copyWith(difficulty: difficulty);
    await _prefs.setInt(_difficultyKey, difficulty.index);
  }

  Future<void> setWpm(double wpm) async {
    final clampedWpm = wpm.clamp(5.0, 30.0);
    state = state.copyWith(wpm: clampedWpm);
    await _prefs.setDouble(_wpmKey, clampedWpm);
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(feedback: state.feedback.copyWith(sound: value));
    await _prefs.setBool(_soundKey, value);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(feedback: state.feedback.copyWith(haptics: value));
    await _prefs.setBool(_hapticsKey, value);
  }

  Future<void> setFlash(bool value) async {
    state = state.copyWith(feedback: state.feedback.copyWith(flash: value));
    await _prefs.setBool(_flashKey, value);
  }

  Future<void> setScreenText(bool value) async {
    state = state.copyWith(
      feedback: state.feedback.copyWith(screenText: value),
    );
    await _prefs.setBool(_screenTextKey, value);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    await _prefs.setBool(_darkModeKey, value);
  }

  Future<void> toggleDifficulty() async {
    final newDifficulty = state.difficulty == Difficulty.easy
        ? Difficulty.hard
        : Difficulty.easy;
    await setDifficulty(newDifficulty);
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup');
});

/// Main settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

/// Convenience providers for specific settings
final difficultyProvider = Provider<Difficulty>((ref) {
  return ref.watch(settingsProvider).difficulty;
});

final wpmProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).wpm;
});

final feedbackProvider = Provider<FeedbackSettings>((ref) {
  return ref.watch(settingsProvider).feedback;
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).isDarkMode;
});
