import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_storage.dart';

/// Custom Game Page Route with smooth Zoom-Fade transition.
/// Avoids sluggish OS-level platform slide transitions and provides a unified,
/// punchy casual game feel across Android and iOS.
class GamePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  GamePageRoute({
    required this.child,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedPrimary = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final curvedSecondary = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.85).animate(curvedSecondary),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.96).animate(curvedSecondary),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedPrimary),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedPrimary),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}

/// Standard casual-game spring pop-in dialog presentation.
/// Features a dark scrim fade, bouncy scale pop-in with Curves.easeOutBack,
/// and a quick crisp exit dismiss with Curves.easeInBack.
Future<T?> showGameDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor = const Color(0x9E000000),
  Duration duration = const Duration(milliseconds: 280),
}) {
  if (GameStorage.isHapticEnabled()) {
    HapticFeedback.lightImpact();
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: barrierColor,
    transitionDuration: duration,
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curvedAnim = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );

      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.72, end: 1.0).animate(curvedAnim),
          child: child,
        ),
      );
    },
  );
}
