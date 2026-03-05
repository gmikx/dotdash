import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../logic/settings_provider.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

/// Settings modal screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0A0A0F)]
              : [Colors.grey.shade100, Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Difficulty section
                  _buildSectionTitle('DIFFICULTY', isDark),
                  const Gap(12),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              settings.difficulty == Difficulty.easy
                                  ? Icons.sentiment_satisfied
                                  : Icons.sentiment_very_dissatisfied,
                              color: settings.difficulty == Difficulty.easy
                                  ? AppTheme.successGreen
                                  : AppTheme.neonPink,
                              size: 32,
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.difficulty == Difficulty.easy
                                        ? 'Easy Mode'
                                        : 'Hard Mode',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    settings.difficulty == Difficulty.easy
                                        ? 'Two buttons: Tap for dot, tap for dash'
                                        : 'One tap pad: Quick tap = dot, hold = dash',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: settings.difficulty == Difficulty.hard,
                              onChanged: (value) => notifier.setDifficulty(
                                value ? Difficulty.hard : Difficulty.easy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1),

                  const Gap(32),

                  // Speed section
                  _buildSectionTitle('TRANSMISSION SPEED', isDark),
                  const Gap(12),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${settings.wpm.round()} WPM',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              settings.wpm < 10
                                  ? 'Very Slow'
                                  : settings.wpm < 15
                                  ? 'Slow'
                                  : settings.wpm < 20
                                  ? 'Normal'
                                  : settings.wpm < 25
                                  ? 'Fast'
                                  : 'Very Fast',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.neonCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Slider(
                          value: settings.wpm,
                          min: 5.0,
                          max: 30.0,
                          divisions: 25,
                          onChanged: (value) => notifier.setWpm(value),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '5 WPM',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                            ),
                            Text(
                              '30 WPM',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                  const Gap(32),

                  // Feedback section
                  _buildSectionTitle('FEEDBACK', isDark),
                  const Gap(12),
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildToggleTile(
                          icon: Icons.volume_up,
                          title: 'Sound',
                          subtitle: 'Audio feedback for morse signals',
                          value: settings.feedback.sound,
                          onChanged: (v) => notifier.setSound(v),
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildToggleTile(
                          icon: Icons.vibration,
                          title: 'Haptics',
                          subtitle: 'Vibration patterns for morse signals',
                          value: settings.feedback.haptics,
                          onChanged: (v) => notifier.setHaptics(v),
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildToggleTile(
                          icon: Icons.flash_on,
                          title: 'Flash',
                          subtitle: 'Screen flash for morse signals',
                          value: settings.feedback.flash,
                          onChanged: (v) => notifier.setFlash(v),
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildToggleTile(
                          icon: Icons.text_fields,
                          title: 'Show Morse Text',
                          subtitle: 'Display dots and dashes on screen',
                          value: settings.feedback.screenText,
                          onChanged: (v) => notifier.setScreenText(v),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                  const Gap(32),

                  // About section
                  _buildSectionTitle('ABOUT', isDark),
                  const Gap(12),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/dotdash_logo.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DotDash',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    'Version 1.0.0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Text(
                          'Learn Morse code through haptic feedback, visual cues, and gamified exercises.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                  const Gap(32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: value
            ? AppTheme.neonCyan
            : (isDark ? Colors.white38 : Colors.black26),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black26,
        ),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
