import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_stack/app.dart';
import 'package:perfect_stack/services/ad_service.dart';
import 'package:perfect_stack/services/app_services.dart';
import 'package:perfect_stack/services/haptic_service.dart';
import 'package:perfect_stack/services/sound_service.dart';
import 'package:perfect_stack/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late AppServices services;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final storage = await StorageService.create();
    services = AppServices(
      storage: storage,
      // Audio is never initialised in tests, so playback is a no-op.
      sound: SoundService(storage),
      haptics: HapticService(storage),
      ads: AdManager(
        service: MockAdService(adDuration: const Duration(milliseconds: 100)),
      ),
    );
  });

  /// Advances real frames; the game caps each frame at 1/30 s of game time.
  Future<void> pumpFrames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> tapGame(WidgetTester tester) async {
    // Tap in the empty upper area, away from the HUD buttons.
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> dieAndShowGameOver(WidgetTester tester) async {
    // The first block starts on the right edge and still overlaps the
    // foundation; the next one starts far left over a sliver -> miss.
    await tapGame(tester);
    await tapGame(tester);
    await pumpFrames(tester, 90);
  }

  testWidgets('home -> play -> score -> game over -> continue -> retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PerfectStackApp(services: services));
    expect(find.text('PERFECT'), findsOneWidget);
    expect(find.text('HIGH SCORE  0'), findsOneWidget);

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('TAP TO DROP'), findsOneWidget);

    await dieAndShowGameOver(tester);
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('NEW BEST!'), findsOneWidget);
    expect(services.storage.highScore, 1);

    // Rewarded "ad" continues the same run exactly once.
    await tester.tap(find.text('WATCH AD TO CONTINUE'));
    await tester.pump(const Duration(milliseconds: 150));
    await pumpFrames(tester, 20);
    expect(find.text('GAME OVER'), findsNothing);

    // The continued block is a sliver again, so waiting and tapping at the
    // wrong moment misses; keep tapping until the run ends.
    for (var i = 0; i < 10 && find.text('GAME OVER').evaluate().isEmpty; i++) {
      await tapGame(tester);
      await pumpFrames(tester, 90);
    }
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('WATCH AD TO CONTINUE'), findsNothing);

    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await pumpFrames(tester, 20);
    expect(find.text('GAME OVER'), findsNothing);
    expect(find.text('TAP TO DROP'), findsOneWidget);
  });

  testWidgets('back button pauses, resumes and returns home from game over', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PerfectStackApp(services: services));
    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.binding.handlePopRoute();
    await pumpFrames(tester, 20);
    expect(find.text('PAUSED'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await pumpFrames(tester, 20);
    expect(find.text('PAUSED'), findsNothing);

    await dieAndShowGameOver(tester);
    expect(find.text('GAME OVER'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await pumpFrames(tester, 60);
    expect(find.text('HIGH SCORE  1'), findsOneWidget);
    expect(find.text('GAME OVER'), findsNothing);
  });
}
