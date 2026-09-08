import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/views/widgets/tutorial_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'count_tutorial_shown': false,
    });
    await GameStorage.init();
    await GameStorage.setCountTutorialShown(false);
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

    // Verify sample letter 'C' and count '2' are displayed
    expect(find.text('C'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Got it!'), findsOneWidget);

    // Tap Got it! button
    await tester.tap(find.text('Got it!'));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
    expect(GameStorage.isCountTutorialShown(), isTrue);
  });
}
