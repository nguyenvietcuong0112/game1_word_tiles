import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import 'common/app_background.dart';
import 'common/wood_widgets.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final String language;
  final bool isFromGame;

  const LevelSelectScreen({
    super.key,
    required this.language,
    this.isFromGame = false,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  List<int> _levelIds = [];
  bool _isLoading = true;
  int _maxUnlockedIndex = 0;
  Map<int, int> _starsMap = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() => _isLoading = true);
    _levelIds = await LevelLoader.loadLevelList(widget.language);
    _maxUnlockedIndex = GameStorage.getMaxUnlockedLevelIndex(widget.language);
    _starsMap = GameStorage.getLevelStars(widget.language);

    setState(() => _isLoading = false);

    // Scroll to currently unlocked level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _maxUnlockedIndex > 10) {
        final row = _maxUnlockedIndex ~/ 5;
        final targetOffset = row * 84.0.h;
        _scrollController.jumpTo(targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  void _openLevel(int index, int levelId) {
    if (index > _maxUnlockedIndex) {
      return;
    }

    if (widget.isFromGame) {
      Navigator.of(context).pop(index);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            language: widget.language,
            levelIndex: index,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langName = LevelLoader.languageDisplayNames[widget.language] ?? widget.language;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  WoodCarvedIconButton(
                    size: 44.r,
                    assetPath: WoodGameIcons.btnBack,
                    onTap: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT LEVEL',
                          style: GoogleFonts.fredoka(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: WoodenStyle.carvedDark,
                          ),
                        ),
                        Text(
                          langName,
                          style: GoogleFonts.fredoka(
                            fontSize: 14.sp,
                            color: const Color(0xFF7A4A28),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total Stars Pill
                  // Container(
                  //   padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFFFFF7EA),
                  //     borderRadius: BorderRadius.circular(20.r),
                  //     border: Border.all(color: WoodenStyle.woodBevel, width: 1.5),
                  //     boxShadow: const [
                  //       BoxShadow(
                  //         color: WoodenStyle.woodExtrusion,
                  //         offset: Offset(0, 1.8),
                  //         blurRadius: 0,
                  //       ),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       WoodenStar(isEarned: true, size: 18.r),
                  //       SizedBox(width: 4.w),
                  //       Text(
                  //         '${_starsMap.values.fold<int>(0, (sum, s) => sum + s)}',
                  //         style: GoogleFonts.fredoka(
                  //           fontWeight: FontWeight.w900,
                  //           color: WoodenStyle.carvedDark,
                  //           fontSize: 14.sp,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // SizedBox(width: 8.w),

                  // Coins Counter
                  WoodenCurrency(
                    coins: GameStorage.getCoins(),
                  ),
                ],
              ),
            ),

            // Level Grid (Matching Reference Screenshot Card Style)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 0.84,
                      ),
                      itemCount: _levelIds.length,
                      itemBuilder: (context, index) {
                        final levelId = _levelIds[index];
                        final isUnlocked = index <= _maxUnlockedIndex;
                        final isCurrent = index == _maxUnlockedIndex;
                        final stars = _starsMap[levelId] ?? 0;

                        return _LevelCard(
                          levelNumber: index + 1,
                          isUnlocked: isUnlocked,
                          isCurrent: isCurrent,
                          stars: stars,
                          onTap: () => _openLevel(index, levelId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _LevelCard extends StatelessWidget {
  final int levelNumber;
  final bool isUnlocked;
  final bool isCurrent;
  final int stars;
  final VoidCallback onTap;

  const _LevelCard({
    required this.levelNumber,
    required this.isUnlocked,
    required this.isCurrent,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isCurrent
                ? WoodenStyle.woodExtrusion
                : (isUnlocked ? WoodenStyle.woodBevel : const Color(0xFFD4C2AE)),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrent
                  ? WoodenStyle.woodExtrusion
                  : (isUnlocked ? WoodenStyle.woodExtrusion : const Color(0xFFC7B5A0)),
              offset: const Offset(0, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Base Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isCurrent
                          ? const [
                              WoodenStyle.woodHighlight,
                              WoodenStyle.woodTop,
                              WoodenStyle.woodMid,
                            ]
                          : (isUnlocked
                              ? const [Color(0xFFFFF7EA), Color(0xFFF3DFBE), Color(0xFFE2C498)]
                              : const [Color(0xFFF0E5D8), Color(0xFFE2D4C4)]),
                    ),
                  ),
                ),
              ),

              // Wood Grain Texture Overlay
              if (isUnlocked)
                Positioned.fill(
                  child: Opacity(
                    opacity: isCurrent ? 0.38 : 0.22,
                    child: Image.asset(
                      'assets/images/golden_wood_texture.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // Center Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isUnlocked)
                    Image.asset(
                      WoodGameIcons.btnLock,
                      width: 24.r,
                      height: 24.r,
                      fit: BoxFit.contain,
                    )
                  else ...[
                    Text(
                      '$levelNumber',
                      style: GoogleFonts.fredoka(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isCurrent ? const Color(0xFFAEF82C) : WoodenStyle.carvedDark,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: isCurrent ? WoodenStyle.woodExtrusion : WoodenStyle.carvedShadowLight,
                            offset: const Offset(0, 1.2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Stars (Reflects exact stars earned: 1, 2, or 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final hasStar = isUnlocked && (i < stars);
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 1.w),
                          child: WoodenStar(
                            isEarned: hasStar,
                            size: 13.r,
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
