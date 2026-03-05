import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'screens.dart';
import '../theme/app_theme.dart';

/// Main home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReceiveLettersScreen(),
    SendLettersScreen(),
    ReceiveSentencesScreen(),
    SendSentencesScreen(),
  ];

  final List<String> _titles = const [
    'Receive Letters',
    'Send Letters',
    'Receive Sentences',
    'Send Sentences',
  ];

  final List<IconData> _icons = const [
    Icons.hearing,
    Icons.touch_app,
    Icons.headphones,
    Icons.keyboard,
  ];

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Settings button
          IconButton(
            onPressed: () => _openSettings(context),
            icon: Icon(
              Icons.settings,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const Gap(8),
        ],
      ),
      body: Container(
        decoration: isDark
            ? AppTheme.darkGradientBackground
            : AppTheme.lightGradientBackground,
        child: SafeArea(
          bottom: false,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassNavBar(isDark),
    );
  }

  Widget _buildGlassNavBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    final isSelected = _currentIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected
                              ? AppTheme.neonCyan.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _icons[index],
                              size: 24,
                              color: isSelected
                                  ? AppTheme.neonCyan
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                            const Gap(4),
                            Text(
                              _getShortTitle(index),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.neonCyan
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3);
  }

  String _getShortTitle(int index) {
    switch (index) {
      case 0:
        return 'Receive';
      case 1:
        return 'Send';
      case 2:
        return 'Decode';
      case 3:
        return 'Transmit';
      default:
        return '';
    }
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {}, // Prevent taps on the sheet from closing
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: const SettingsScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
