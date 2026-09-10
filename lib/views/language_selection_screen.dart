import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ads_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import '../widgets/common/game_button.dart';
import '../widgets/common/game_icon_button.dart';
import '../widgets/common/game_scaffold.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _tempSelectedLanguage;

  @override
  void initState() {
    super.initState();
    _tempSelectedLanguage = widget.currentLanguage;
    final currentLvl = GameStorage.getMaxUnlockedLevelIndex(widget.currentLanguage);
    AdsManager.showBanner('bottom', level: currentLvl + 1);
  }

  void _confirmSelection() async {
    if (_tempSelectedLanguage != widget.currentLanguage) {
      await GameStorage.setSelectedLanguage(_tempSelectedLanguage);
      widget.onLanguageSelected(_tempSelectedLanguage);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = LevelLoader.supportedLanguages;

    return GameScaffold(
      body: Column(
        children: [
          // Top Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              children: [
                GameIconButton.back(context),
                SizedBox(width: 14.w),
                Text(
                  'SELECT LANGUAGE',
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

            // Description Header
            // Language List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = lang == _tempSelectedLanguage;
                  final displayName = LevelLoader.languageDisplayNames[lang] ?? lang;
                  final maxUnlocked = GameStorage.getMaxUnlockedLevelIndex(lang) + 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _tempSelectedLanguage = lang;
                        });
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.cardPeachLight : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected ? AppColors.btnFaceBrown : AppColors.borderSubtle,
                            width: isSelected ? 2.0 : 1.5,
                          ),
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
                              width: 44.r,
                              height: 44.r,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                              ),
                              child: Center(
                                child: Text(
                                  displayName.split(' ').length > 1 ? displayName.split(' ').last : '🌐',
                                  style: TextStyle(fontSize: 22.sp),
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),

                            // Language Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName.split(' ').first,
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.sp,
                                      color: isSelected ? AppColors.headerBrown : AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Progress: Level $maxUnlocked',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12.sp,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Radio Check Indicator
                            Container(
                              width: 24.r,
                              height: 24.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.btnFaceBrown : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.btnFaceBrown : AppColors.borderSubtle,
                                  width: 2.0,
                                ),
                              ),
                              child: isSelected
                                   ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Confirm Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: GameButton.primary(
                size: GameButtonSize.large,
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                text: 'CONFIRM SELECTION',
                onTap: _confirmSelection,
              ),
            ),
            SizedBox(height: 55.h),
          ],
        ),
    );
  }
}
