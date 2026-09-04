import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import 'common/app_background.dart';
import 'common/wood_widgets.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const SettingsScreen({super.key, required this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound;
  late bool _haptic;
  late String _language;

  @override
  void initState() {
    super.initState();
    _sound = GameStorage.getSoundEnabled();
    _haptic = GameStorage.getHapticEnabled();
    _language = GameStorage.getSelectedLanguage();
  }

  void _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WoodenDialog(
        title: 'RESET PROGRESS?',
        onClose: () => Navigator.pop(ctx, false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Text(
              'Are you sure you want to reset all progress for ${_language.toUpperCase()}?',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: WoodenButton(
                    text: 'CANCEL',
                    variant: WoodenButtonVariant.action,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: WoodenButton(
                    text: 'RESET',
                    variant: WoodenButtonVariant.alert,
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await GameStorage.resetLanguageProgress(_language);
      if (mounted) {
        widget.onLanguageChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullLang = LevelLoader.languageDisplayNames[_language] ?? _language;
    final parts = fullLang.split(' ');
    final flag = parts.length > 1 ? parts.last : '🌐';
    final langName = parts.first;
    const langSub = 'Tap to change language';

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
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.fredoka(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: WoodenStyle.woodExtrusion,
                            offset: Offset(0, 2),
                            blurRadius: 1,
                          ),
                          Shadow(
                            color: Color(0xFF1F0900),
                            offset: Offset(0, 3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20.w),
                  children: [
                    // Language Selection
                    _buildSectionHeader('GAME LANGUAGE'),
                    _buildWoodCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LanguageSelectionScreen(
                              currentLanguage: _language,
                              onLanguageSelected: (newLang) {
                                setState(() => _language = newLang);
                                widget.onLanguageChanged();
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        child: Row(
                          children: [
                            // Flag / Icon Box
                            Container(
                              width: 48.r,
                              height: 48.r,
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
                                border: Border.all(color: GoldenWoodColors.woodHighlight, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: GoldenWoodColors.woodExtrusion,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(flag, style: TextStyle(fontSize: 26.sp)),
                              ),
                            ),
                            SizedBox(width: 14.w),

                            // Language Names
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langName,
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.sp,
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
                                  SizedBox(height: 2.h),
                                  Text(
                                    langSub,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12.sp,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w600,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xFF1F0900),
                                          offset: Offset(0, 1.0),
                                          blurRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action / Arrow 3D Button
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF5A2508),
                                    Color(0xFF381401),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: GoldenWoodColors.woodHighlight, width: 1.4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: GoldenWoodColors.woodExtrusion,
                                    offset: Offset(0, 1.8),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CHANGE',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFD868),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: Color(0xFFFFD868),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Audio & Haptics
                    _buildSectionHeader('AUDIO & FEEDBACK'),
                    _buildWoodCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Sound Effects',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 15.sp,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF1F0900),
                                    offset: Offset(0, 1.2),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            secondary: Image.asset(
                              WoodGameIcons.btnSound,
                              width: 36.r,
                              height: 36.r,
                              fit: BoxFit.contain,
                            ),
                            value: _sound,
                            activeThumbColor: const Color(0xFF67DC34),
                            activeTrackColor: const Color(0xFF381401),
                            inactiveThumbColor: const Color(0xFFC7AF96),
                            inactiveTrackColor: const Color(0xFF5C3318),
                            onChanged: (val) async {
                              setState(() => _sound = val);
                              await GameStorage.setSoundEnabled(val);
                              AudioManager.syncSoundSettings();
                            },
                          ),
                          Divider(
                            color: GoldenWoodColors.woodBevel.withValues(alpha: 0.35),
                            height: 1,
                            indent: 16.w,
                            endIndent: 16.w,
                          ),
                          SwitchListTile(
                            title: Text(
                              'Haptic Vibration',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 15.sp,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF1F0900),
                                    offset: Offset(0, 1.2),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            secondary: Image.asset(
                              WoodGameIcons.btnVibrate,
                              width: 36.r,
                              height: 36.r,
                              fit: BoxFit.contain,
                            ),
                            value: _haptic,
                            activeThumbColor: const Color(0xFF67DC34),
                            activeTrackColor: const Color(0xFF381401),
                            inactiveThumbColor: const Color(0xFFC7AF96),
                            inactiveTrackColor: const Color(0xFF5C3318),
                            onChanged: (val) async {
                              setState(() => _haptic = val);
                              await GameStorage.setHapticEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Reset Progress
                    _buildSectionHeader('DATA MANAGEMENT'),
                    _buildWoodCard(
                      onTap: _resetProgress,
                      borderColor: const Color(0xFFB53828),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        child: Row(
                          children: [
                            Container(
                              width: 42.r,
                              height: 42.r,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFE03020),
                                    Color(0xFF8B1208),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color(0xFFFF9285), width: 1.4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF4E0A04),
                                    offset: Offset(0, 1.8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Text(
                                'Reset Current Language Progress',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.sp,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF1F0900),
                                      offset: Offset(0, 1.2),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // About
                    Center(
                      child: Text(
                        'Word Tiles Casual Puzzle\nVersion 1.0.0',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13.sp,
                          height: 1.5,
                          shadows: const [
                            Shadow(
                              color: WoodenStyle.woodExtrusion,
                              offset: Offset(0, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWoodCard({
    required Widget child,
    VoidCallback? onTap,
    Color? borderColor,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: borderColor ?? GoldenWoodColors.woodBevel,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: GoldenWoodColors.woodExtrusion,
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 5),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Stack(
          children: [
            // Golden Honey Oak Wood Gradient
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
            // Real Wood Grain Texture
            Positioned.fill(
              child: Opacity(
                opacity: 0.32,
                child: Image.asset(
                  'assets/images/golden_wood_texture.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Top Specular Highlight Rim
            Positioned(
              top: 0,
              left: 10,
              right: 10,
              height: 1.5,
              child: Container(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            // Content
            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: card,
        ),
      );
    }
    return card;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 13.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
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
    );
  }
}
