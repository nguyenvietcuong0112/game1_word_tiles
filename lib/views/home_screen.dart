import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ads_manager.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../utils/game_transitions.dart';
import 'widgets/exit_game_dialog.dart';
import '../widgets/common/game_scaffold.dart';
import 'game_screen.dart';
import 'widgets/bouncy_button.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/shop_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _language = 'english';
  int _currentLevelIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
    AudioManager.startBgm();
  }

  Future<void> _loadState() async {
    final lang = GameStorage.getSelectedLanguage();
    final count = LevelLoader.totalLevelsPerLanguage[lang] ?? 1000;
    final currentLvl = GameStorage.getMaxUnlockedLevelIndex(lang).clamp(0, count > 0 ? count - 1 : 0);

    if (mounted) {
      setState(() {
        _language = lang;
        _currentLevelIndex = currentLvl;
        _isLoading = false;
      });
    }

    AdsManager.showBanner('bottom', level: currentLvl + 1);
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

  void _openSettings() {
    AudioManager.playTileSelect(pitchIndex: 4);
    showGameDialog(
      context: context,
      builder: (context) => SettingsDialog(
        isHomeScreen: true,
        onLanguageChanged: () {
          _loadState();
        },
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
    ExitGameDialog.show(
      context,
      onExit: () {
        SystemNavigator.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelNumber = _currentLevelIndex + 1;

    return GameScaffold(
      useSafeArea: false,
      background: Image.asset(
        'assets/images/bg_home.webp',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
      ),
      onWillPop: () async {
        await _handleExitAppConfirmation();
        return false;
      },
      body: _isLoading
          ? const SizedBox.shrink()
          : SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  SizedBox(height: 0.1.sh), 
                  _buildLogo(),
                  const Spacer(),
                  _buildPlayButton(levelNumber),
                  SizedBox(height: 0.2.sh),
                ],
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCoinCapsule(),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildCoinCapsule() {
    return BouncyButton(
      onTap: _openShop,
      child: SizedBox(
        height: 44.h,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Dark royal blue pill container
            Container(
              margin: EdgeInsets.only(left: 18.w),
              height: 34.h,
              constraints: BoxConstraints(minWidth: 78.w),
              padding: EdgeInsets.only(left: 20.w, right: 14.w),
              decoration: BoxDecoration(
                color: const Color(0xFF26499D),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ValueListenableBuilder<int>(
                valueListenable: GameStorage.coinsNotifier,
                builder: (context, coins, _) {
                  return Text(
                    '$coins',
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  );
                },
              ),
            ),
            // Overlapping gold crown coin icon
            Image.asset(
              'assets/icons/icon_coin.webp',
              width: 44.r,
              height: 44.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return BouncyButton(
      onTap: _openSettings,
      child: Image.asset(
        'assets/icons/icon_setting.webp',
        width: 44.r,
        height: 44.r,
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo_home.webp',
      width: 300.w,
      fit: BoxFit.contain,
    );
  }

  Widget _buildPlayButton(int levelNumber) {
    return BouncyButton(
      onTap: _playCurrentLevel,
      child: SizedBox(
        width: 240.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/btn_yellow.webp',
              width: 240.w,
              fit: BoxFit.contain,
            ),
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Navy blue stroke
                      Text(
                        'Level $levelNumber',
                        style: GoogleFonts.fredoka(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 5.0
                            ..strokeCap = StrokeCap.round
                            ..strokeJoin = StrokeJoin.round
                            ..color = const Color(0xFF1B3D82),
                        ),
                      ),
                      // White fill
                      Text(
                        'Level $levelNumber',
                        style: GoogleFonts.fredoka(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
