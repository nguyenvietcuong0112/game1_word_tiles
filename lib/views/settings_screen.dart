import 'package:flutter/material.dart';
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
    _sound = GameStorage.isSoundEnabled();
    _haptic = GameStorage.isHapticEnabled();
    _language = GameStorage.getLanguage();
  }

  void _resetProgress() async {
    final confirm = await GameDialog.showConfirm(
      context,
      icon: '⚠️',
      title: 'Reset Progress?',
      message: 'Are you sure you want to reset all progress for ${_language.toUpperCase()}?',
      cancelText: 'Cancel',
      confirmText: 'Reset',
      confirmVariant: GameButtonVariant.danger,
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
                Text(
                  'SETTINGS',
                  style: GoogleFonts.fredoka(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.headerBrown,
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
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(20.r),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          GamePageRoute(
                            child: LanguageSelectionScreen(
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
                            // Flag / Icon Box
                            Container(
                              width: 48.r,
                              height: 48.r,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
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
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    langSub,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12.sp,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action / Arrow 3D Button
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                color: AppColors.btnFaceBrown,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: AppColors.btnBorderBrown, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.btnShadowBrown,
                                    offset: Offset(0, 1.5),
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
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      decoration: BoxDecoration(
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
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text('Sound Effects', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15.sp)),
                            secondary: const Icon(Icons.volume_up_rounded, color: AppColors.textDark),
                            value: _sound,
                            activeThumbColor: AppColors.btnFaceBrown,
                            activeTrackColor: AppColors.btnRingBg,
                            onChanged: (val) async {
                              setState(() => _sound = val);
                              await GameStorage.setSoundEnabled(val);
                              AudioManager.syncSoundSettings();
                            },
                          ),
                          const Divider(color: AppColors.borderSubtle, height: 1),
                          SwitchListTile(
                            title: Text('Haptic Vibration', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15.sp)),
                            secondary: const Icon(Icons.vibration_rounded, color: AppColors.textDark),
                            value: _haptic,
                            activeThumbColor: AppColors.btnFaceBrown,
                            activeTrackColor: AppColors.btnRingBg,
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
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      decoration: BoxDecoration(
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
                      child: ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.btnFaceBrown),
                        title: Text('Reset Current Language Progress', style: GoogleFonts.fredoka(color: AppColors.btnFaceBrown, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        onTap: _resetProgress,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // About
                  Center(
                    child: Text(
                      'Word Tiles Casual Puzzle\nVersion 1.0.0',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(color: AppColors.textMuted, fontSize: 13.sp, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: AppColors.headerBrown,
        ),
      ),
    );
  }
}
