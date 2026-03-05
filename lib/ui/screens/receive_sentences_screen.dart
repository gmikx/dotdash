import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../logic/morse_engine.dart';
import '../../logic/settings_provider.dart';
import '../../logic/feedback_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

/// Tab 3: Receive Sentences
/// App plays a random sentence via morse, user types the answer
class ReceiveSentencesScreen extends ConsumerStatefulWidget {
  const ReceiveSentencesScreen({super.key});

  @override
  ConsumerState<ReceiveSentencesScreen> createState() =>
      _ReceiveSentencesScreenState();
}

class _ReceiveSentencesScreenState
    extends ConsumerState<ReceiveSentencesScreen> {
  final _engine = MorseEngine.instance;
  final _feedback = FeedbackService.instance;
  final _textController = ColoredTextEditingController();
  final _focusNode = FocusNode();

  String _targetSentence = '';
  String _revealedText = '';
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isComplete = false;
  int _currentCharIndex = 0;
  double _localWpm = 15.0;
  bool _shouldStop = false;

  int _previousTextLength = 0;

  @override
  void initState() {
    super.initState();
    _feedback.initialize();
    _generateNewSentence();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateNewSentence() {
    setState(() {
      _targetSentence = _engine.generateSentence();
      _textController.targetText =
          _targetSentence; // Update target for coloring
      _revealedText = '';
      _isComplete = false;
      _currentCharIndex = 0;
      _shouldStop = false;
      _isPlaying = false;
      _isPaused = false;
      _previousTextLength = 0;
    });
    _textController.clear();
    _localWpm = ref.read(settingsProvider).wpm;
  }

  void _onTextChanged() {
    final userText = _textController.text.toUpperCase();
    final targetClean = _targetSentence.toUpperCase();

    // Check for wrong character entry
    if (userText.length > _previousTextLength) {
      // User added character(s)
      final lastCharIndex = userText.length - 1;
      if (lastCharIndex < targetClean.length) {
        if (userText[lastCharIndex] != targetClean[lastCharIndex]) {
          // Wrong character
          _feedback.playError(
            haptics: ref.read(settingsProvider).feedback.haptics,
            sound: ref.read(settingsProvider).feedback.sound,
          );
        }
      } else {
        // Exceeded length - also wrong
        _feedback.playError(
          haptics: ref.read(settingsProvider).feedback.haptics,
          sound: ref.read(settingsProvider).feedback.sound,
        );
      }
    }
    _previousTextLength = userText.length;

    // Check how many characters are correct
    int correctCount = 0;
    for (int i = 0; i < userText.length && i < targetClean.length; i++) {
      if (userText[i] == targetClean[i]) {
        correctCount = i + 1;
      } else {
        break;
      }
    }

    setState(() {
      _revealedText = _targetSentence.substring(0, correctCount);
      if (correctCount == _targetSentence.length &&
          userText.length == targetClean.length) {
        _isComplete = true;
        _focusNode.unfocus();
        _feedback.playSuccess(
          haptics: ref.read(settingsProvider).feedback.haptics,
          sound: ref.read(settingsProvider).feedback.sound,
        );
        // Auto-advance
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _generateNewSentence();
          }
        });
      } else {
        _isComplete = false;
      }
    });
  }

  Future<void> _playSequence() async {
    if (_isPlaying) {
      setState(() {
        _isPaused = !_isPaused;
      });
      return;
    }

    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _shouldStop = false;
      _currentCharIndex = 0;
    });

    final settings = ref.read(settingsProvider);
    final timing = _engine.getTiming(_localWpm);

    await _feedback.playMorseSequence(
      _targetSentence,
      haptics: settings.feedback.haptics,
      sound: settings.feedback.sound,
      timing: timing,
      onCharacter: (index, char) {
        if (!_isPaused && mounted) {
          setState(() {
            _currentCharIndex = index;
          });
        }
      },
      shouldStop: () => _shouldStop || _isPaused,
    );

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _stopPlayback() {
    setState(() {
      _shouldStop = true;
      _isPlaying = false;
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
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
                          padding: const EdgeInsets.only(bottom: 140),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Gap(24),
                              // Playback controls
                              GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    // Control buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Play/Pause button
                                        GlassButton(
                                          width: 80,
                                          height: 80,
                                          borderRadius: 40,
                                          padding: EdgeInsets.zero,
                                          onTap: _isComplete
                                              ? null
                                              : _playSequence,
                                          tintColor: _isPlaying
                                              ? AppTheme.neonCyan.withValues(
                                                  alpha: 0.2,
                                                )
                                              : null,
                                          child: Center(
                                            child: Icon(
                                              _isPlaying
                                                  ? (_isPaused
                                                        ? Icons.play_arrow
                                                        : Icons.pause)
                                                  : Icons.play_arrow,
                                              size: 40,
                                              color: _isComplete
                                                  ? Colors.grey
                                                  : AppTheme.neonCyan,
                                            ),
                                          ),
                                        ),
                                        const Gap(24),
                                        // Stop button
                                        GlassButton(
                                          width: 60,
                                          height: 60,
                                          borderRadius: 30,
                                          padding: EdgeInsets.zero,
                                          onTap: _isPlaying
                                              ? _stopPlayback
                                              : null,
                                          enabled: _isPlaying,
                                          child: Center(
                                            child: Icon(
                                              Icons.stop,
                                              size: 32,
                                              color: _isPlaying
                                                  ? AppTheme.errorRed
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        const Gap(24),
                                        // New sentence button
                                        GlassButton(
                                          width: 60,
                                          height: 60,
                                          borderRadius: 30,
                                          padding: EdgeInsets.zero,
                                          onTap: _generateNewSentence,
                                          child: Center(
                                            child: Icon(
                                              Icons.refresh,
                                              size: 32,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(20),
                                    // Speed slider
                                    Row(
                                      children: [
                                        const Icon(Icons.speed, size: 20),
                                        const Gap(12),
                                        Expanded(
                                          child: Slider(
                                            value: _localWpm,
                                            min: 5.0,
                                            max: 30.0,
                                            divisions: 25,
                                            label: '${_localWpm.round()} WPM',
                                            onChanged: (value) {
                                              setState(() => _localWpm = value);
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            '${_localWpm.round()}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideY(begin: -0.2),

                              const Gap(32),

                              // Hidden sentence (revealed as user types correctly)
                              GlassContainer(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text(
                                      'DECODE THE MESSAGE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                    const Gap(16),
                                    // Masked display
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: List.generate(
                                        _targetSentence.length,
                                        (index) {
                                          final isRevealed =
                                              index < _revealedText.length;
                                          final isCurrentChar =
                                              index == _currentCharIndex &&
                                              _isPlaying;
                                          final char = _targetSentence[index];

                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                              vertical: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCurrentChar
                                                  ? AppTheme.neonCyan
                                                        .withValues(alpha: 0.3)
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isRevealed
                                                  ? char
                                                  : (char == ' ' ? ' ' : '•'),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: isRevealed
                                                    ? AppTheme.successGreen
                                                    : (isDark
                                                          ? Colors.white38
                                                          : Colors.black26),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(),

                              const Gap(32),

                              // Completion message or Input
                              if (_isComplete)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.successGreen,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.successGreen,
                                        size: 32,
                                      ),
                                      const Gap(12),
                                      const Text(
                                        'DECODED!',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().scale(
                                  begin: const Offset(0.8, 0.8),
                                )
                              else
                                // Text input
                                GlassContainer(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: TextField(
                                        controller: _textController,
                                        focusNode: _focusNode,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Type your answer...',
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black26,
                                          ),
                                          border: InputBorder.none,
                                          prefixIcon: Icon(
                                            Icons.keyboard,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black26,
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 200.ms)
                                    .slideY(begin: 0.2),

                              const Spacer(),
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
      ),
    );
  }
}

class ColoredTextEditingController extends TextEditingController {
  String targetText = '';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> spans = [];
    final String cleanTarget = targetText.toUpperCase();
    final String currentText = text.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loop through current text
    for (int i = 0; i < text.length; i++) {
      Color color;
      if (i < cleanTarget.length) {
        if (currentText[i] == cleanTarget[i]) {
          // Correct character
          color = isDark ? Colors.white : Colors.black87;
        } else {
          // Wrong character
          color = AppTheme.errorRed;
        }
      } else {
        // Extra characters (also wrong)
        color = AppTheme.errorRed;
      }

      spans.add(
        TextSpan(
          text: text[i],
          style: style?.copyWith(color: color),
        ),
      );
    }

    return TextSpan(style: style, children: spans);
  }
}
