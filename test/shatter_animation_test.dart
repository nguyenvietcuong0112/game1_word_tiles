import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_tiles_flutter/views/widgets/shatter_particle_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TileShatterController spawns rich 3D shards, shockwaves, and sparkles', (tester) async {
    final controller = TileShatterController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final vsync = Navigator.of(context);
              controller.init(vsync);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(controller.shards, isEmpty);
    expect(controller.shockwaves, isEmpty);
    expect(controller.sparkles, isEmpty);

    // Trigger shatter
    controller.shatterTile(
      center: const Offset(100, 100),
      tileSize: 60.0,
    );

    // Verify entities are spawned
    expect(controller.shards.length, greaterThanOrEqualTo(18));
    expect(controller.shockwaves.length, 1);
    expect(controller.sparkles.length, greaterThanOrEqualTo(6));

    // Verify button brown dominant palette (contains button face brown / caramel, NO dark bark #4A2610)
    const woodyBrown = Color(0xFF4A2610);
    final hasWoodyColors = controller.shards.any((s) => s.faceColor == woodyBrown);
    expect(hasWoodyColors, isFalse, reason: 'Shards should not have dark wood bark colors');

    final buttonBrownShards = controller.shards.where(
      (s) => s.faceColor == const Color(0xFFA66640) ||
             s.faceColor == const Color(0xFFCA9370) ||
             s.faceColor == const Color(0xFFBD7C54) ||
             s.faceColor == const Color(0xFF8F522C) ||
             s.faceColor == const Color(0xFF9E5C35) ||
             s.faceColor == const Color(0xFFB57048) ||
             s.faceColor == const Color(0xFF7B411D),
    );
    expect(buttonBrownShards.isNotEmpty, isTrue, reason: 'Button brown colors must be present');
    expect(
      buttonBrownShards.length,
      greaterThan(controller.shards.length ~/ 2),
      reason: 'Button brown colors must be the dominant majority (>50%) of shards',
    );

    // Verify mix of juicy pop bubbles and glossy gem shards
    final hasBubbles = controller.shards.any((s) => s.isBubble);
    final hasGemShards = controller.shards.any((s) => !s.isBubble);
    expect(hasBubbles, isTrue, reason: 'Should spawn juicy round candy bubbles');
    expect(hasGemShards, isTrue, reason: 'Should spawn glossy gem fragments');

    // Verify Painter renders without exceptions
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TileShatterPainter(
      shards: controller.shards,
      shockwaves: controller.shockwaves,
      sparkles: controller.sparkles,
    );
    expect(() => painter.paint(canvas, const Size(400, 800)), returnsNormally);

    // Let animation run to completion across frames (respecting clamped dt)
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }

    expect(controller.shards, isEmpty);
    expect(controller.shockwaves, isEmpty);
    expect(controller.sparkles, isEmpty);

    controller.dispose();
  });
}
