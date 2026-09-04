import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/game_controller.dart';
import '../../services/game_storage.dart';
import '../common/wood_widgets.dart';

class BoosterBar extends StatelessWidget {
  final GameController controller;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenExtraWords;

  const BoosterBar({
    super.key,
    required this.controller,
    this.onOpenShop,
    this.onOpenExtraWords,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final extraCount = GameStorage.getExtraWordsChestCount();
        final hintCount = GameStorage.getHintCount();
        final rocketCount = GameStorage.getRocketCount();
        final isReadyToClaim = extraCount >= 10;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Extra Words Button (Authentic Wooden Ring)
              WoodCircularButton(
                size: 56.r,
                icon: WoodGameIcons.extraWords(size: 30.r),
                badgeText: isReadyToClaim ? 'CLAIM!' : '$extraCount/10',
                badgeColor: isReadyToClaim ? const Color(0xFF10B981) : null,
                onTap: onOpenExtraWords,
              ),

              // 2. Hint Booster 💡
              WoodCircularButton(
                size: 56.r,
                icon: WoodGameIcons.hint(size: 30.r),
                badgeText: hintCount > 0 ? '$hintCount' : '80 🪙',
                onTap: () => controller.useHint(),
              ),

              // 3. Rocket Booster 🚀
              WoodCircularButton(
                size: 56.r,
                icon: WoodGameIcons.rocket(size: 30.r),
                badgeText: rocketCount > 0 ? '$rocketCount' : '240 🪙',
                onTap: () => controller.useRocket(),
              ),

              // 4. Shop / Chest 🎁
              WoodCircularButton(
                size: 56.r,
                icon: WoodGameIcons.shop(size: 30.r),
                badgeText: 'SHOP',
                onTap: onOpenShop,
              ),
            ],
          ),
        );
      },
    );
  }
}
