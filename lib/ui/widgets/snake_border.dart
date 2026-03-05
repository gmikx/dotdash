import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SnakeBorder extends StatefulWidget {
  final Widget child;
  final bool show;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final int maxLoops;

  const SnakeBorder({
    super.key,
    required this.child,
    this.show = false,
    this.borderWidth = 4.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(4.0),
    this.maxLoops = 3,
  });

  @override
  State<SnakeBorder> createState() => _SnakeBorderState();
}

class _SnakeBorderState extends State<SnakeBorder>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  int _loopCount = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );

    _controller.addStatusListener(_onAnimationStatusChanged);
    _fadeController.addStatusListener(_onFadeStatusChanged);

    if (widget.show) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(SnakeBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _startAnimation();
    } else if (!widget.show && oldWidget.show) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _loopCount = 0;
    _isVisible = true;
    _fadeController.value = 1.0;
    _controller.forward(from: 0);
  }

  void _stopAnimation() {
    _controller.stop();
    _controller.reset();
    _isVisible = false;
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _loopCount++;
      if (_loopCount < widget.maxLoops) {
        _controller.forward(from: 0);
      } else {
        _fadeController.reverse();
      }
    }
  }

  void _onFadeStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _fadeController.removeStatusListener(_onFadeStatusChanged);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(padding: widget.padding, child: widget.child),
        if (_isVisible)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _SnakeBorderPainter(
                          progress: _controller.value,
                          opacity: _fadeController.value,
                          borderWidth: widget.borderWidth,
                          borderRadius: widget.borderRadius,
                          color: AppTheme.successGreen,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _SnakeBorderPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final double borderWidth;
  final double borderRadius;
  final Color color;

  _SnakeBorderPainter({
    required this.progress,
    required this.opacity,
    required this.borderWidth,
    required this.borderRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final pathLength = metric.length;

    final double snakeLength = pathLength * 0.25;
    final double phase = progress * pathLength;

    Path snakePath = Path();

    double start = phase - snakeLength;
    double end = phase;

    if (start < 0) {
      final part1 = metric.extractPath(pathLength + start, pathLength);
      final part2 = metric.extractPath(0, end);
      snakePath.addPath(part1, Offset.zero);
      snakePath.addPath(part2, Offset.zero);
    } else {
      snakePath.addPath(metric.extractPath(start, end), Offset.zero);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    paint.color = color.withValues(alpha: opacity);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawPath(snakePath, paint);

    paint.maskFilter = null;
    paint.color = color.withValues(alpha: opacity);
    canvas.drawPath(snakePath, paint);
  }

  @override
  bool shouldRepaint(_SnakeBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
