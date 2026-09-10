import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../services/level_loader.dart';
import '../../theme/app_typography.dart';
import '../language_selection_screen.dart';

class SettingsDialog extends StatefulWidget {
  final bool isHomeScreen;
  final VoidCallback? onLanguageChanged;
  final VoidCallback? onRestartLevel;
  final VoidCallback? onGoHome;

  const SettingsDialog({
    super.key,
    this.isHomeScreen = false,
    this.onLanguageChanged,
    this.onRestartLevel,
    this.onGoHome,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _musicEnabled;
  late bool _soundEnabled;
  late bool _hapticEnabled;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _musicEnabled = GameStorage.isMusicEnabled();
    _soundEnabled = GameStorage.isSoundEnabled();
    _hapticEnabled = GameStorage.isHapticEnabled();
    _currentLanguage = GameStorage.getLanguage();
  }

  void _toggleMusic(bool value) async {
    setState(() => _musicEnabled = value);
    await GameStorage.setMusicEnabled(value);
    AudioManager.setMusicEnabled(value);
    AudioManager.playTileSelect(pitchIndex: value ? 5 : 2);
  }

  void _toggleSound(bool value) async {
    setState(() => _soundEnabled = value);
    await GameStorage.setSoundEnabled(value);
    AudioManager.playTileSelect(pitchIndex: value ? 5 : 2);
  }

  void _toggleHaptic(bool value) async {
    setState(() => _hapticEnabled = value);
    await GameStorage.setHapticEnabled(value);
    if (value) {
      HapticFeedback.mediumImpact();
    }
    AudioManager.playTileSelect(pitchIndex: value ? 5 : 2);
  }

  void _openLanguageSelection() async {
    AudioManager.playTileSelect(pitchIndex: 4);
    await LanguageSelectionScreen.show(
      context,
      currentLanguage: _currentLanguage,
      onLanguageSelected: (newLang) {
        setState(() => _currentLanguage = newLang);
        widget.onLanguageChanged?.call();
      },
    );
    if (mounted) {
      setState(() {
        _currentLanguage = GameStorage.getLanguage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: SizedBox(
          width: 336.w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Outer White Card with Soft 3D Shadow
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFFE5EFF5), width: 3.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x38000000),
                      offset: Offset(0, 12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0xFFB0C9DA),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 14.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sunken Pastel Toggle Panel
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5E7F3),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFBED7E8), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Music Row
                          _buildSettingRow(
                            iconAsset: 'assets/icons/icon_music.png',
                            label: 'Music',
                            value: _musicEnabled,
                            onChanged: _toggleMusic,
                          ),
                          SizedBox(height: 12.h),

                          // Sound Row
                          _buildSettingRow(
                            iconAsset: 'assets/icons/icon_sound.png',
                            label: 'Sound',
                            value: _soundEnabled,
                            onChanged: _toggleSound,
                          ),
                          SizedBox(height: 12.h),

                          // Vibration Row
                          _buildSettingRow(
                            iconAsset: 'assets/icons/icon_vibration.png',
                            label: 'Vibration',
                            value: _hapticEnabled,
                            onChanged: _toggleHaptic,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Contextual Action Buttons
                    if (widget.isHomeScreen) ...[
                      // Home Screen Mode: Select Game Language
                      _buildLanguageButton(),
                    ] else ...[
                      // Game Screen Mode: Home and Restart Buttons
                      _buildAction3DButton(
                        label: 'Home',
                        icon: Icons.home,
                        faceColor: const Color(0xFF42D623),
                        bevelColor: const Color(0xFF229713),
                        borderColor: const Color(0xFF0F5A06),
                        outlineColor: const Color(0xFF0E5606),
                        onTap: () {
                          AudioManager.playTileSelect(pitchIndex: 2);
                          if (widget.onGoHome != null) {
                            widget.onGoHome!();
                          } else {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                      ),
                      SizedBox(height: 10.h),
                      _buildAction3DButton(
                        label: 'Restart',
                        icon: Icons.replay_sharp,
                        faceColor: const Color(0xFFFF3F3F),
                        bevelColor: const Color(0xFFD11F24),
                        borderColor: const Color(0xFF881014),
                        outlineColor: const Color(0xFF881014),
                        onTap: () {
                          AudioManager.playTileSelect(pitchIndex: 3);
                          Navigator.of(context).pop();
                          widget.onRestartLevel?.call();
                        },
                      ),
                    ],

                    SizedBox(height: 14.h),

                    // Version Label at Bottom
                  ],
                ),
              ),

              // Header Pill: "Setting" with bg_btn_setting.png
              Positioned(
                top: -20.h,
                child: Container(
                  width: 200.w,
                  height: 48.h,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/icons/bg_btn_setting.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: const CartoonText(
                    text: 'Setting',
                    fontSize: 22,
                    textColor: Colors.white,
                    outlineColor: Color(0xFF380662),
                    strokeWidth: 3.4,
                    shadowOffset: 1.6,
                  ),
                ),
              ),

              // Close Button using icon_close.png (overflows corner as in mockup)
              Positioned(
                top: -15.h,
                right: -13.w,
                child: _CloseButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.78, 0.78),
          end: const Offset(1.0, 1.0),
          duration: 260.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 180.ms);
  }

  /// Builds a single toggle row: icon + label + animated on/off switch
  Widget _buildSettingRow({
    required String iconAsset,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  iconAsset,
                  width: 26.r,
                  height: 26.r,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3B4868),
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _SettingToggleSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// 3D Action button (Home / Restart)
  Widget _buildAction3DButton({
    required String label,
    required IconData icon,
    required Color faceColor,
    required Color bevelColor,
    required Color borderColor,
    required Color outlineColor,
    required VoidCallback onTap,
  }) {
    return _Pressable3DContainer(
      onTap: onTap,
      width: 160.w,
      height: 48.h,
      faceColor: faceColor,
      bevelColor: bevelColor,
      borderColor: borderColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 26.r,
          ),
          SizedBox(width: 8.w),
          CartoonText(
            text: label,
            fontSize: 20,
            textColor: Colors.white,
            outlineColor: outlineColor,
            strokeWidth: 3.2,
            shadowOffset: 1.4,
          ),
        ],
      ),
    );
  }

  /// Language Selection button shown on HomeScreen mode
  Widget _buildLanguageButton() {
    final fullLang = LevelLoader.languageDisplayNames[_currentLanguage] ?? _currentLanguage;
    final parts = fullLang.split(' ');
    final flag = parts.length > 1 ? parts.last : '🌐';
    final langName = parts.first;

    return _Pressable3DContainer(
      onTap: _openLanguageSelection,
      width: 210.w,
      height: 52.h,
      faceColor: const Color(0xFFFFB703),
      bevelColor: const Color(0xFFD48B00),
      borderColor: const Color(0xFF9A5B00),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 8.w),
          CartoonText(
            text: langName,
            fontSize: 19,
            textColor: Colors.white,
            outlineColor: const Color(0xFF8D5300),
            strokeWidth: 3.2,
            shadowOffset: 1.4,
          ),
          SizedBox(width: 6.w),
          const Icon(
            Icons.swap_horiz_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }
}

/// Custom animated toggle switch using box_on_off.png, btn_on.png, btn_off.png
class _SettingToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggleSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62.w,
        height: 32.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Track: box_on_off.png
            Image.asset(
              'assets/icons/box_on_off.png',
              width: 58.w,
              height: 18.h,
              fit: BoxFit.fill,
            ),
            // Sliding Knob: btn_on.png (green) or btn_off.png (red)
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Image.asset(
                value ? 'assets/icons/btn_on.png' : 'assets/icons/btn_off.png',
                width: 32.r,
                height: 32.r,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile 3D Pressable Container with Bevel Lip
class _Pressable3DContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double width;
  final double height;
  final Color faceColor;
  final Color bevelColor;
  final Color borderColor;

  const _Pressable3DContainer({
    required this.child,
    required this.onTap,
    required this.width,
    required this.height,
    required this.faceColor,
    required this.bevelColor,
    required this.borderColor,
  });

  @override
  State<_Pressable3DContainer> createState() => _Pressable3DContainerState();
}

class _Pressable3DContainerState extends State<_Pressable3DContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (GameStorage.isHapticEnabled()) {
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? 3.h : 0,
          bottom: _isPressed ? 0 : 3.h,
        ),
        decoration: BoxDecoration(
          color: widget.faceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: widget.borderColor, width: 0.5),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.bevelColor,
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            const BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: _isPressed ? 0 : 2.h),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Close Button using icon_close.png
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (GameStorage.isHapticEnabled()) {
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        AudioManager.playTileSelect(pitchIndex: 1);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Image.asset(
          'assets/icons/icon_close.png',
          width: 44.r,
          height: 44.r,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
