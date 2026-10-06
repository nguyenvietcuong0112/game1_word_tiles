import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/remote_config_service.dart';
import 'package:word_tiles_flutter/views/widgets/tutorial_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'count_tutorial_shown': false,
    });
    await GameStorage.init();
    await GameStorage.setCountTutorialShown(false);
    RemoteConfigService.setMockValues(tutorialTapOutsideClose: false);
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

  testWidgets('TileCountTutorialModal renders single 3D letter tile and Got it button', (tester) async {
    bool dismissed = false;

    await tester.pumpWidget(
      buildTestWidget(
        TileCountTutorialModal(
          sampleLetter: 'C',
          count: 2,
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify speech bubble and Got it! button are displayed
    expect(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('usage count')),
      findsOneWidget,
    );
    expect(find.text('Got it!'), findsOneWidget);

    // Tap Got it! button
    await tester.tap(find.text('Got it!'));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
    expect(GameStorage.isCountTutorialShown(), isTrue);
  });

  testWidgets('When tutorialTapOutsideClose is false (default), tapping outside does NOT dismiss', (tester) async {
    bool dismissed = false;
    RemoteConfigService.setMockValues(tutorialTapOutsideClose: false);
    await GameStorage.setCountTutorialShown(false);

    await tester.pumpWidget(
      buildTestWidget(
        TileCountTutorialModal(
          sampleLetter: 'C',
          count: 2,
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Tap top-left corner outside the bubble
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Must NOT be dismissed because default is false
    expect(dismissed, isFalse);
    expect(GameStorage.isCountTutorialShown(), isFalse);
  });

  testWidgets('When tutorialTapOutsideClose is true, tapping outside DOES dismiss', (tester) async {
    bool dismissed = false;
    RemoteConfigService.setMockValues(tutorialTapOutsideClose: true);
    await GameStorage.setCountTutorialShown(false);

    await tester.pumpWidget(
      buildTestWidget(
        TileCountTutorialModal(
          sampleLetter: 'C',
          count: 2,
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Tap top-left corner outside the bubble
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Must be dismissed when enabled
    expect(dismissed, isTrue);
    expect(GameStorage.isCountTutorialShown(), isTrue);
  });

  testWidgets('SwipeTutorialCard tap dismiss respects tutorialTapOutsideClose', (tester) async {
    bool dismissed = false;

    // When false
    RemoteConfigService.setMockValues(tutorialTapOutsideClose: false);
    await tester.pumpWidget(
      buildTestWidget(
        SwipeTutorialCard(
          spans: const [TextSpan(text: 'Swipe the Word SUN')],
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byType(TutorialSpeechBubble));
    await tester.pumpAndSettle();
    expect(dismissed, isFalse);

    // When true
    RemoteConfigService.setMockValues(tutorialTapOutsideClose: true);
    await tester.pumpWidget(
      buildTestWidget(
        SwipeTutorialCard(
          spans: const [TextSpan(text: 'Swipe the Word SUN')],
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byType(TutorialSpeechBubble));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });

  test('GameStorage tutorial tap outside override toggles RemoteConfigService', () async {
    RemoteConfigService.setMockValues(tutorialTapOutsideClose: false);
    expect(RemoteConfigService.tutorialTapOutsideClose, isFalse);

    await GameStorage.setTutorialTapOutsideOverride(true);
    expect(RemoteConfigService.tutorialTapOutsideClose, isTrue);

    await GameStorage.setTutorialTapOutsideOverride(false);
    expect(RemoteConfigService.tutorialTapOutsideClose, isFalse);

    await GameStorage.setTutorialTapOutsideOverride(null);
    expect(RemoteConfigService.tutorialTapOutsideClose, isFalse);
  });
}
