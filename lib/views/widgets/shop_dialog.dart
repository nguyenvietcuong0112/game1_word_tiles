import 'package:flutter/material.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';

class ShopDialog extends StatefulWidget {
  final VoidCallback onUpdated;

  const ShopDialog({super.key, required this.onUpdated});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  void _claimFreeReward() async {
    await GameStorage.addCoins(100);
    await GameStorage.addHintCount(1);
    await GameStorage.addRocketCount(1);
    widget.onUpdated();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎁 Claimed Daily Gift: +100 🪙, +1 💡 Hint, +1 🚀 Rocket!')),
      );
    }
  }

  void _buyBoosterPack(String name, int coinsCost, int hints, int rockets) async {
    final success = await GameStorage.spendCoins(coinsCost);
    if (success) {
      await GameStorage.addHintCount(hints);
      await GameStorage.addRocketCount(rockets);
      widget.onUpdated();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✨ Purchased $name!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Not enough coins!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = GameStorage.getCoins();
    final hints = GameStorage.getHintCount();
    final rockets = GameStorage.getRocketCount();

    return AlertDialog(
      backgroundColor: AppColors.cardPeach,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderDark, width: 2.0),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Coin Shop & Gifts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardPeachLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark, width: 1.5),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text('$coins', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inventory preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardPeachLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.terracotta, size: 20),
                    const SizedBox(width: 6),
                    Text('$hints Hints', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ]),
                  Container(width: 1.5, height: 20, color: AppColors.borderDark.withOpacity(0.2)),
                  Row(children: [
                    const Icon(Icons.rocket_launch_outlined, color: AppColors.terracotta, size: 20),
                    const SizedBox(width: 6),
                    Text('$rockets Rockets', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Daily Free Gift Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardPeachLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderDark, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderDark.withOpacity(0.12),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Free Gift', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 14)),
                        Text('+100 🪙, +1 💡, +1 🚀', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _claimFreeReward,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Text(
                        'CLAIM',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Booster Pack 1
            _buildShopItem(
              title: 'Explorer Pack',
              desc: '3x 💡 Hints + 1x 🚀 Rocket',
              icon: '🎒',
              cost: 300,
              onBuy: () => _buyBoosterPack('Explorer Pack', 300, 3, 1),
            ),
            const SizedBox(height: 8),

            // Booster Pack 2
            _buildShopItem(
              title: 'Master Pack',
              desc: '8x 💡 Hints + 4x 🚀 Rockets',
              icon: '👑',
              cost: 800,
              onBuy: () => _buyBoosterPack('Master Pack', 800, 8, 4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildShopItem({
    required String title,
    required String desc,
    required String icon,
    required int cost,
    required VoidCallback onBuy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardPeachLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderDark.withOpacity(0.12),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textDark)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          InkWell(
            onTap: onBuy,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderDark.withOpacity(0.15),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$cost',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 3),
                  const Text('🪙', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
