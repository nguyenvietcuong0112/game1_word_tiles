import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';

enum GameIconButtonVariant {
  woodcraft,
  danger,
  neutral,
}

enum GameIconButtonSize {
  header,      // 44.r (standard for top bars)
  dialogClose, // 36.r (for popup top-right close 'X')
  large,       // 54.r (for victory replay, hero actions)
  mini,        // 32.r (for inline compact controls)
}

/// Unified 3D Circular Button for Word Tiles.
/// Replaces duplicated double-ring woodcraft buttons across all screens.
class GameIconButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final GameIconButtonVariant variant;
  final GameIconButtonSize size;
  final double? customSize;

  const GameIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.variant = GameIconButtonVariant.woodcraft,
    this.size = GameIconButtonSize.header,
    this.customSize,
  });

  /// Standard 3D Back Arrow Button
  static Widget back(
    BuildContext context, {
    VoidCallback? onTap,
    GameIconButtonSize size = GameIconButtonSize.header,
  }) {
    return GameIconButton(
      onTap: () {
        AudioManager.playTileSelect(pitchIndex: 2);
        if (onTap != null) {
          onTap();
        } else {
          Navigator.maybePop(context);
        }
      },
      size: size,
      icon: const Icon(
        Icons.chevron_left_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  /// Standard Glossy Red Circular Close "X" Button for Popups
  static Widget close(
    BuildContext context, {
    VoidCallback? onTap,
    GameIconButtonSize size = GameIconButtonSize.dialogClose,
  }) {
    return GameIconButton(
      onTap: () {
        AudioManager.playTileSelect(pitchIndex: 1);
        if (onTap != null) {
          onTap();
        } else {
          Navigator.maybePop(context);
        }
      },
      variant: GameIconButtonVariant.danger,
      size: size,
      icon: const Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  /// Standard Settings Button
  static Widget settings({
    required VoidCallback onTap,
    GameIconButtonSize size = GameIconButtonSize.header,
  }) {
    return GameIconButton(
      onTap: () {
        AudioManager.playTileSelect(pitchIndex: 4);
        onTap();
      },
      size: size,
      icon: const Icon(
        Icons.settings_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  /// Standard Replay Button (Large round 3D button)
  static Widget replay({
    required VoidCallback onTap,
    GameIconButtonSize size = GameIconButtonSize.large,
  }) {
    return GameIconButton(
      onTap: () {
        AudioManager.playTileSelect(pitchIndex: 3);
        onTap();
      },
      size: size,
      icon: const Icon(
        Icons.replay_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  @override
  State<GameIconButton> createState() => _GameIconButtonState();
}

class _GameIconButtonState extends State<GameIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
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

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _controller.forward();
    if (GameStorage.isHapticEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final double dimension;
    if (widget.customSize != null) {
      dimension = widget.customSize!;
    } else {
      switch (widget.size) {
        case GameIconButtonSize.header:
          dimension = 44.r;
          break;
        case GameIconButtonSize.dialogClose:
          dimension = 36.r;
          break;
        case GameIconButtonSize.large:
          dimension = 54.r;
          break;
        case GameIconButtonSize.mini:
          dimension = 32.r;
          break;
      }
    }

    Widget buttonContent;

    if (widget.variant == GameIconButtonVariant.danger) {
      // Glossy 3D Red Badge (for dialog top-right close "X")
      buttonContent = Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5252), Color(0xFFE53935)],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              offset: Offset(0, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: AppColors.dangerShadow,
              offset: Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(child: widget.icon),
      );
    } else if (widget.variant == GameIconButtonVariant.neutral) {
      // Soft Birch / Cream Ring
      buttonContent = Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: AppColors.cardPeachLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE8DAC8),
              offset: Offset(0, 2.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(child: widget.icon),
      );
    } else {
      // Signature 3D Dual-Ring Woodcraft Button
      final padding = dimension >= 50.r ? 4.5 : (dimension <= 34.r ? 3.0 : 4.0);

      buttonContent = Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: AppColors.btnRingBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.btnRingBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.btnRingShadow,
              offset: Offset(0, 2.0),
              blurRadius: 0,
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.btnFaceBrown,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.btnBorderBrown, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.btnShadowBrown,
                offset: Offset(0, 1.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(child: widget.icon),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: buttonContent,
      ),
    );
  }
}
