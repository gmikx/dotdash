import 'package:flutter/material.dart';
import 'glass_container.dart';

/// A tappable glass button with splash effect
class GlassButton extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final VoidCallback? onTapCancel;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tintColor;
  final Color? splashColor;
  final bool enabled;
  final double blur;

  const GlassButton({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.margin,
    this.width,
    this.height,
    this.tintColor,
    this.splashColor,
    this.enabled = true,
    this.blur = 15.0,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
    widget.onTapDown?.call(details);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _controller.reverse();
    widget.onTapUp?.call(details);
  }

  void _handleTapCancel() {
    _controller.reverse();
    widget.onTapCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final splash =
        widget.splashColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05));

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: GlassContainer(
          blur: widget.blur,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          tintColor: widget.tintColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: splash,
              highlightColor: splash.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: null, // Handled by GestureDetector
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
