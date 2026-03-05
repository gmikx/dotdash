import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Displays a morse code pattern visually (dots and dashes)
class MorseDisplay extends StatelessWidget {
  final String morseCode;
  final int highlightIndex;
  final Color? dotColor;
  final Color? dashColor;
  final Color? highlightColor;
  final double dotSize;
  final double dashWidth;
  final double height;
  final double spacing;

  const MorseDisplay({
    super.key,
    required this.morseCode,
    this.highlightIndex = -1,
    this.dotColor,
    this.dashColor,
    this.highlightColor,
    this.dotSize = 16,
    this.dashWidth = 40,
    this.height = 16,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black54;
    final highlight = highlightColor ?? Colors.cyanAccent;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(morseCode.length, (index) {
        final symbol = morseCode[index];
        final isHighlighted = index == highlightIndex;
        final color = isHighlighted ? highlight : (dotColor ?? defaultColor);

        if (symbol == '.') {
          return _buildDot(color, isHighlighted);
        } else if (symbol == '-') {
          return _buildDash(color, isHighlighted);
        } else if (symbol == ' ') {
          return SizedBox(width: spacing * 2);
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildDot(Color color, bool isHighlighted) {
    Widget dot = Container(
      width: dotSize,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    if (isHighlighted) {
      dot = dot
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 800.ms,
            color: Colors.white.withValues(alpha: 0.3),
          );
    }

    return dot;
  }

  Widget _buildDash(Color color, bool isHighlighted) {
    Widget dash = Container(
      width: dashWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    if (isHighlighted) {
      dash = dash
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 800.ms,
            color: Colors.white.withValues(alpha: 0.3),
          );
    }

    return dash;
  }
}
