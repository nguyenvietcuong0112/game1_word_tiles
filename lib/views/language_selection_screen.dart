import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';

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

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  // 3D Cocoa-Caramel Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
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
                      padding: const EdgeInsets.all(4.0),
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
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('🌍', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Choose your preferred language for all word puzzles and progression.',
                        style: GoogleFonts.fredoka(
                          fontSize: 12.sp,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
              child: InkWell(
                onTap: _confirmSelection,
                borderRadius: BorderRadius.circular(24.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppColors.btnBorderBrown, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.btnShadowBrown,
                        offset: Offset(0, 2.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8.w),
                      Text(
                        'CONFIRM SELECTION',
                        style: GoogleFonts.fredoka(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 150.ms, curve: Curves.easeOut),
            ),
          ],
        ),
      ),
    );
  }
}
