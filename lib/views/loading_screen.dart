import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:funtap_global_sdk/funtap_global_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ads_manager.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/remote_config_service.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startLoadingPipeline();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLoadingPipeline() async {
    final startTime = DateTime.now();

    // 1. Start smooth visual progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progress < 0.90) {
          _progress += 0.02;
        }
      });
    });

    FGSDK.logLoadingStart('splash');

    // 2. Perform async initializations
    try {
      await GameStorage.init();
    } catch (_) {}

    try {
      await AudioManager.init();
      AudioManager.startBgm();
    } catch (_) {}

    // Initialize AdsManager & RemoteConfig
    try {
      AdsManager.init();
      // Wait for Remote Config to be ready from cloud if possible (max 1500ms)
      final rcStartTime = DateTime.now();
      while (!await FGSDK.isRemoteConfigReady() &&
          DateTime.now().difference(rcStartTime).inMilliseconds < 1500) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await RemoteConfigService.fetchConfigs();
    } catch (_) {}

    // Small delay to ensure smooth, pleasant animation (bounded by 10s max)
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    _progressTimer?.cancel();

    // Complete to 100%
    setState(() {
      _progress = 1.0;
    });

    final loadDuration = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
    FGSDK.logLoadingEnd('splash', true, loadDuration);

    await Future.delayed(const Duration(milliseconds: 300));

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
      backgroundColor: const Color(0xFF6B42A6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed background with floating tiles and bottom scrabble tiles
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_loading_splash.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Fore-layer interactive UI: Glowing Logo + Loading... + Progress Capsule
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 32),

                // Center Word Connect Logo with ambient radial glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft warm radial light halo
                    Container(
                      width: 290.w,
                      height: 180.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),

                    // Logo Artwork
                    Image.asset(
                      'assets/icons/logo_loading_splash.png',
                      width: 310.w,
                      fit: BoxFit.contain,
                    ),
                  ],
                )
                    .animate()
                    .scale(
                      duration: 650.ms,
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
                    ),

                const Spacer(flex: 18),

                // Loading... status label
                Text(
                  'Loading...',
                  style: GoogleFonts.fredoka(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        offset: Offset(0, 1.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                SizedBox(height: 10.h),

                // Sleek Capsule Progress Bar
                Container(
                  width: 246.w,
                  height: 20.h,
                  padding: EdgeInsets.all(2.5.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2D38),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFFF3ECE4),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 2.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      final barW = (maxW * _progress.clamp(0.0, 1.0));
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: barW,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7.r),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5FE86D), // bright top lime highlight
                                Color(0xFF32D34E), // rich emerald green
                                Color(0xFF1EAE3A), // deep green base
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x664ADE80),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(duration: 500.ms),

                const Spacer(flex: 38),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
