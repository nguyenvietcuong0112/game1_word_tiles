import 'dart:async';
import 'package:flutter/material.dart';
import 'package:funtap_global_sdk/funtap_global_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ads_manager.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/remote_config_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/game_scaffold.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Loading dictionaries...';
  Timer? _progressTimer;

  final List<String> _loadingMessages = [
    'Loading dictionaries...',
    'Initializing audio engine...',
    'Preparing puzzle levels...',
    'Polishing word tiles...',
    'Ready to play!',
  ];

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
          final msgIndex = ((_progress / 0.90) * (_loadingMessages.length - 2)).floor().clamp(0, _loadingMessages.length - 2);
          _statusText = _loadingMessages[msgIndex];
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
      _statusText = _loadingMessages.last;
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
    return GameScaffold(
      body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // Modern Pastel 512x512 Logo with Soft Clay Shadow & Pop-in
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(44),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracotta.withValues(alpha: 0.20),
                              blurRadius: 30,
                              spreadRadius: 4,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: const Color(0xFF78350F).withValues(alpha: 0.10),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(44),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          .animate()
                          .scale(
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3),
                            end: const Offset(1.0, 1.0),
                          )
                          .then()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            duration: 2000.ms,
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.03, 1.03),
                            curve: Curves.easeInOut,
                          ),

                      const SizedBox(height: 28),

                      // Game Title
                      Text(
                        'WORD TILES',
                        style: GoogleFonts.fredoka(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: const Color(0xFF1E293B),
                          shadows: [
                            Shadow(
                              color: AppColors.terracotta.withValues(alpha: 0.25),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),

                      const SizedBox(height: 6),

                      // Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardPeachLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                        ),
                        child: Text(
                          '✨ CONNECT LETTERS • FIND WORDS ✨',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 350.ms),

                      const Spacer(flex: 3),

                      // Animated Pastel Progress Bar Container
                      Container(
                        width: double.infinity,
                        height: 22,
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracotta.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final currentWidth = (maxWidth * _progress.clamp(0.0, 1.0));
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: currentWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFB923C), // Pastel warm orange
                                    Color(0xFFF97316),
                                    Color(0xFFEA580C),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.terracotta.withValues(alpha: 0.3),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                      const SizedBox(height: 14),

                      // Loading Status & Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _statusText,
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms, delay: 450.ms),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
    );
  }
}
