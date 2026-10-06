import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/language_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'selected_language': 'english',
      'max_unlocked_level_index_english': 10,
      'max_unlocked_level_index_german': 5,
    });
    await GameStorage.init();
  });

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('LanguageSelectionScreen renders header banner, close button, language cards and confirm button', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        LanguageSelectionScreen(
          currentLanguage: 'english',
          onLanguageSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    // 1. Header Banner CartoonText "Language"
    expect(
      find.byWidgetPredicate((w) => w is CartoonText && w.text == 'Language'),
      findsOneWidget,
    );

    // 2. Close button
    expect(find.byType(Image), findsWidgets);

    // 3. Languages displayed
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    // 4. Progress subtitles
    expect(find.text('Progress: Level 11'), findsOneWidget);
    expect(find.text('Progress: Level 6'), findsOneWidget);

    // 5. Confirm 3D button
    expect(
      find.byWidgetPredicate((w) => w is CartoonText && w.text == 'Confirm'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping a different language selects it and Confirm saves it', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? selectedLang;

    await tester.pumpWidget(
      buildTestWidget(
        LanguageSelectionScreen(
          currentLanguage: 'english',
          onLanguageSelected: (lang) => selectedLang = lang,
        ),
      ),
    );
    await tester.pump();

    expect(GameStorage.getSelectedLanguage(), equals('english'));

    // Tap Deutsch
    await tester.tap(find.text('Deutsch'));
    await tester.pump();

    // Tap Confirm button
    final confirmBtn = find.byWidgetPredicate((w) => w is CartoonText && w.text == 'Confirm');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(selectedLang, equals('german'));
    expect(GameStorage.getSelectedLanguage(), equals('german'));
  });

  testWidgets('Close button dismisses without changing language', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? selectedLang;

    await tester.pumpWidget(
      buildTestWidget(
        LanguageSelectionScreen(
          currentLanguage: 'english',
          onLanguageSelected: (lang) => selectedLang = lang,
        ),
      ),
    );
    await tester.pump();

    // Tap Deutsch
    await tester.tap(find.text('Deutsch'));
    await tester.pump();

    // Tap Close Button (icon_close.webp)
    final closeBtn = find.byWidgetPredicate(
      (w) => w is Image && (w.image as AssetImage).assetName == 'assets/icons/icon_close.webp',
    );
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // Callback should not be called, language should remain 'english'
    expect(selectedLang, isNull);
    expect(GameStorage.getSelectedLanguage(), equals('english'));
  });
}
