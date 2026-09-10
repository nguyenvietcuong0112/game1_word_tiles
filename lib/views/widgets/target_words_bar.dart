import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../models/level_model.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';

class TargetWordsBar extends StatefulWidget {
  final GameController controller;

  const TargetWordsBar({super.key, required this.controller});

  @override
  State<TargetWordsBar> createState() => _TargetWordsBarState();
}

class _TargetWordsBarState extends State<TargetWordsBar> {
  int _lastSolvedCount = 0;
  bool _lastIsWon = false;

  @override
  void initState() {
    super.initState();
    _lastSolvedCount = widget.controller.solvedTargetWords.length;
    _lastIsWon = widget.controller.isWon;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant TargetWordsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _lastSolvedCount = widget.controller.solvedTargetWords.length;
      _lastIsWon = widget.controller.isWon;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final solvedCount = widget.controller.solvedTargetWords.length;
    final isWon = widget.controller.isWon;
    if (solvedCount != _lastSolvedCount || isWon != _lastIsWon) {
      _lastSolvedCount = solvedCount;
      _lastIsWon = isWon;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final words = controller.level.targetWords;
    final maxLen = words.fold<int>(0, (maxVal, tw) => tw.word.length > maxVal ? tw.word.length : maxVal);
    final tutorialTargetWord = (!GameStorage.isTutorialCompleted() &&
            controller.levelNumber == 1 &&
            !controller.isWon &&
            controller.solvedTargetWords.length < 2)
        ? controller.getNextUnsolvedTargetWord()
        : null;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: words.map((tw) {
            final isSolved = controller.solvedTargetWords.contains(tw.word);
            final isTutorialTarget = !isSolved && tutorialTargetWord == tw.word;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: words.length > 4 ? 2.0.h : 2.5.h),
              child: _TargetWordRow(
                targetWord: tw,
                isSolved: isSolved,
                isTutorialTarget: isTutorialTarget,
                maxWordLength: maxLen,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TargetWordRow extends StatelessWidget {
  final TargetWord targetWord;
  final bool isSolved;
  final bool isTutorialTarget;
  final int maxWordLength;

  const _TargetWordRow({
    required this.targetWord,
    required this.isSolved,
    required this.isTutorialTarget,
    required this.maxWordLength,
  });

  @override
  Widget build(BuildContext context) {
    final word = targetWord.word;

    // Dynamic prominent sizing based on word length
    final double boxSize;
    if (word.length <= 4) {
      boxSize = 52.0.r;
    } else if (word.length == 5) {
      boxSize = 47.0.r;
    } else if (word.length == 6) {
      boxSize = 43.0.r;
    } else {
      boxSize = 39.0.r;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (index) {
        final char = word[index];

        if (isSolved) {
          return Container(
            width: boxSize,
            height: boxSize,
            margin: EdgeInsets.symmetric(horizontal: 1.5.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.terracottaLight, AppColors.btnFaceBrown],
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.btnBorderBrown, width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.btnShadowBrown,
                  offset: Offset(0, 2.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  char,
                  style: GoogleFonts.fredoka(
                    fontSize: boxSize * 0.62,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF6B3818).withValues(alpha: 0.8),
                        offset: const Offset(0, 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate(delay: (50 * index).ms)
              .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.0, 1.0), duration: 250.ms, curve: Curves.elasticOut)
              .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.4));
        }

        return Container(
          width: boxSize,
          height: boxSize,
          margin: EdgeInsets.symmetric(horizontal: 1.5.w),
          decoration: BoxDecoration(
            color: isTutorialTarget ? const Color(0xFFFFF9F0) : const Color(0xFFF6E7D8),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isTutorialTarget ? AppColors.btnFaceBrown : const Color(0xFFDEC5AE),
              width: isTutorialTarget ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (isTutorialTarget)
                const BoxShadow(
                  color: Color(0x55BA805D),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              const BoxShadow(
                color: Color(0xFFDEC5AE),
                offset: Offset(0, 2.0),
                blurRadius: 0,
              ),
            ],
          ),
        );
      }),
    );
  }
}
