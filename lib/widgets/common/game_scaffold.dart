import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'game_background.dart';

/// Unified Game Scaffold for Word Tiles.
/// Bundles Scaffold, GameBackground, SafeArea, and PopScope back confirmation cleanly.
class GameScaffold extends StatelessWidget {
  final Widget body;
  final GameBackgroundVariant backgroundVariant;
  final Future<bool> Function()? onWillPop;
  final bool useSafeArea;
  final Color? backgroundColor;

  const GameScaffold({
    super.key,
    required this.body,
    this.backgroundVariant = GameBackgroundVariant.standard,
    this.onWillPop,
    this.useSafeArea = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GameBackground(
      variant: backgroundVariant,
      child: useSafeArea ? SafeArea(child: body) : body,
    );

    if (onWillPop != null) {
      content = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await onWillPop!();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.bgCanvas,
      body: content,
    );
  }
}
