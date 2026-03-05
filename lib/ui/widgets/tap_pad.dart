import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A fully interactive tap pad for hard mode
/// Tap (<200ms) = Dot, Hold (>=200ms) = Dash
class TapPad extends StatefulWidget {
  final void Function(bool isDash)? onInput;
  final VoidCallback? onTapStart;
  final bool enabled;
  final Color? activeColor;

  const TapPad({
    super.key,
    this.onInput,
    this.onTapStart,
    this.enabled = true,
    this.activeColor,
  });

  @override
  State<TapPad> createState() => _TapPadState();
}

class _TapPadState extends State<TapPad> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  DateTime? _pressStart;
  static const _dashThreshold = Duration(milliseconds: 200);

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = true;
      _pressStart = DateTime.now();
    });
    widget.onTapStart?.call();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || _pressStart == null) return;

    final duration = DateTime.now().difference(_pressStart!);
    final isDash = duration >= _dashThreshold;

    setState(() {
      _isPressed = false;
      _pressStart = null;
    });

    widget.onInput?.call(isDash);
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
      _pressStart = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        widget.activeColor ?? (isDark ? Colors.cyanAccent : Colors.blueAccent);

    return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: _isPressed
                    ? [
                        activeColor.withValues(alpha: 0.4),
                        activeColor.withValues(alpha: 0.1),
                      ]
                    : [
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.1,
                        ),
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.05,
                        ),
                      ],
              ),
              border: Border.all(
                color: _isPressed
                    ? activeColor.withValues(alpha: 0.5)
                    : (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.2,
                      ),
                width: 2,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPressed ? Icons.radio_button_checked : Icons.touch_app,
                    size: 48,
                    color: _isPressed
                        ? activeColor
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPressed ? 'HOLD FOR DASH' : 'TAP FOR DOT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: _isPressed
                          ? activeColor
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(target: _isPressed ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.98, 0.98),
          duration: 100.ms,
        );
  }
}
