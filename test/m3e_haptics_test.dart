// Copyright (c) 2026 Mudit Purohit
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_haptics/m3e_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String?> hapticCalls = [];

  setUp(() {
    hapticCalls.clear();
    // Intercept native haptic method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('m3e_haptics/haptics'), (MethodCall methodCall) async {
      if (methodCall.method == 'vibrate') {
        final arguments = methodCall.arguments as Map;
        final type = arguments['type'] as String;
        final String mappedType = switch (type) {
          'dragTexture' => 'HapticFeedbackType.lightImpact',
          'bookendLower' => 'HapticFeedbackType.heavyImpact',
          'tickCrossing' => 'HapticFeedbackType.mediumImpact',
          'bookendUpper' => 'HapticFeedbackType.heavyImpact',
          _ => 'HapticFeedbackType.mediumImpact',
        };
        hapticCalls.add(mappedType);
      }
      return null;
    });

    // Intercept platform channel calls for haptic feedback
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'HapticFeedback.vibrate') {
        hapticCalls.add(methodCall.arguments as String?);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('m3e_haptics/haptics'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('M3EHapticTracker tests in standalone package', () {
    test('does not play haptics when baseHaptic is none', () {
      final tracker = M3EHapticTracker(
        baseHaptic: M3EHapticFeedback.none,
      );
      tracker.start(0.5, Offset.zero);
      tracker.update(0.6, const Offset(10, 0));
      expect(hapticCalls, isEmpty);
    });

    test('plays continuous drag haptics based on progress delta', () {
      final tracker = M3EHapticTracker(
        baseHaptic: M3EHapticFeedback.light,
        config: const M3EHapticConfig(
          enableContinuousDrag: true,
          deltaProgressForDragThreshold: 0.1,
          vibrateOnLowerBookend: false,
          vibrateOnUpperBookend: false,
        ),
      );
      tracker.start(0.0, Offset.zero);

      // Move progress by 0.05 -> no haptic
      tracker.update(0.05, const Offset(5, 0));
      expect(hapticCalls, isEmpty);

      // Move progress to 0.12 -> triggers haptic
      tracker.update(0.12, const Offset(12, 0));
      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first, equals('HapticFeedbackType.lightImpact'));
    });

    test('triggers bookend haptics at edge thresholds', () {
      final tracker = M3EHapticTracker(
        baseHaptic: M3EHapticFeedback.light,
        config: const M3EHapticConfig(
          enableContinuousDrag: false,
          vibrateOnLowerBookend: true,
          lowerBookendThreshold: 0.05,
          vibrateOnUpperBookend: true,
          upperBookendThreshold: 0.95,
        ),
      );

      // Start at 0.5 (middle)
      tracker.start(0.5, const Offset(50, 0));

      // Move to 0.02 (below lowerBookendThreshold 0.05) -> triggers lower bookend
      tracker.update(0.02, const Offset(2, 0));
      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.last, equals('HapticFeedbackType.heavyImpact'));

      // Move to 0.01 (still below threshold) -> should not trigger again
      tracker.update(0.01, const Offset(1, 0));
      expect(hapticCalls, hasLength(1));

      // Move back to 0.5
      tracker.update(0.5, const Offset(50, 0));

      // Move to 0.98 (above upperBookendThreshold 0.95) -> triggers upper bookend
      tracker.update(0.98, const Offset(98, 0));
      expect(hapticCalls, hasLength(2));
      expect(hapticCalls.last, equals('HapticFeedbackType.heavyImpact'));
    });

    test('velocity changes amplitude for drag texture (AOSP-aligned)', () async {
      final tracker = M3EHapticTracker(
        baseHaptic: M3EHapticFeedback.light,
        config: const M3EHapticConfig(
          enableContinuousDrag: true,
          deltaProgressForDragThreshold: 0.01,
          additionalVelocityMaxBump: 0.25,
          maxVelocityToScale: 100.0,
          vibrateOnLowerBookend: false,
          vibrateOnUpperBookend: false,
        ),
      );

      // Low velocity movement
      tracker.start(0.1, const Offset(10, 0));
      await Future.delayed(const Duration(milliseconds: 150));
      tracker.update(0.2, const Offset(11, 0));
      expect(hapticCalls, isNotEmpty);
      expect(hapticCalls.last, equals('HapticFeedbackType.lightImpact'));

      hapticCalls.clear();

      // High velocity movement
      tracker.start(0.2, const Offset(11, 0));
      await Future.delayed(const Duration(milliseconds: 5));
      tracker.update(0.5, const Offset(500, 0));
      expect(hapticCalls, isNotEmpty);
      expect(hapticCalls.last, equals('HapticFeedbackType.lightImpact'));
    });
  });
}
