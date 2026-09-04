import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import 'common/app_background.dart';
import 'common/wood_widgets.dart';

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
    AudioManager.playTileSelect(pitchIndex: 4);
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
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    WoodCarvedIconButton(
                      size: 44.r,
                      assetPath: WoodGameIcons.btnBack,
                      onTap: () {
                        AudioManager.playTileSelect(pitchIndex: 1);
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'SELECT LANGUAGE',
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
              SizedBox(height: 6.h),

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
                    final parts = displayName.split(' ');
                    final flag = parts.length > 1 ? parts.last : '🌐';
                    final langName = parts.first;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: InkWell(
                        onTap: () {
                          AudioManager.playTileSelect(pitchIndex: 3);
                          setState(() {
                            _tempSelectedLanguage = lang;
                          });
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected ? WoodenStyle.woodHighlight : WoodenStyle.woodBevel,
                              width: isSelected ? 2.2 : 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: WoodenStyle.woodExtrusion,
                                offset: Offset(0, isSelected ? 3.5 : 2.5),
                                blurRadius: 0,
                              ),
                              if (isSelected)
                                const BoxShadow(
                                  color: Color(0x33F3942B),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18.r),
                            child: Stack(
                              children: [
                                // Background
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFFFFD868),
                                                Color(0xFFF3942B),
                                                Color(0xFFD97213),
                                                Color(0xFFAC4B04),
                                              ],
                                            )
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFFD97E25),
                                                Color(0xFFBF6212),
                                                Color(0xFFA64F0A),
                                                Color(0xFF853B04),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                // Wood Grain
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: isSelected ? 0.32 : 0.25,
                                    child: Image.asset(
                                      'assets/images/golden_wood_texture.webp',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                // Highlight specular rim
                                Positioned(
                                  top: 0,
                                  left: 12,
                                  right: 12,
                                  height: 1.2,
                                  child: Container(
                                    color: Colors.white.withValues(alpha: isSelected ? 0.45 : 0.35),
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                  child: Row(
                                    children: [
                                      // Flag / Icon Box
                                      Container(
                                        width: 44.r,
                                        height: 44.r,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFF5A2508),
                                              Color(0xFF381401),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? GoldenWoodColors.woodHighlight
                                                : GoldenWoodColors.woodBevel,
                                            width: 1.4,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: GoldenWoodColors.woodExtrusion,
                                              offset: Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(flag, style: TextStyle(fontSize: 22.sp)),
                                        ),
                                      ),
                                      SizedBox(width: 14.w),

                                      // Language Info
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
                                              'Progress: Level $maxUnlocked',
                                              style: GoogleFonts.fredoka(
                                                fontSize: 12.sp,
                                                color: Colors.white.withValues(alpha: 0.9),
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

                                      // Radio Check Indicator
                                      if (isSelected)
                                        Image.asset(
                                          WoodGameIcons.btnCheck,
                                          width: 28.r,
                                          height: 28.r,
                                        )
                                      else
                                        Container(
                                          width: 24.r,
                                          height: 24.r,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF421500),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: GoldenWoodColors.woodBevel,
                                              width: 2.0,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                child: WoodenButton(
                  text: 'CONFIRM SELECTION',
                  icon: Icons.check_circle_rounded,
                  variant: WoodenButtonVariant.primary,
                  height: 56.h,
                  fontSize: 18.sp,
                  onTap: _confirmSelection,
                ).animate().scale(duration: 150.ms, curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
