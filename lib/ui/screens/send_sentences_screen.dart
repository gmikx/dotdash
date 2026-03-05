import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../logic/morse_engine.dart';
import '../../logic/settings_provider.dart';
import '../../logic/feedback_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

/// Tab 4: Send Sentences
/// Shows a full sentence, user sends each letter via morse
class SendSentencesScreen extends ConsumerStatefulWidget {
  const SendSentencesScreen({super.key});

  @override
  ConsumerState<SendSentencesScreen> createState() =>
      _SendSentencesScreenState();
}

class _SendSentencesScreenState extends ConsumerState<SendSentencesScreen> {
  final _engine = MorseEngine.instance;
  final _feedback = FeedbackService.instance;

  String _targetSentence = '';
  int _currentIndex = 0;
  String _currentMorse = '';
  String _userInput = '';

  bool _showHint = true;
  bool _isComplete = false;
  bool _busy = false; // locks input during feedback playback

  @override
  void initState() {
    super.initState();
    _feedback.initialize();
    _generateNewSentence();
  }

  void _generateNewSentence() {
    final sentence = _engine.generateSentence();
    setState(() {
      _targetSentence = sentence;
      _currentIndex = 0;
      _isComplete = false;
      _updateCurrentMorse();
    });
  }

  void _updateCurrentMorse() {
    if (_currentIndex < _targetSentence.length) {
      final char = _targetSentence[_currentIndex];
      if (char == ' ') {
        // Skip spaces automatically
        _currentMorse = '';
        _advanceToNextChar();
      } else {
        _currentMorse = _engine.toMorse(char) ?? '';
        _userInput = '';
      }
    }
  }

  void _advanceToNextChar() {
    if (_currentIndex + 1 >= _targetSentence.length) {
      // Sentence complete
      setState(() {
        _isComplete = true;
        _currentIndex = _targetSentence.length;
      });
      _feedback.playSuccess(
        haptics: ref.read(settingsProvider).feedback.haptics,
        sound: ref.read(settingsProvider).feedback.sound,
      );
      // Auto-advance to next sentence after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isComplete) {
          _generateNewSentence();
        }
      });
    } else {
      setState(() {
        _currentIndex++;
        _updateCurrentMorse();
      });
    }
  }

  Future<void> _addSymbol(bool isDash) async {
    if (_isComplete || _busy) return;

    final settings = ref.read(settingsProvider);
    final timing = _engine.getTiming(settings.wpm);

    // Feedback for tap
    if (settings.feedback.haptics || settings.feedback.sound) {
      if (isDash) {
        _feedback.playDash(
          haptics: settings.feedback.haptics,
          sound: settings.feedback.sound,
          durationMs: timing.dash,
        );
      } else {
        _feedback.playDot(
          haptics: settings.feedback.haptics,
          sound: settings.feedback.sound,
          durationMs: timing.dot,
        );
      }
    }

    final symbol = isDash ? '-' : '.';
    final newInput = _userInput + symbol;

    if (_currentMorse.startsWith(newInput)) {
      setState(() {
        _userInput = newInput;
      });

      // Check if letter complete
      if (newInput == _currentMorse) {
        await Future.delayed(const Duration(milliseconds: 200));
        _advanceToNextChar();
      }
    } else {
      await _handleError();
    }
  }

  Future<void> _handleError() async {
    _busy = true;
    final settings = ref.read(settingsProvider);

    if (settings.feedback.haptics || settings.feedback.sound) {
      await _feedback.playError(
        haptics: settings.feedback.haptics,
        sound: settings.feedback.sound,
      );
    }

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _userInput = '';
    });
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final isEasyMode = settings.difficulty == Difficulty.easy;

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
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 180),
                        child: Column(
                          children: [
                            const Gap(24),
                            // Display area
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: GlassContainer(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Row with refresh and hint buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(width: 40),
                                        IconButton(
                                          onPressed: _generateNewSentence,
                                          icon: Icon(
                                            Icons.refresh,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => setState(
                                            () => _showHint = !_showHint,
                                          ),
                                          icon: Icon(
                                            _showHint
                                                ? Icons.lightbulb
                                                : Icons.lightbulb_outline,
                                            color: _showHint
                                                ? Colors.amber
                                                : (isDark
                                                      ? Colors.white24
                                                      : Colors.black26),
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Sentence with highlighted letter
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: List.generate(
                                        _targetSentence.length,
                                        (index) {
                                          final char = _targetSentence[index];
                                          final isCompleted =
                                              index < _currentIndex;
                                          final isCurrent =
                                              index == _currentIndex;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                              vertical: 4,
                                            ),
                                            child: Text(
                                              char,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent
                                                    ? AppTheme.neonCyan
                                                    : isCompleted
                                                    ? (isDark
                                                          ? Colors.white54
                                                          : Colors.black45)
                                                    : (isDark
                                                          ? Colors.white
                                                          : Colors.black87),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const Gap(24),
                                    // Current letter morse code
                                    if (_showHint && _currentMorse.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: Text(
                                          _currentMorse,
                                          style: TextStyle(
                                            fontSize: 32, // Larger hint
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(),

                            const Gap(24),

                            // User Input Display
                            SizedBox(
                              height: 60,
                              child: Text(
                                _userInput,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: AppTheme.neonCyan,
                                  shadows: [
                                    BoxShadow(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Gap(16),

                            // Completion or Input Controls
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_isComplete)
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppTheme.successGreen,
                                          size: 64,
                                        ),
                                        const Gap(16),
                                        Text(
                                          'TRANSMISSION COMPLETE',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.successGreen,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ).animate().fadeIn().scale()
                                  else if (isEasyMode)
                                    _buildEasyModeControls(isDark)
                                  else
                                    _buildHardModeControls(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEasyModeControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Dot button
          Expanded(
            child: GlassButton(
              height: 100,
              onTap: () => _addSymbol(false),
              tintColor: AppTheme.neonCyan.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'DOT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),
          // Dash button
          Expanded(
            child: GlassButton(
              height: 100,
              onTap: () => _addSymbol(true),
              tintColor: AppTheme.neonPink.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonPink.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'DASH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildHardModeControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 160,
        child: TapPad(
          onInput: (isDash) => _addSymbol(isDash),
          activeColor: AppTheme.neonCyan,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
