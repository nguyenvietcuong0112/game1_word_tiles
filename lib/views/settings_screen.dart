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
                    Material(
                      color: const Color(0xFF381401),
                      borderRadius: BorderRadius.circular(20.r),
                      child: InkWell(
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
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF381401),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: WoodenStyle.woodBevel, width: 2.0),
                            boxShadow: const [
                              BoxShadow(
                                color: WoodenStyle.woodExtrusion,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Flag / Icon Box
                              Container(
                                width: 48.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF230C00),
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: WoodenStyle.woodBevel, width: 1.5),
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
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action / Arrow 3D Button
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                                decoration: BoxDecoration(
                                  color: WoodenStyle.woodTop,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: WoodenStyle.woodExtrusion, width: 1.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: WoodenStyle.woodExtrusion,
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
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
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
                    SizedBox(height: 24.h),

                    // Audio & Haptics
                    _buildSectionHeader('AUDIO & FEEDBACK'),
                    Material(
                      color: const Color(0xFF381401),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF381401),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: WoodenStyle.woodBevel, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: WoodenStyle.woodExtrusion,
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                'Sound Effects',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
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
                                width: 34.r,
                                height: 34.r,
                                fit: BoxFit.contain,
                              ),
                              value: _sound,
                              activeThumbColor: WoodenStyle.woodHighlight,
                              activeTrackColor: WoodenStyle.woodDark,
                              inactiveThumbColor: const Color(0xFF8A6550),
                              inactiveTrackColor: const Color(0xFF230C00),
                              onChanged: (val) async {
                                setState(() => _sound = val);
                                await GameStorage.setSoundEnabled(val);
                                AudioManager.syncSoundSettings();
                              },
                            ),
                            const Divider(color: Color(0xFF5D2D0C), height: 1, indent: 16, endIndent: 16),
                            SwitchListTile(
                              title: Text(
                                'Haptic Vibration',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
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
                                width: 34.r,
                                height: 34.r,
                                fit: BoxFit.contain,
                              ),
                              value: _haptic,
                              activeThumbColor: WoodenStyle.woodHighlight,
                              activeTrackColor: WoodenStyle.woodDark,
                              inactiveThumbColor: const Color(0xFF8A6550),
                              inactiveTrackColor: const Color(0xFF230C00),
                              onChanged: (val) async {
                                setState(() => _haptic = val);
                                await GameStorage.setHapticEnabled(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Reset Progress
                    _buildSectionHeader('DATA MANAGEMENT'),
                    Material(
                      color: const Color(0xFF381401),
                      borderRadius: BorderRadius.circular(20.r),
                      child: InkWell(
                        onTap: _resetProgress,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF381401),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: GoldenWoodColors.rubyTop.withValues(alpha: 0.7), width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: WoodenStyle.woodExtrusion,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: GoldenWoodColors.rubyTop.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: GoldenWoodColors.rubyTop.withValues(alpha: 0.5), width: 1.2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.delete_forever_rounded, color: GoldenWoodColors.rubyTop, size: 22),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Text(
                                  'Reset Current Language Progress',
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
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
              color: WoodenStyle.woodExtrusion,
              offset: Offset(0, 1.5),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
