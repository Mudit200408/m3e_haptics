// Copyright (c) 2026 Mudit Purohit
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:math' show pow;
import 'package:flutter/widgets.dart';

import 'm3e_haptic_engine.dart';
import 'm3e_haptic_types.dart';

@immutable
class M3EHapticConfig {
  final bool enableContinuousDrag;
  final double deltaProgressForDragThreshold;
  final bool vibrateOnLowerBookend;
  final bool vibrateOnUpperBookend;
  final double lowerBookendThreshold;
  final double upperBookendThreshold;
  final double progressBasedDragMinScale;
  final double progressBasedDragMaxScale;
  final double additionalVelocityMaxBump;
  final double maxVelocityToScale;

  const M3EHapticConfig({
    this.enableContinuousDrag = true,
    this.deltaProgressForDragThreshold = 0.015,
    this.vibrateOnLowerBookend = true,
    this.vibrateOnUpperBookend = true,
    this.lowerBookendThreshold = 0.01,
    this.upperBookendThreshold = 0.99,
    this.progressBasedDragMinScale = 0.10,
    this.progressBasedDragMaxScale = 0.85,
    this.additionalVelocityMaxBump = 0.25,
    this.maxVelocityToScale = 200.0,
  });

  const M3EHapticConfig.continuous() : this(
    enableContinuousDrag: true,
    deltaProgressForDragThreshold: 0.02,
    vibrateOnLowerBookend: true,
    vibrateOnUpperBookend: true,
    lowerBookendThreshold: 0.01,
    upperBookendThreshold: 0.99,
    progressBasedDragMinScale: 0.10,
    progressBasedDragMaxScale: 0.85,
    additionalVelocityMaxBump: 0.1,
    maxVelocityToScale: 200.0,
  );

  const M3EHapticConfig.discrete() : this(
    enableContinuousDrag: false,
    deltaProgressForDragThreshold: 0.0,
    vibrateOnLowerBookend: true,
    vibrateOnUpperBookend: true,
    lowerBookendThreshold: 0.0,
    upperBookendThreshold: 1.0,
    progressBasedDragMinScale: 0.20,
    progressBasedDragMaxScale: 0.50,
    additionalVelocityMaxBump: 0.20,
    maxVelocityToScale: 100.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is M3EHapticConfig &&
          enableContinuousDrag == other.enableContinuousDrag &&
          deltaProgressForDragThreshold == other.deltaProgressForDragThreshold &&
          vibrateOnLowerBookend == other.vibrateOnLowerBookend &&
          vibrateOnUpperBookend == other.vibrateOnUpperBookend &&
          lowerBookendThreshold == other.lowerBookendThreshold &&
          upperBookendThreshold == other.upperBookendThreshold &&
          progressBasedDragMinScale == other.progressBasedDragMinScale &&
          progressBasedDragMaxScale == other.progressBasedDragMaxScale &&
          additionalVelocityMaxBump == other.additionalVelocityMaxBump &&
          maxVelocityToScale == other.maxVelocityToScale;

  @override
  int get hashCode => Object.hash(
    enableContinuousDrag,
    deltaProgressForDragThreshold,
    vibrateOnLowerBookend,
    vibrateOnUpperBookend,
    lowerBookendThreshold,
    upperBookendThreshold,
    progressBasedDragMinScale,
    progressBasedDragMaxScale,
    additionalVelocityMaxBump,
    maxVelocityToScale,
  );
}

class M3EHapticTracker {
  final M3EHapticFeedback baseHaptic;
  final M3EHapticConfig config;

  double? _lastDragHapticProgress;
  bool _hasTriggeredLowerBookend = false;
  bool _hasTriggeredUpperBookend = false;
  DateTime? _lastDragTime;
  Offset? _lastDragPosition;
  double _currentVelocity = 0.0;

  M3EHapticTracker({
    this.baseHaptic = M3EHapticFeedback.none,
    this.config = const M3EHapticConfig(),
  });

  void start(double initialProgress, Offset globalPosition) {
    _lastDragHapticProgress = initialProgress;
    _hasTriggeredLowerBookend = false;
    _hasTriggeredUpperBookend = false;
    _lastDragTime = DateTime.now();
    _lastDragPosition = globalPosition;
    _currentVelocity = 0.0;
  }

  void update(double currentProgress, Offset globalPosition) {
    final now = DateTime.now();
    if (_lastDragTime != null && _lastDragPosition != null) {
      final dt = now.difference(_lastDragTime!).inMicroseconds / 1000000.0;
      if (dt > 0.001) {
        final dx = (globalPosition - _lastDragPosition!).distance;
        _currentVelocity = dx / dt;
        _lastDragTime = now;
        _lastDragPosition = globalPosition;
      }
    } else {
      _lastDragTime = now;
      _lastDragPosition = globalPosition;
    }

    _performHapticFeedback(currentProgress);
  }

  void triggerTick(double progress) {
    if (baseHaptic == M3EHapticFeedback.none) return;
    final amplitude = _computeAmplitude(progress, config.progressBasedDragMinScale, config.progressBasedDragMaxScale);
    applyTypedHaptic('tickCrossing', amplitude);
  }

  void _performHapticFeedback(double progress) {
    if (baseHaptic == M3EHapticFeedback.none) return;

    if (config.vibrateOnLowerBookend && progress <= config.lowerBookendThreshold) {
      if (!_hasTriggeredLowerBookend) {
        _hasTriggeredLowerBookend = true;
        applyTypedHaptic('bookendLower', 1.0);
      }
      return;
    } else {
      _hasTriggeredLowerBookend = false;
    }

    if (config.vibrateOnUpperBookend && progress >= config.upperBookendThreshold) {
      if (!_hasTriggeredUpperBookend) {
        _hasTriggeredUpperBookend = true;
        applyTypedHaptic('bookendUpper', 1.0);
      }
      return;
    } else {
      _hasTriggeredUpperBookend = false;
    }

    if (config.enableContinuousDrag && _lastDragHapticProgress != null) {
      final delta = (progress - _lastDragHapticProgress!).abs();
      if (delta >= config.deltaProgressForDragThreshold) {
        _lastDragHapticProgress = progress;
        final amplitude = _computeAmplitude(
          progress,
          config.progressBasedDragMinScale,
          config.progressBasedDragMaxScale,
        );
        applyTypedHaptic('dragTexture', amplitude);
      }
    }
  }

  double _computeAmplitude(double progress, double minScale, double maxScale) {
    const exponent = 0.80;
    final t = progress.clamp(0.0, 1.0);
    final progressScale = minScale + (maxScale - minScale) * pow(t, exponent).toDouble();
    final velocityFraction = (_currentVelocity / config.maxVelocityToScale).clamp(0.0, 1.0);
    final velocityBump = config.additionalVelocityMaxBump * velocityFraction;

    return (progressScale + velocityBump).clamp(0.0, 1.0);
  }
}
