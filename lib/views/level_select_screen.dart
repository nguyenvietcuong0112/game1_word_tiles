import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ads_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import '../utils/game_transitions.dart';
import '../widgets/common/game_icon_button.dart';
import '../widgets/common/game_scaffold.dart';
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

    AdsManager.showBanner('bottom', level: _maxUnlockedIndex + 1);

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
        GamePageRoute(
          child: GameScreen(
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

    return GameScaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              children: [
                GameIconButton.back(context),
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
                            color: AppColors.headerBrown,
                          ),
                        ),
                        Text(
                          langName,
                          style: GoogleFonts.fredoka(
                            fontSize: 14.sp,
                            color: AppColors.subHeaderBrown,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stars Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFE8DAC8),
                          offset: Offset(0, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 4.w),
                        Text(
                          '${_starsMap.values.fold<int>(0, (sum, s) => sum + s)}',
                          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Coins Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFE8DAC8),
                          offset: Offset(0, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4.w),
                        Text(
                          '${GameStorage.getCoins()}',
                          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 14.sp),
                        ),
                      ],
                    ),
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
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 65.h),
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
    final theme = AppColors.getTileThemeForPosition(levelNumber ~/ 5, levelNumber % 5);

    final Color faceColor = isCurrent
        ? AppColors.btnFaceBrown
        : (isUnlocked ? theme.face : const Color(0xFFF2E8DC));

    final Color bevelColor = isCurrent
        ? AppColors.btnShadowBrown
        : (isUnlocked ? theme.bevel : const Color(0xFFDECFC0));

    final textColor = isCurrent ? Colors.white : (isUnlocked ? AppColors.textDark : AppColors.textMuted);

    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isCurrent ? AppColors.btnBorderBrown : (isUnlocked ? theme.bevel : const Color(0xFFDECFC0)),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: bevelColor,
              offset: const Offset(0, 2.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isUnlocked)
                const Icon(Icons.lock_rounded, size: 20, color: Color(0xFFA6907E))
              else ...[
                Text(
                  '$levelNumber',
                  style: GoogleFonts.fredoka(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.0,
                    shadows: isCurrent
                        ? const [
                            Shadow(
                              color: AppColors.btnShadowBrown,
                              offset: Offset(0, 1.5),
                            ),
                          ]
                        : null,
                  ),
                ),
                SizedBox(height: 4.h),
                // Stars (Reflects exact stars earned: 1, 2, or 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final hasStar = isUnlocked && (i < stars);
                    return Icon(
                      Icons.star_rounded,
                      size: 13.r,
                      color: hasStar
                          ? AppColors.honeyGold
                          : (isCurrent
                              ? Colors.white.withValues(alpha: 0.35)
                              : const Color(0xFFD6C8B8)),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
