import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import '../utils/game_transitions.dart';
import '../widgets/common/game_button.dart';
import '../widgets/common/game_dialog.dart';
import '../widgets/common/game_icon_button.dart';
import '../widgets/common/game_scaffold.dart';
import 'game_screen.dart';
import 'language_selection_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/bouncy_button.dart';
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
      GamePageRoute(
        child: GameScreen(
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
      GamePageRoute(
        child: LevelSelectScreen(
          language: _language,
        ),
      ),
    ).then((_) => _loadState());
  }

  void _openSettings() {
    AudioManager.playTileSelect(pitchIndex: 4);
    Navigator.push(
      context,
      GamePageRoute(
        child: SettingsScreen(
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
      GamePageRoute(
        child: LanguageSelectionScreen(
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
    showGameDialog(
      context: context,
      builder: (context) => ShopDialog(
        onUpdated: () => _loadState(),
      ),
    );
  }

  Future<void> _handleExitAppConfirmation() async {
    AudioManager.playTileSelect(pitchIndex: 2);
    final shouldStay = await GameDialog.showConfirm(
      context,
      icon: '👋',
      title: 'Exit Game?',
      message: 'Are you sure you want to exit the app? Hope to see you back soon!',
      cancelText: 'Exit',
      confirmText: 'Stay',
    );

    if (shouldStay == false && mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
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

    return GameScaffold(
      onWillPop: () async {
        await _handleExitAppConfirmation();
        return false;
      },
      body: _isLoading
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
    );
  }

  Widget _buildTopBar(String langFlag, String langNameOnly) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BouncyButton(
          onTap: _openLanguageSelect,
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
            BouncyButton(
              onTap: _openShop,
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
            GameIconButton.settings(
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
    return BouncyButton(
      onTap: _openLevelSelect,
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
    return GameButton.primary(
      size: GameButtonSize.large,
      onTap: _playCurrentLevel,
      icon: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34.r),
      text: 'PLAY LEVEL $levelNumber',
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.03, 1.03),
          duration: 850.ms,
          curve: Curves.easeInOut,
        );
  }
}
