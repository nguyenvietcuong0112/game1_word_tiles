import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/analytics_service.dart';
import 'services/audio_manager.dart';
import 'theme/app_theme.dart';
import 'views/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase, Analytics, and Crashlytics
  await AnalyticsService.initialize();

  // Set portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WordTilesApp());
}

class WordTilesApp extends StatefulWidget {
  const WordTilesApp({super.key});

  @override
  State<WordTilesApp> createState() => _WordTilesAppState();
}

class _WordTilesAppState extends State<WordTilesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      AudioManager.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      AudioManager.resumeBgm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Word Tiles',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          home: const LoadingScreen(),
        );
      },
    );
  }
}


