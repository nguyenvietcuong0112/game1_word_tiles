import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../models/level_model.dart';
import '../../services/game_storage.dart';
import '../common/wood_widgets.dart';

class TargetWordsBar extends StatefulWidget {
  final GameController controller;

  const TargetWordsBar({super.key, required this.controller});

  @override
  State<TargetWordsBar> createState() => _TargetWordsBarState();
}

class _TargetWordsBarState extends State<TargetWordsBar> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollDown = false;
  bool _canScrollUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void didUpdateWidget(covariant TargetWordsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    final canDown = maxScroll > 8 && currentScroll < maxScroll - 8;
    final canUp = currentScroll > 8;

    if (canDown != _canScrollDown || canUp != _canScrollUp) {
      setState(() {
        _canScrollDown = canDown;
        _canScrollUp = canUp;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final words = widget.controller.level.targetWords;
        final maxLen = words.fold<int>(0, (maxVal, tw) => tw.word.length > maxVal ? tw.word.length : maxVal);
        final tutorialTargetWord = (!GameStorage.isTutorialCompleted() && widget.controller.levelNumber == 1 && !widget.controller.isWon)
            ? widget.controller.getNextUnsolvedTargetWord()
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());

            return Stack(
              alignment: Alignment.center,
              children: [
                // 1-Column Vertically Scrollable Viewport
                NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    _checkScroll();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: words.map((tw) {
                          final isSolved = widget.controller.solvedTargetWords.contains(tw.word);
                          final isTutorialTarget = !isSolved && tutorialTargetWord == tw.word;

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.5.h),
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
                  ),
                ),

                // Floating "More" Scroll Hint Pill on the Right Side (Non-overlapping)
                if (_canScrollDown)
                  Positioned(
                    bottom: 6.h,
                    right: 12.w,
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7EA),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: WoodenStyle.woodBevel, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: WoodenStyle.woodExtrusion,
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'More',
                              style: GoogleFonts.fredoka(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: WoodenStyle.carvedDark,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16.r,
                              color: WoodenStyle.carvedDark,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 600.ms),
                    ),
                  ),
              ],
            );
          },
        );
      },
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

    // Dynamic prominent sizing for single-column layout
    final double boxSize;
    if (word.length <= 3) {
      boxSize = 46.0.r;
    } else if (word.length == 4) {
      boxSize = 44.0.r;
    } else if (word.length == 5) {
      boxSize = 40.0.r;
    } else {
      boxSize = 36.0.r;
    }

    final double marginH = 2.2.w;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (index) {
        final char = word[index];

        if (isSolved) {
          return Container(
            width: boxSize,
            height: boxSize,
            margin: EdgeInsets.symmetric(horizontal: marginH),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: WoodenStyle.woodBevel, width: 1.6),
              boxShadow: const [
                BoxShadow(
                  color: WoodenStyle.woodExtrusion,
                  offset: Offset(0, 2.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            WoodenStyle.woodHighlight,
                            WoodenStyle.woodTop,
                            WoodenStyle.woodMid,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset(
                        'assets/images/golden_wood_texture.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        char,
                        style: GoogleFonts.fredoka(
                          fontSize: boxSize * 0.62,
                          fontWeight: FontWeight.w900,
                          color: WoodenStyle.carvedDark,
                          height: 1.0,
                          shadows: const [
                            Shadow(
                              color: WoodenStyle.carvedShadowLight,
                              offset: Offset(0, 1.2),
                            ),
                            Shadow(
                              color: Color(0xFF1F0900),
                              offset: Offset(0, -0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: (40 * index).ms)
              .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.0, 1.0), duration: 220.ms, curve: Curves.elasticOut)
              .shimmer(duration: 700.ms, color: Colors.white.withValues(alpha: 0.4));
        }

        // Unsolved slot: Recessed Dark Wood Groove Cavity
        return Container(
          width: boxSize,
          height: boxSize,
          margin: EdgeInsets.symmetric(horizontal: marginH),
          decoration: BoxDecoration(
            color: isTutorialTarget ? const Color(0xFF381401) : WoodenStyle.grooveDark,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isTutorialTarget ? WoodenStyle.woodTop : WoodenStyle.grooveBorder,
              width: isTutorialTarget ? 2.0 : 1.4,
            ),
            boxShadow: [
              if (isTutorialTarget)
                const BoxShadow(
                  color: Color(0x99F58A07),
                  blurRadius: 8,
                  spreadRadius: 1.5,
                ),
              const BoxShadow(
                color: Color(0x55000000),
                offset: Offset(0, 1.5),
                blurRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: isTutorialTarget ? 9.r : 7.r,
              height: isTutorialTarget ? 9.r : 7.r,
              decoration: BoxDecoration(
                color: isTutorialTarget ? WoodenStyle.woodTop : const Color(0xFF6B3A1C),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        );
      }),
    );
  }
}
