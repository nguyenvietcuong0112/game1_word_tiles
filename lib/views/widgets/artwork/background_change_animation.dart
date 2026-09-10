// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

/// Constants for chapter background transition animation
const double EXIT_SCALE_VALUE = 1.35;
const Duration BACKGROUND_CHANGE_DURATION = Duration(milliseconds: 850);

/// BackgroundChangeAnimation manages the cinematic transition between two chapter backgrounds:
/// - Zooms in and fades out the exiting background (EXIT_SCALE_VALUE = 1.35).
/// - Slides and fades in the entering new chapter background over BACKGROUND_CHANGE_DURATION.
class BackgroundChangeAnimation extends StatefulWidget {
  final Widget currentBackground;
  final Widget? previousBackground;
  final bool isTransitioning;
  final VoidCallback? onTransitionComplete;

  const BackgroundChangeAnimation({
    super.key,
    required this.currentBackground,
    this.previousBackground,
    this.isTransitioning = false,
    this.onTransitionComplete,
  });

  @override
  State<BackgroundChangeAnimation> createState() => _BackgroundChangeAnimationState();
}

class _BackgroundChangeAnimationState extends State<BackgroundChangeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _exitScaleAnimation;
  late final Animation<double> _exitFadeAnimation;
  late final Animation<Offset> _enterSlideAnimation;
  late final Animation<double> _enterFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: BACKGROUND_CHANGE_DURATION,
    );

    _exitScaleAnimation = Tween<double>(
      begin: 1.0,
      end: EXIT_SCALE_VALUE,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInCubic,
    ));

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.20, 1.0, curve: Curves.easeOut),
    ));

    _enterSlideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _enterFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeIn),
    ));

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTransitionComplete?.call();
      }
    });

    if (widget.isTransitioning) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant BackgroundChangeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransitioning && !oldWidget.isTransitioning) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTransitioning || widget.previousBackground == null) {
      return widget.currentBackground;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Exiting background: Zooms in (EXIT_SCALE_VALUE) and fades out
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _exitFadeAnimation,
              child: Transform.scale(
                scale: _exitScaleAnimation.value,
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          child: widget.previousBackground,
        ),

        // 2. Entering new background: Slides in subtly and fades in
        SlideTransition(
          position: _enterSlideAnimation,
          child: FadeTransition(
            opacity: _enterFadeAnimation,
            child: widget.currentBackground,
          ),
        ),
      ],
    );
  }
}

/// NextChapterAnimation is an alias for BackgroundChangeAnimation
typedef NextChapterAnimation = BackgroundChangeAnimation;
