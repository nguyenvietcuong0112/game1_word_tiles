import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_storage.dart';

/// Interactive tactile button wrapper providing casual-game bouncy press physics.
/// Compresses instantly on touch with 0ms pointer latency and haptic feedback,
/// and springs back with Curves.easeOutBack.
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final HitTestBehavior behavior;

  const BouncyButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.92,
    this.duration = const Duration(milliseconds: 90),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BouncyButton> createState() => BouncyButtonState();
}

class BouncyButtonState extends State<BouncyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  double get currentScale => _scaleAnimation.value;
  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 140),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap == null) return;
    _controller.forward();
    if (GameStorage.isHapticEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return Listener(
      behavior: widget.behavior,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
