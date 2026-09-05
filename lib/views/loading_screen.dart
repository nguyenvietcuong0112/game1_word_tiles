import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import 'common/app_background.dart';
import 'common/wood_widgets.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnim;
  String _statusText = 'Loading dictionaries...';

  final List<String> _loadingMessages = [
    'Loading dictionaries...',
    'Initializing audio engine...',
    'Preparing puzzle levels...',
    'Polishing wood tiles...',
    'Ready to play!',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addListener(() {
      final p = _progressAnim.value;
      final msgIndex = (p * (_loadingMessages.length - 1))
          .floor()
          .clamp(0, _loadingMessages.length - 1);
      if (_statusText != _loadingMessages[msgIndex]) {
        setState(() {
          _statusText = _loadingMessages[msgIndex];
        });
      }
    });

    _startLoadingPipeline();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startLoadingPipeline() async {
    // 1. Start smooth continuous 0% -> 100% progress animation
    final animationFuture = _controller.forward();

    // 2. Perform async initializations in parallel
    try {
      await GameStorage.init();
    } catch (_) {}

    try {
      await AudioManager.init();
      AudioManager.startBgm();
    } catch (_) {}

    // 3. Wait for progress to reach 100%
    await animationFuture;

    // Small delay at 100% to let the user see "Ready to play!"
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient warm golden particles (Workshop sunlit dust motes)
              ..._buildGoldenParticles(),

              // Main content
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // Wood-Framed App Logo with 3D Bevel & Specular Highlight
                      _buildWoodFramedLogo(),

                      SizedBox(height: 22.h),

                      // 3D Wooden Letter Tiles: "WORD" and "TILES"
                      _buildWoodTilesTitle(),

                      SizedBox(height: 12.h),

                      // Subtitle Carved Walnut Plaque
                      _buildSubtitlePlaque(),

                      const Spacer(flex: 3),

                      // Authentic 3D Slotted Wooden Progress Bar (0% -> 100% Left-to-Right)
                      AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (context, child) {
                          final progress = _progressAnim.value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WoodProgressBar(
                                progress: progress,
                                height: 24.h,
                              ),
                              SizedBox(height: 12.h),
                              _buildStatusRow(progress),
                            ],
                          );
                        },
                      ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWoodFramedLogo() {
    return Container(
      width: 156.r,
      height: 156.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: WoodenStyle.woodBevel,
          width: 3.2.r,
        ),
        boxShadow: [
          BoxShadow(
            color: WoodenStyle.woodExtrusion,
            offset: Offset(0, 5.h),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0x3D000000),
            offset: Offset(0, 10.h),
            blurRadius: 18.r,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/app_logo.webp',
                fit: BoxFit.cover,
              ),
            ),
            // Specular Highlight Rim on top edge
            Positioned(
              top: 0,
              left: 12.w,
              right: 12.w,
              height: 2.h,
              child: Container(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          duration: 700.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.4, 0.4),
          end: const Offset(1.0, 1.0),
        )
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          duration: 2200.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.025, 1.025),
          curve: Curves.easeInOut,
        );
  }

  Widget _buildWoodTilesTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['W', 'O', 'R', 'D'].asMap().entries.map((entry) {
            return _buildWoodLetterTile(entry.value, size: 46.r)
                .animate()
                .fadeIn(duration: 400.ms, delay: (150 + entry.key * 70).ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                );
          }).toList(),
        ),
        SizedBox(height: 7.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['T', 'I', 'L', 'E', 'S'].asMap().entries.map((entry) {
            return _buildWoodLetterTile(entry.value, size: 40.r)
                .animate()
                .fadeIn(duration: 400.ms, delay: (450 + entry.key * 60).ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWoodLetterTile(String letter, {required double size}) {
    final double radius = size * 0.26;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF6B2B04),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF421500),
            offset: Offset(0, 3.2),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x30000000),
            offset: Offset(0, 4.5),
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.88),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rich Golden Honey Oak Plank Gradient
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
            // Wood Grain Texture
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  'assets/images/golden_wood_texture.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Specular Highlight Rim
            Positioned(
              top: 0,
              left: 5,
              right: 5,
              height: 1.5,
              child: Container(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            // 3D Carved Letter Text
            Center(
              child: Text(
                letter,
                style: GoogleFonts.fredoka(
                  fontSize: size * 0.58,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF5A1C00),
                      offset: Offset(0, 2.0),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: Color(0xFF2E0C00),
                      offset: Offset(0, 3.5),
                      blurRadius: 1,
                    ),
                    Shadow(
                      color: Color(0x44000000),
                      offset: Offset(0, 5.0),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitlePlaque() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFF381401),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: WoodenStyle.woodBevel, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: WoodenStyle.woodExtrusion,
            offset: Offset(0, 1.8),
          ),
        ],
      ),
      child: Text(
        '✨ CONNECT LETTERS • FIND WORDS ✨',
        style: GoogleFonts.fredoka(
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          color: const Color(0xFFFFBA52),
          shadows: const [
            Shadow(
              color: Color(0xFF1F0900),
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 750.ms);
  }

  Widget _buildStatusRow(double progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 7.r,
                height: 7.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD97213),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x88F3942B),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _statusText,
                  style: GoogleFonts.fredoka(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C2E14),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: GoogleFonts.fredoka(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFB55208),
            shadows: const [
              Shadow(
                color: Color(0x40FFE066),
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGoldenParticles() {
    final particlesData = [
      (top: 90.0, left: 30.0, right: null, size: 6.0, delay: 0),
      (top: 170.0, left: null, right: 36.0, size: 8.0, delay: 300),
      (top: 260.0, left: 45.0, right: null, size: 5.0, delay: 600),
      (top: 380.0, left: null, right: 28.0, size: 9.0, delay: 200),
      (top: 500.0, left: 35.0, right: null, size: 7.0, delay: 500),
      (top: 610.0, left: null, right: 42.0, size: 6.0, delay: 700),
      (top: 710.0, left: 50.0, right: null, size: 8.0, delay: 400),
    ];

    return particlesData.map((data) {
      return Positioned(
        top: data.top,
        left: data.left,
        right: data.right,
        child: Container(
          width: data.size.r,
          height: data.size.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD868).withValues(alpha: 0.55),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                blurRadius: 6,
                spreadRadius: 1.5,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              delay: Duration(milliseconds: data.delay),
              duration: 2000.ms,
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.35, 1.35),
            )
            .fade(begin: 0.3, end: 0.85),
      );
    }).toList();
  }
}

