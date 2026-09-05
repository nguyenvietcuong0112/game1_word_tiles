import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import 'common/app_background.dart';
import 'common/wood_widgets.dart';
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
      builder: (ctx) => WoodSignboardDialog(
        title: 'WANT TO EXIT?',
        onClose: () => Navigator.of(ctx).pop(false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Text(
              'Are you sure you want to exit the app?',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFE8CC),
                height: 1.35,
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: WoodCtaButton(
                    text: 'YES',
                    isGreen: true,
                    onTap: () {
                      AudioManager.playTileSelect(pitchIndex: 1);
                      Navigator.of(ctx).pop(true);
                    },
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: WoodCtaButton(
                    text: 'NO',
                    onTap: () {
                      AudioManager.playBooster();
                      Navigator.of(ctx).pop(false);
                    },
                  ),
                ),
              ],
            ),
          ],
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
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
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
        ),
      ),
    );
  }

  Widget _buildTopBar(String langFlag, String langNameOnly) {
    final double headerHeight = 44.h;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: _openLanguageSelect,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            height: headerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: WoodenStyle.woodBevel, width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: WoodenStyle.woodExtrusion,
                  offset: Offset(0, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
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
                            GoldenWoodColors.woodHighlight,
                            GoldenWoodColors.woodTop,
                            GoldenWoodColors.woodMid,
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
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 8,
                    right: 8,
                    height: 1.2,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(langFlag, style: TextStyle(fontSize: 18.sp)),
                        SizedBox(width: 6.w),
                        Text(
                          langNameOnly,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.sp,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF1F0900),
                                offset: Offset(0, 1.2),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WoodenCurrency(
              coins: _coins,
              onTap: _openShop,
              height: headerHeight,
            ),
            SizedBox(width: 10.w),
            WoodCarvedIconButton(
              size: headerHeight,
              assetPath: WoodGameIcons.btnSettings,
              onTap: _openSettings,
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
        Text(
          '✨ CASUAL WORD PUZZLE ✨',
          style: GoogleFonts.fredoka(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: WoodenStyle.carvedDark,
            shadows: const [
              Shadow(
                color: WoodenStyle.carvedShadowLight,
                offset: Offset(0, 1.2),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['W', 'O', 'R', 'D'].map((letter) {
            return _buildWoodLogoTile(letter, size: 52.r);
          }).toList(),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['T', 'I', 'L', 'E', 'S'].map((letter) {
            return _buildWoodLogoTile(letter, size: 46.r);
          }).toList(),
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildWoodLogoTile(String letter, {required double size}) {
    final double radius = size * 0.26;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.5.w),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF6B2B04),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF421500),
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x35000000),
            offset: Offset(0, 5),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.88),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rich Golden Honey Oak Plank Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFD868),
                      Color(0xFFF3942B),
                      Color(0xFFD97213),
                      Color(0xFFAC4B04),
                    ],
                  ),
                ),
              ),
            ),
            // Subtle Wood Grain Texture
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  'assets/images/golden_wood_texture.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Specular Highlight Rim on top edge
            Positioned(
              top: 0,
              left: 6,
              right: 6,
              height: 1.5,
              child: Container(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            // Carved Letter with 3D Depth
            Center(
              child: Text(
                letter,
                style: GoogleFonts.fredoka(
                  fontSize: size * 0.58,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF5A1C00),
                      offset: Offset(0, 2.0),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: Color(0xFF2E0C00),
                      offset: Offset(0, 3.5),
                      blurRadius: 1,
                    ),
                    Shadow(
                      color: Color(0x44000000),
                      offset: Offset(0, 5.0),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: WoodenStyle.woodBevel, width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: WoodenStyle.woodExtrusion,
              offset: Offset(0, 4.0),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 8),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.8.r),
          child: Stack(
            children: [
              // Rich Golden Honey Oak Wood Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFD868),
                        Color(0xFFF3942B),
                        Color(0xFFD97213),
                        Color(0xFFAC4B04),
                      ],
                    ),
                  ),
                ),
              ),
              // Subtle Wood Grain Texture
              Positioned.fill(
                child: Opacity(
                  opacity: 0.32,
                  child: Image.asset(
                    'assets/images/golden_wood_texture.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Top Highlight Rim
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                height: 1.5,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(18.r),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Milestone Trophy Icon Box (Squircle Carved Wooden Tile)
                        Container(
                          width: 50.r,
                          height: 50.r,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF5A2508),
                                Color(0xFF381401),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: GoldenWoodColors.woodHighlight, width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: GoldenWoodColors.woodExtrusion,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: WoodGameIcons.trophy(size: 28.r),
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
                                      fontSize: 19.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xFF1F0900),
                                          offset: Offset(0, 1.5),
                                          blurRadius: 1,
                                        ),
                                        Shadow(
                                          color: Color(0x66000000),
                                          offset: Offset(0, 2.5),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A1E05),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: const Color(0xFF8C3E08), width: 1.2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Goal: Level $nextMilestone',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '$langFlag $langNameOnly • ⭐ $_totalStars Stars',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12.5.sp,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF1F0900),
                                      offset: Offset(0, 1.2),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Forward Arrow Button (Squircle Carved Wooden Block)
                        Container(
                          width: 30.r,
                          height: 30.r,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF5A2508),
                                Color(0xFF381401),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(9.r),
                            border: Border.all(color: GoldenWoodColors.woodHighlight, width: 1.4),
                            boxShadow: const [
                              BoxShadow(
                                color: GoldenWoodColors.woodExtrusion,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: Color(0xFFFFD868),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Progress Bar to Next Milestone
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(int levelNumber) {
    return WoodenButton(
      text: 'PLAY LEVEL $levelNumber',
      textColor: Colors.white,
      variant: WoodenButtonVariant.primary,
      height: 64.h,
      fontSize: 22.sp,
      onTap: _playCurrentLevel,
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.03, 1.03),
          duration: 850.ms,
          curve: Curves.easeInOut,
        );
  }
}
