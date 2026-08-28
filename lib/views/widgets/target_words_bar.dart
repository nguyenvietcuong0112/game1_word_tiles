import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/game_controller.dart';
import '../../models/level_model.dart';
import '../../theme/app_theme.dart';

class TargetWordsBar extends StatelessWidget {
  final GameController controller;

  const TargetWordsBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final words = controller.level.targetWords;

        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: words.map((tw) {
                final isSolved = controller.solvedTargetWords.contains(tw.word);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _TargetWordRow(
                    targetWord: tw,
                    isSolved: isSolved,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _TargetWordRow extends StatelessWidget {
  final TargetWord targetWord;
  final bool isSolved;

  const _TargetWordRow({
    required this.targetWord,
    required this.isSolved,
  });

  @override
  Widget build(BuildContext context) {
    final word = targetWord.word;
    const boxSize = 34.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (index) {
        final char = word[index];

        if (isSolved) {
          return Container(
            width: boxSize,
            height: boxSize,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.borderDark.withOpacity(0.18),
                  offset: const Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                char,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ).animate(delay: (50 * index).ms).scale(duration: 200.ms, curve: Curves.easeOutBack);
        }

        return Container(
          width: boxSize,
          height: boxSize,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: AppColors.cardPeachLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDark, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.borderDark.withOpacity(0.12),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
        );
      }),
    );
  }
}
