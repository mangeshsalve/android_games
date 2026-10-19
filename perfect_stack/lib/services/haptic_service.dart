import 'package:flutter/services.dart';

import 'storage_service.dart';

class HapticService {
  HapticService(this._storage);

  final StorageService _storage;

  void place() => _run(HapticFeedback.lightImpact);
  void perfect() => _run(HapticFeedback.mediumImpact);
  void fail() => _run(HapticFeedback.heavyImpact);
  void button() => _run(HapticFeedback.selectionClick);

  void _run(Future<void> Function() feedback) {
    if (!_storage.vibrationEnabled) return;
    // Devices without a vibrator simply ignore the request.
    feedback().catchError((Object _) {});
  }
}
