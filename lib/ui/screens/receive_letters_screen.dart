import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../logic/morse_engine.dart';
import '../../logic/settings_provider.dart';
import '../../logic/feedback_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

/// Tab 1: Receive Letters - The Quiz with Levels
/// App plays morse code, user must identify the correct letter
class ReceiveLettersScreen extends ConsumerStatefulWidget {
  const ReceiveLettersScreen({super.key});

  @override
  ConsumerState<ReceiveLettersScreen> createState() =>
      _ReceiveLettersScreenState();
}

class _ReceiveLettersScreenState extends ConsumerState<ReceiveLettersScreen> {
  final _engine = MorseEngine.instance;
  final _feedback = FeedbackService.instance;

  String _currentLetter = '';
  List<String> _options = [];
  bool _isPlaying = false;
  bool _showResult = false;
  bool _isCorrect = false;
  int _streak = 0;
  int _selectedIndex = -1;
  int _currentLevel = 1;
  bool _showLevelSelect = false;
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _feedback.initialize();
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    final levelLetters = _engine.getLettersForLevel(_currentLevel);
    setState(() {
      _currentLetter = _engine.getRandomLetterFromLevel(_currentLevel);
      // Get options from current level, ensure we have at least 4 (or all if less)
      final optionCount = levelLetters.length >= 4 ? 4 : levelLetters.length;
      _options = _engine.getRandomLettersFromLevel(
        optionCount,
        _currentLevel,
        mustInclude: _currentLetter,
      );
      _showResult = false;
      _isCorrect = false;
    });
  }

  void _selectLevel(int level) {
    setState(() {
      _currentLevel = level;
      _showLevelSelect = false;
      _streak = 0;
    });
    _generateNewQuestion();
  }

  Future<void> _playMorse() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);

    final settings = ref.read(settingsProvider);
    final timing = _engine.getTiming(settings.wpm);
    final morse = _engine.toMorse(_currentLetter) ?? '';

    // Play each symbol with haptics and flash
    for (int i = 0; i < morse.length; i++) {
      final symbol = morse[i];
      final duration = symbol == '.' ? timing.dot : timing.dash;

      // Flash on (if enabled in settings)
      if (settings.feedback.flash) {
        setState(() => _flashOpacity = 0.8);
      }

      // Haptic/Sound feedback
      // Haptic/Sound feedback
      if (symbol == '.') {
        _feedback.playDot(
          haptics: true,
          sound: settings.feedback.sound,
          durationMs: duration,
        );
      } else {
        _feedback.playDash(
          haptics: true,
          sound: settings.feedback.sound,
          durationMs: duration,
        );
      }

      // Enforce duration wait regardless of haptics/sound timing
      await Future.delayed(Duration(milliseconds: duration));

      // Flash off
      if (settings.feedback.flash) {
        setState(() => _flashOpacity = 0.0);
      }

      // Gap between symbols
      await Future.delayed(Duration(milliseconds: timing.symbolGap));
    }

    setState(() => _isPlaying = false);
  }

  void _checkAnswer(String answer) async {
    final settings = ref.read(settingsProvider);
    final correct = answer == _currentLetter;

    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) {
        _streak++;
        // Auto-advance level after 5 correct in a row
        if (_streak >= 5 && _currentLevel < _engine.totalLevels) {
          _currentLevel++;
          _streak = 0;
        }
      } else {
        _streak = 0;
      }
    });

    if (correct) {
      await _feedback.playSuccess(
        haptics: true,
        sound: settings.feedback.sound,
      );
    } else {
      await _feedback.playError(haptics: true, sound: settings.feedback.sound);
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    _generateNewQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      body: Stack(
        children: [
          // Background effects
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top content
                        Column(
                          children: [
                            const Gap(16),

                            // Level + Streak row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  // Level selector button
                                  GlassButton(
                                    onTap: () =>
                                        setState(() => _showLevelSelect = true),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.signal_cellular_alt,
                                          size: 18,
                                          color: AppTheme.neonCyan,
                                        ),
                                        const Gap(8),
                                        Text(
                                          'LEVEL $_currentLevel',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.neonCyan,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Streak
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const Gap(4),
                                        Text(
                                          '$_streak',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Gap(40),

                            // Play button with Snake Border
                            SnakeBorder(
                              show: _showResult && _isCorrect,
                              borderRadius:
                                  30, // Matches GlassContainer radius approx
                              padding: const EdgeInsets.all(4),
                              child:
                                  GestureDetector(
                                        onTap: _isPlaying ? null : _playMorse,
                                        child: GlassContainer(
                                          width: 140,
                                          height: 140,
                                          padding: const EdgeInsets.all(20),
                                          borderRadius: 24,
                                          tintColor: _isPlaying
                                              ? AppTheme.neonCyan.withValues(
                                                  alpha: 0.2,
                                                )
                                              : null,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _isPlaying
                                                    ? Icons.volume_up
                                                    : Icons.play_arrow_rounded,
                                                size: 56,
                                                color: _isPlaying
                                                    ? AppTheme.neonCyan
                                                    : (isDark
                                                          ? Colors.white
                                                          : Colors.black87),
                                              ),
                                              const Gap(4),
                                              Text(
                                                _isPlaying
                                                    ? 'PLAYING...'
                                                    : 'PLAY',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                                  color: _isPlaying
                                                      ? AppTheme.neonCyan
                                                      : (isDark
                                                            ? Colors.white70
                                                            : Colors.black54),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .animate(target: _isPlaying ? 1 : 0)
                                      .shimmer(duration: 1000.ms)
                                      .animate()
                                      .fadeIn()
                                      .scale(begin: const Offset(0.8, 0.8)),
                            ),

                            const Gap(32),

                            // Result feedback area
                            if (_showResult)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isCorrect
                                      ? AppTheme.successGreen.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppTheme.errorRed.withValues(
                                          alpha: 0.2,
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isCorrect
                                        ? AppTheme.successGreen
                                        : AppTheme.errorRed,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  _isCorrect
                                      ? 'CORRECT!'
                                      : 'IT WAS "$_currentLetter"',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: _isCorrect
                                        ? AppTheme.successGreen
                                        : AppTheme.errorRed,
                                  ),
                                ),
                              ).animate().fadeIn().scale(
                                begin: const Offset(0.8, 0.8),
                              )
                            else
                              const SizedBox(height: 54), // Placeholder height
                          ],
                        ),

                        // Bottom content (Options)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildOptionButton(0)),
                                      const Gap(16),
                                      Expanded(child: _buildOptionButton(1)),
                                    ],
                                  ),
                                  const Gap(16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildOptionButton(2)),
                                      const Gap(16),
                                      Expanded(child: _buildOptionButton(3)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Extra padding for bottom navbar to prevent overlap
                            const Gap(140),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Level Select Modal
          if (_showLevelSelect) _buildLevelSelectModal(isDark),

          // Flash overlay for morse signals
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: _flashOpacity,
                child: Container(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index) {
    if (index >= _options.length) return const SizedBox.shrink();

    final option = _options[index];
    final isSelected = _selectedIndex == index;
    final showColor =
        _showResult &&
        (option == _currentLetter || (isSelected && !_isCorrect));
    final isRight = option == _currentLetter;

    return GlassButton(
      onTap: _showResult
          ? null
          : () {
              setState(() => _selectedIndex = index);
              _checkAnswer(_options[index]);
            },
      height: 80,
      tintColor: showColor
          ? (isRight
                ? AppTheme.successGreen.withValues(alpha: 0.3)
                : AppTheme.errorRed.withValues(alpha: 0.3))
          : null,
      child: Center(
        child: Text(
          option,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: showColor
                ? (isRight ? AppTheme.successGreen : AppTheme.errorRed)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectModal(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _showLevelSelect = false),
      child: Container(
        color: Colors.black87,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap through
            child: GlassContainer(
              width: 320,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SELECT LEVEL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Gap(24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _engine.totalLevels,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder: (context, index) {
                        final level = index + 1;
                        final isCurrentLevel = level == _currentLevel;

                        return GestureDetector(
                          onTap: () => _selectLevel(level),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCurrentLevel
                                  ? AppTheme.neonCyan.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentLevel
                                    ? AppTheme.neonCyan
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrentLevel
                                        ? AppTheme.neonCyan
                                        : Colors.white12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$level',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentLevel
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Text(
                                    'Level $level',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isCurrentLevel)
                                  Icon(
                                        Icons.check_circle,
                                        color: AppTheme.neonCyan,
                                        size: 20,
                                      )
                                      .animate()
                                      .fadeIn(delay: 200.ms)
                                      .slideY(begin: 0.2),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(24),
                  GlassButton(
                    onTap: () => setState(() => _showLevelSelect = false),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'BACK TO PRACTICE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
