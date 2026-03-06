import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../theme/app_theme.dart';
import 'glass_button.dart';
import 'tap_pad.dart';

/// Shared morse input controls used by both Send Letters and Send Sentences.
///
/// In easy mode: two Dot / Dash buttons side by side.
/// In hard mode: a single TapPad that distinguishes short vs long presses.
class MorseInputPanel extends StatelessWidget {
  /// Called when the user inputs a dot (false) or dash (true).
  final ValueChanged<bool> onInput;

  /// Whether to show easy mode (two buttons) or hard mode (tap pad).
  final bool isEasyMode;

  const MorseInputPanel({
    super.key,
    required this.onInput,
    required this.isEasyMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isEasyMode ? _buildEasyMode(isDark) : _buildHardMode();
  }

  Widget _buildEasyMode(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Dot button
          Expanded(
            child: GlassButton(
              height: 100,
              onTap: () => onInput(false),
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
              onTap: () => onInput(true),
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

  Widget _buildHardMode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 160,
        child: TapPad(
          onInput: (isDash) => onInput(isDash),
          activeColor: AppTheme.neonCyan,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
