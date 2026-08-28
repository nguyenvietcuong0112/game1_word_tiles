import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../theme/app_theme.dart';

class BoosterBar extends StatelessWidget {
  final GameController controller;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenLevelSelect;

  const BoosterBar({
    super.key,
    required this.controller,
    this.onOpenShop,
    this.onOpenLevelSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final levelNum = controller.levelNumber;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Level Map Badge (Left)
              InkWell(
                onTap: onOpenLevelSelect,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderDark,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.15),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.terracotta, size: 18),
                          Text(
                            '$levelNum',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Middle Boosters (Hint 💡 & Rocket 🚀)
              Row(
                children: [
                  // Hint 💡
                  _buildCircularBooster(
                    icon: Icons.lightbulb_outline_rounded,
                    price: 80,
                    onTap: () => controller.useHint(),
                  ),
                  const SizedBox(width: 14),

                  // Rocket / Firework 🚀
                  _buildCircularBooster(
                    icon: Icons.rocket_launch_outlined,
                    price: 240,
                    onTap: () => controller.useRocket(),
                  ),
                ],
              ),

              // 3. Gift Box / Chest (Right)
              InkWell(
                onTap: onOpenShop,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderDark, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.15),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎁', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircularBooster({
    required IconData icon,
    required int price,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular button with 2px dark border
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cardPeachLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderDark,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.borderDark.withOpacity(0.15),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: AppColors.terracotta, size: 26),
            ),
          ),

          // Attached Terracotta Price Pill with 2px dark border
          Transform.translate(
            offset: const Offset(0, -6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderDark.withOpacity(0.15),
                    offset: const Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 8)),
                  const SizedBox(width: 2),
                  Text(
                    '$price',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
