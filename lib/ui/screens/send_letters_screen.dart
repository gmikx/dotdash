import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../logic/morse_engine.dart';
import '../../logic/settings_provider.dart';
import '../../logic/feedback_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

/// Tab 2: Send Letters - The Trainer
/// Shows a letter, user must tap the correct morse pattern
class SendLettersScreen extends ConsumerStatefulWidget {
  const SendLettersScreen({super.key});

  @override
  ConsumerState<SendLettersScreen> createState() => _SendLettersScreenState();
}

class _SendLettersScreenState extends ConsumerState<SendLettersScreen>
    with SingleTickerProviderStateMixin {
  final _engine = MorseEngine.instance;
  final _feedback = FeedbackService.instance;

  String _targetLetter = '';
  String _targetMorse = '';
  String _userInput = '';
  bool _showSuccess = false;
  bool _showError = false;
  bool _showHint = true;
  int _successCount = 0;
  bool _busy = false; // locks input during feedback playback

  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _feedback.initialize();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _generateNewLetter();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateNewLetter() {
    setState(() {
      _targetLetter = _engine.getRandomLetter();
      _targetMorse = _engine.toMorse(_targetLetter) ?? '';
      _userInput = '';
      _showSuccess = false;
      _showError = false;
    });
  }

  Future<void> _addSymbol(bool isDash) async {
    if (_busy) return;
    final settings = ref.read(settingsProvider);
    final timing = _engine.getTiming(settings.wpm);

    // Add feedback for the tap
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

    // Check if input is valid
    if (_targetMorse.startsWith(newInput)) {
      setState(() {
        _userInput = newInput;
      });

      // Check if complete
      if (newInput == _targetMorse) {
        await _handleSuccess();
      }
    } else {
      await _handleError();
    }
  }

  Future<void> _handleSuccess() async {
    _busy = true;
    final settings = ref.read(settingsProvider);

    setState(() {
      _showSuccess = true;
      _successCount++;
    });

    if (settings.feedback.haptics || settings.feedback.sound) {
      await _feedback.playSuccess(
        haptics: settings.feedback.haptics,
        sound: settings.feedback.sound,
      );
    }

    _confettiController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1200));
    _busy = false;
    _generateNewLetter();
  }

  Future<void> _handleError() async {
    _busy = true;
    final settings = ref.read(settingsProvider);

    setState(() {
      _showError = true;
    });

    if (settings.feedback.haptics || settings.feedback.sound) {
      await _feedback.playError(
        haptics: settings.feedback.haptics,
        sound: settings.feedback.sound,
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _userInput = '';
      _showError = false;
    });
    _busy = false;
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
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Gap(24),

                          const Gap(24),

                          // Success counter
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const Gap(8),
                                Text(
                                  'Completed: $_successCount',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: -0.2),

                          const Gap(40),

                          // Target letter display with SnakeBorder
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              height: 150, // Height for the area
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // CENTERED LETTER
                                  SnakeBorder(
                                        show: _showSuccess,
                                        borderRadius: 30,
                                        padding: const EdgeInsets.all(4),
                                        child: GlassContainer(
                                          width: 140,
                                          height: 140,
                                          borderRadius: 30,
                                          tintColor: _showError
                                              ? AppTheme.errorRed.withValues(
                                                  alpha: 0.3,
                                                )
                                              : (_showSuccess
                                                    ? AppTheme.successGreen
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                    : null),
                                          child: Center(
                                            child: Text(
                                              _targetLetter,
                                              style: TextStyle(
                                                fontSize: 80,
                                                fontWeight: FontWeight.bold,
                                                color: _showError
                                                    ? AppTheme.errorRed
                                                    : (isDark
                                                          ? Colors.white
                                                          : Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .animate(key: ValueKey(_targetLetter))
                                      .fadeIn()
                                      .scale(),

                                  // OFFSET HINT (Top Right)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
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
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Gap(24),

                          // Morse hint
                          Visibility(
                            visible: _showHint,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: MorseDisplay(
                              morseCode: _targetMorse,
                              highlightIndex: _userInput.length,
                            ).animate().fadeIn(delay: 100.ms),
                          ),

                          const Gap(16),

                          // User input display - Simplified
                          Text(
                            _userInput.isEmpty ? '' : _userInput,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          const Spacer(),

                          // Input controls
                          if (ref.watch(settingsProvider).difficulty ==
                              Difficulty.easy)
                            _buildEasyModeControls(isDark)
                          else
                            _buildHardModeControls(),

                          // Extra padding for bottom navbar
                          const Gap(180),
                        ],
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
              height: 120,
              onTap: () => _addSymbol(false),
              tintColor: AppTheme.neonCyan.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'DOT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(24),
          // Dash button
          Expanded(
            child: GlassButton(
              height: 120,
              onTap: () => _addSymbol(true),
              tintColor: AppTheme.neonPink.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonPink.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'DASH',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildHardModeControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 200,
        child: TapPad(
          onInput: (isDash) => _addSymbol(isDash),
          activeColor: AppTheme.neonCyan,
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}
