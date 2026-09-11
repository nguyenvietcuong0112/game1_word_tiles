import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/ads_manager.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_typography.dart';
import '../utils/game_transitions.dart';
import 'widgets/exit_game_dialog.dart';
import '../widgets/common/game_scaffold.dart';
import 'game_screen.dart';
import 'widgets/bouncy_button.dart';
import 'widgets/pressable_3d_button.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/shop_dialog.dart';

class HomeScreen extends StatefulWidget {
  final bool isFirstSessionStart;

  const HomeScreen({
    super.key,
    this.isFirstSessionStart = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  String _language = 'english';
  int _currentLevelIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState(showBanner: !widget.isFirstSessionStart);
    AudioManager.startBgm();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadState(showBanner: true);
    AudioManager.resumeBgm();
  }

  Future<void> _loadState({bool showBanner = true}) async {
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

    if (showBanner) {
      AdsManager.showBanner('bottom', level: currentLvl + 1);
    }
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
                color: const Color(0xFF000000).withValues(alpha: 0.1),
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
    return Pressable3DButton(
      onTap: _playCurrentLevel,
      width: 240.w,
      height: 90.h,
      borderRadius: 22,
      bevelOffset: 5.0,
      borderWidth: 1.2,
      faceColor: const Color(0xFF46dc28),
      bevelColor: const Color(0xFF2DC419),
      borderColor: const Color(0xFF19BA05),
      child: CartoonText(
        text: 'Level $levelNumber',
        fontSize: 32.sp,
        textColor: Colors.white,
        outlineColor: const Color(0xFF179A09),
        strokeWidth: 4.5,
        shadowOffset: 2.0,
      ),
    );
  }
}
