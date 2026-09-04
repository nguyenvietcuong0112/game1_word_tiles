import 'package:flutter/material.dart';

/// Reusable full-screen warm ambient woodcraft game background
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Warm Ambient Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFF9F0), // Soft Cream Studio Light
                Color(0xFFFAF0E1), // Warm Amber Light
                Color(0xFFF1DECB), // Cozy Warm Floor Canvas
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // High-Quality Ambient Stage Floor Lighting
        Positioned.fill(
          child: Image.asset(
            'assets/images/wood_game_bg.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),

        // Foreground Content
        child,
      ],
    );
  }
}
