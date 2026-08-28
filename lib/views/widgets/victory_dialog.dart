import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/game_controller.dart';
import '../../theme/app_theme.dart';

class VictoryOverlay extends StatefulWidget {
  final GameController controller;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;

  const VictoryOverlay({
    super.key,
    required this.controller,
    required this.onNextLevel,
    required this.onReplay,
  });

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        Container(
          color: Colors.black.withOpacity(0.55),
        ),

        // Confetti Explosion
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.terracotta,
              AppColors.goldAccent,
              AppColors.successGreen,
              Color(0xFFE27150),
              Color(0xFF2B2824),
            ],
          ),
        ),

        // Victory Card (Cozy Warm Paper Card with 2px Dark Border)
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.cardPeach,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderDark, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.borderDark.withOpacity(0.2),
                  offset: const Offset(0, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Title
                Text(
                  widget.controller.victoryCelebrationText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.terracotta,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Level ${widget.controller.levelNumber} Completed',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                // 3 Stars Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.star_rounded,
                        size: 52,
                        color: index < widget.controller.starsEarned
                            ? AppColors.goldAccent
                            : AppColors.borderDark.withOpacity(0.15),
                      ),
                    )
                        .animate(delay: (200 * index).ms)
                        .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut);
                  }),
                ),
                const SizedBox(height: 18),

                // Coins Reward Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderDark, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.12),
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${widget.controller.coinsReward}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('🪙', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons (Matching reference image "CONTINUE" button)
                Row(
                  children: [
                    // Replay Button
                    InkWell(
                      onTap: widget.onReplay,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardPeachLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderDark, width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.borderDark.withOpacity(0.15),
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.replay_rounded, size: 24, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Next Level Button
                    Expanded(
                      child: InkWell(
                        onTap: widget.onNextLevel,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderDark, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.borderDark.withOpacity(0.2),
                                offset: const Offset(0, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
        ),
      ],
    );
  }
}
