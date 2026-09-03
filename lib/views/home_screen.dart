import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'language_selection_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/shop_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _coins = 0;
  String _language = 'english';
  int _currentLevelIndex = 0;
  int _totalStars = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
    AudioManager.startBgm();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);

    final coins = GameStorage.getCoins();
    final lang = GameStorage.getSelectedLanguage();
    final count = LevelLoader.totalLevelsPerLanguage[lang] ?? 1000;
    final currentLvl = GameStorage.getMaxUnlockedLevelIndex(lang).clamp(0, count > 0 ? count - 1 : 0);
    final starsMap = GameStorage.getLevelStars(lang);
    final totalStars = starsMap.values.fold<int>(0, (sum, s) => sum + s);

    setState(() {
      _coins = coins;
      _language = lang;
      _currentLevelIndex = currentLvl;
      _totalStars = totalStars;
      _isLoading = false;
    });
  }

  void _playCurrentLevel() {
    AudioManager.playTileSelect(pitchIndex: 3);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          language: _language,
          levelIndex: _currentLevelIndex,
        ),
      ),
    ).then((_) => _loadState());
  }

  void _openLevelSelect() {
    AudioManager.playTileSelect(pitchIndex: 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelSelectScreen(
          language: _language,
        ),
      ),
    ).then((_) => _loadState());
  }

  void _openSettings() {
    AudioManager.playTileSelect(pitchIndex: 4);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onLanguageChanged: () {
            _loadState();
          },
        ),
      ),
    ).then((_) => _loadState());
  }

  void _openLanguageSelect() {
    AudioManager.playTileSelect(pitchIndex: 3);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageSelectionScreen(
          currentLanguage: _language,
          onLanguageSelected: (newLang) {
            _loadState();
          },
        ),
      ),
    ).then((_) => _loadState());
  }

  void _openShop() {
    AudioManager.playTileSelect(pitchIndex: 4);
    showDialog(
      context: context,
      builder: (context) => ShopDialog(
        onUpdated: () => _loadState(),
      ),
    );
  }

  Future<void> _handleExitAppConfirmation() async {
    AudioManager.playTileSelect(pitchIndex: 2);
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: AppColors.borderSubtle, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFE8DAC8),
                offset: Offset(0, 4.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: AppColors.butterCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFFCD34D),
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 28)),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Exit Game?',
                style: GoogleFonts.fredoka(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to exit the app? Hope to see you back soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        AudioManager.playTileSelect(pitchIndex: 1);
                        Navigator.of(ctx).pop(true);
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.cardPeachLight,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFE8DAC8),
                              offset: Offset(0, 2.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Exit',
                            style: GoogleFonts.fredoka(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.headerBrown,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () {
                        AudioManager.playBooster();
                        Navigator.of(ctx).pop(false);
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFCA9370),
                              AppColors.btnFaceBrown,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.btnBorderBrown, width: 1.8),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.btnShadowBrown,
                              offset: Offset(0, 2.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Stay',
                            style: GoogleFonts.fredoka(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldExit == true) {
      // ignore: use_build_context_synchronously
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        // App termination logic
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langName = LevelLoader.languageDisplayNames[_language] ?? _language;
    final langParts = langName.split(' ');
    final langFlag = langParts.length > 1 ? langParts.last : '🌐';
    final langNameOnly = langParts.first;

    final levelNumber = _currentLevelIndex + 1;
    final nextMilestone = ((levelNumber ~/ 10) + 1) * 10;
    final progressInMilestone = (levelNumber % 10) / 10.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExitAppConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Stack(
          children: [
            _buildAmbientBackground(),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      child: Column(
                        children: [
                          _buildTopBar(langFlag, langNameOnly),
                          const Spacer(flex: 1),
                          _buildHeroLogo(),
                          const Spacer(flex: 1),
                          _buildProgressCard(
                            levelNumber,
                            nextMilestone,
                            progressInMilestone,
                            langNameOnly,
                            langFlag,
                          ),
                          const Spacer(flex: 2),
                          _buildPlayButton(levelNumber),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String langFlag, String langNameOnly) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: _openLanguageSelect,
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(22.r),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(langFlag, style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 6.w),
                Text(
                  langNameOnly,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(width: 4.w),
                const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.terracotta),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _openShop,
              borderRadius: BorderRadius.circular(22.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(22.r),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪙', style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 6.w),
                    Text(
                      '$_coins',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            InkWell(
              onTap: _openSettings,
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                width: 44.r,
                height: 44.r,
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
                padding: EdgeInsets.all(4.w),
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
                  child: const Center(
                    child: Icon(Icons.settings_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.5.h),
          decoration: BoxDecoration(
            color: AppColors.cardPeachLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          ),
          child: Text(
            '✨ WOODCRAFT WORD TILES ✨',
            style: GoogleFonts.fredoka(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.headerBrown,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['W', 'O', 'R', 'D'].asMap().entries.map((e) {
            final isHighlight = e.key == 0;
            return _buildWoodLogoTile(
              e.value,
              isHighlight: isHighlight,
            );
          }).toList(),
        ),
        SizedBox(height: 7.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['T', 'I', 'L', 'E', 'S'].asMap().entries.map((e) {
            final isHighlight = e.key == 0;
            return _buildWoodLogoTile(
              e.value,
              isHighlight: isHighlight,
              isSmaller: true,
            );
          }).toList(),
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildWoodLogoTile(String letter, {bool isHighlight = false, bool isSmaller = false}) {
    final size = isSmaller ? 42.0.r : 48.0.r;
    final bgColor = isHighlight ? AppColors.btnFaceBrown : AppColors.cardWhite;
    final borderColor = isHighlight ? AppColors.btnBorderBrown : AppColors.borderSubtle;
    final bevelColor = isHighlight ? AppColors.btnShadowBrown : const Color(0xFFDEC5AE);
    final textColor = isHighlight ? Colors.white : AppColors.headerBrown;

    return Container(
      width: size,
      height: size + 2.h,
      margin: EdgeInsets.symmetric(horizontal: 3.5.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: bevelColor,
            offset: const Offset(0, 2.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.fredoka(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    int levelNumber,
    int nextMilestone,
    double progressInMilestone,
    String langNameOnly,
    String langFlag,
  ) {
    return InkWell(
      onTap: _openLevelSelect,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.borderSubtle, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE8DAC8),
              offset: Offset(0, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Milestone Trophy Icon Box
                Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    color: AppColors.btnRingBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderSubtle, width: 1.8),
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 24)),
                  ),
                ),
                SizedBox(width: 14.w),

                // Level Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level $levelNumber',
                            style: GoogleFonts.fredoka(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Goal: Level $nextMilestone',
                            style: GoogleFonts.fredoka(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.headerBrown,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$langFlag $langNameOnly • ⭐ $_totalStars Stars',
                        style: GoogleFonts.fredoka(
                          fontSize: 12.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.headerBrown),
              ],
            ),
            SizedBox(height: 14.h),

            // Progress Bar to Next Milestone
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Stack(
                children: [
                  Container(
                    height: 10.h,
                    width: double.infinity,
                    color: AppColors.cardPeachLight,
                  ),
                  FractionallySizedBox(
                    widthFactor: progressInMilestone == 0.0 ? 1.0 : progressInMilestone,
                    child: Container(
                      height: 10.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(int levelNumber) {
    return InkWell(
      onTap: _playCurrentLevel,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFCA9370),
              AppColors.btnFaceBrown,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: AppColors.btnBorderBrown, width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.btnShadowBrown,
              offset: Offset(0, 3.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34.r),
            SizedBox(width: 8.w),
            Text(
              'PLAY LEVEL $levelNumber',
              style: GoogleFonts.fredoka(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.8,
                shadows: const [
                  Shadow(
                    color: AppColors.btnShadowBrown,
                    offset: Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.03, 1.03),
          duration: 850.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildAmbientBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _BackgroundTilesPainter(),
        ),
      ),
    );
  }
}

class _BackgroundTilesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final positions = [
      Offset(size.width * 0.12, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.18),
      Offset(size.width * 0.10, size.height * 0.55),
      Offset(size.width * 0.88, size.height * 0.62),
      Offset(size.width * 0.22, size.height * 0.88),
      Offset(size.width * 0.78, size.height * 0.90),
    ];

    final paint = Paint()
      ..color = const Color(0xFFDEC5AE).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFDEC5AE).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final pos in positions) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pos,
          width: 44,
          height: 44,
        ),
        const Radius.circular(14),
      );

      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
