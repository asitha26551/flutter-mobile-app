import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onboarding_store_web.dart'
    if (dart.library.io) 'onboarding_store_native.dart' as platform_store;

class OnboardingStore {
  static const _channel = MethodChannel('mindcare/onboarding');

  static Future<bool> hasCompleted() async {
    if (kIsWeb) return platform_store.hasCompleted();
    return await _channel.invokeMethod<bool>('hasCompleted') ?? false;
  }

  static Future<void> markCompleted() async {
    if (kIsWeb) {
      await platform_store.markCompleted();
      return;
    }
    await _channel.invokeMethod<bool>('markCompleted');
  }
}
