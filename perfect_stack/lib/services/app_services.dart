import 'dart:async';

import 'ad_service.dart';
import 'haptic_service.dart';
import 'sound_service.dart';
import 'storage_service.dart';

/// Holds the app-wide services. Passed down explicitly instead of using a
/// service locator package to keep dependencies minimal.
class AppServices {
  AppServices({
    required this.storage,
    required this.sound,
    required this.haptics,
    required this.ads,
  });

  final StorageService storage;
  final SoundService sound;
  final HapticService haptics;
  final AdManager ads;

  static Future<AppServices> create() async {
    final storage = await StorageService.create();
    final services = AppServices(
      storage: storage,
      sound: SoundService(storage),
      haptics: HapticService(storage),
      ads: AdManager(service: MockAdService()),
    );
    // Neither blocks the first frame; both fail gracefully.
    unawaited(services.sound.initialize());
    unawaited(services.ads.initialize());
    return services;
  }
}
