import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SuccessOverlay extends StatefulWidget {
  final bool show;
  final Widget child;

  const SuccessOverlay({super.key, required this.show, required this.child});

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child:
                  Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.successGreen,
                            width: 8,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .shimmer(
                        duration: 1000.ms,
                        color: AppTheme.successGreen.withValues(alpha: 0.5),
                      )
                      .then()
                      .fadeOut(delay: 500.ms),
            ),
          ),
      ],
    );
  }
}
