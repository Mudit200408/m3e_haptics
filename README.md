# M3E Haptics

A Flutter package providing expressive, high-fidelity AOSP-aligned native haptic feedback compositions for Flutter. It enables continuous drag textures, dynamic velocity bumps, snap-to-tick behaviors, and bookend feedback using native Android haptic compositions (`PRIMITIVE_LOW_TICK`, `PRIMITIVE_TICK`, and `PRIMITIVE_CLICK`) with automatic fallbacks for iOS, Web, and desktop platforms.

> [!NOTE]
> `m3e_haptics` is a part of the larger **[m3e_core](https://github.com/Mudit200408/m3e_core)** ecosystem.

---

## 🎮 Interactive Demo

You can try out the package UI demo here: [m3e_core demo](https://mudit200408.github.io/m3e_core/)

> [!IMPORTANT]
> **To experience the high-fidelity native haptic effects, you must run the example app on an Android device.**
> The web demo above allows you to check the UI and layout of the various `m3e` components, but does not support hardware haptic playback.

---

## 🚀 Features

- **Continuous Drag Textures** — fine-grained micro-vibrations (`PRIMITIVE_LOW_TICK`) while dragging sliders, sheets, or list items.
- **Dynamic Velocity Bumps** — vibration amplitude dynamically adjusts based on the swipe/drag velocity.
- **Bookend/Boundary Snaps** — distinct click feedback (`PRIMITIVE_CLICK`) when hitting the minimum (0%) or maximum (100%) limits of a widget.
- **Progress-Based Intensity Ramp** — scale tactile feedback amplitude dynamically as progress changes (e.g. stronger resistance as you swipe further).
- **Graceful Fallbacks** — automatically falls back to standard iOS/Web haptic patterns (`lightImpact`, `mediumImpact`, `heavyImpact`) on unsupported platforms.
- **M3EHapticTracker Helper** — an easy-to-use controller class to track interaction positions, speeds, and bounds in custom widgets.

---

## 📦 Installation

```yaml
dependencies:
  m3e_haptics: ^0.0.1
```

```dart
import 'package:m3e_haptics/m3e_haptics.dart';
```

---

## 🧩 Quick Start

### 1. Button Tap

For simple tap/click feedback, call `M3EHapticFeedback` directly inside your button callback:

```dart
FilledButton(
  onPressed: () {
    M3EHapticFeedback.light.apply();
    saveChanges();
  },
  child: const Text('Save'),
)
```

Use heavier feedback for more prominent actions:

```dart
IconButton(
  onPressed: () {
    M3EHapticFeedback.heavy.apply();
    deleteItem();
  },
  icon: const Icon(Icons.delete),
)
```

### 2. Slider Drag

Wrap the slider with `M3EHapticListener`. It handles pointer tracking and progress updates, so you do not need to manually wire `Listener`, `onPointerDown`, or `onPointerMove`.

```dart
class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double _value = 0.5;

  final _tracker = M3EHapticTracker(
    baseHaptic: M3EHapticFeedback.light,
    config: const M3EHapticConfig.continuous(),
  );

  @override
  Widget build(BuildContext context) {
    return M3EHapticListener(
      tracker: _tracker,
      progress: _value,
      child: Slider(
        value: _value,
        onChanged: (value) {
          setState(() => _value = value);
        },
      ),
    );
  }
}
```

### 3. Dismissible / Swipe Action

Use `M3EHapticListener` with `Dismissible.onUpdate` to create resistance-style feedback as the card moves.

```dart
class HapticDismissibleTile extends StatefulWidget {
  final String id;
  final Widget child;
  final VoidCallback onDismissed;

  const HapticDismissibleTile({
    super.key,
    required this.id,
    required this.child,
    required this.onDismissed,
  });

  @override
  State<HapticDismissibleTile> createState() => _HapticDismissibleTileState();
}

class _HapticDismissibleTileState extends State<HapticDismissibleTile> {
  double _progress = 0.0;

  final _tracker = M3EHapticTracker(
    baseHaptic: M3EHapticFeedback.light,
    config: const M3EHapticConfig(
      enableContinuousDrag: true,
      deltaProgressForDragThreshold: 0.04,
      vibrateOnLowerBookend: false,
      vibrateOnUpperBookend: false,
      progressBasedDragMinScale: 0.10,
      progressBasedDragMaxScale: 0.85,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return M3EHapticListener(
      tracker: _tracker,
      progress: _progress,
      child: Dismissible(
        key: ValueKey(widget.id),
        onUpdate: (details) {
          setState(() => _progress = details.progress);
        },
        onDismissed: (_) => widget.onDismissed(),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: widget.child,
      ),
    );
  }
}
```

### 4. Determinate Loader

For non-pointer-driven progress, disable pointer listening and pass the current progress value.

```dart
class HapticProgressIndicator extends StatelessWidget {
  final double progress;

  HapticProgressIndicator({
    super.key,
    required this.progress,
  });

  final _tracker = M3EHapticTracker(
    baseHaptic: M3EHapticFeedback.light,
    config: const M3EHapticConfig(
      enableContinuousDrag: true,
      deltaProgressForDragThreshold: 0.05,
      vibrateOnLowerBookend: true,
      vibrateOnUpperBookend: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return M3EHapticListener(
      tracker: _tracker,
      progress: progress,
      listenToPointer: false,
      child: CircularProgressIndicator(value: progress),
    );
  }
}
```

### 5. Custom Typed Haptic with Amplitude Control

Directly invoke specific Android compositions with pre-calculated amplitudes from `0.0` to `1.0`:

```dart
// Play custom drag texture with 70% amplitude.
applyTypedHaptic('dragTexture', 0.7);

// Play upper bookend click at max strength.
applyTypedHaptic('bookendUpper', 1.0);
```

---

## 📖 Detailed API Guide

### 1. `M3EHapticFeedback`

Predefined feedback levels representing general haptic intensities:

| Level | Value | Underlying Android Action | iOS/Web Fallback |
|-------|-------|--------------------------|------------------|
| `none` | `0` | None | None |
| `light` | `1` | `dragTexture` (0.5 amp) | `lightImpact` |
| `medium` | `2` | `tickCrossing` (0.5 amp) | `mediumImpact` |
| `heavy` | `3` | `bookendUpper` (0.5 amp) | `heavyImpact` |

```dart
M3EHapticFeedback.medium.apply();
```

---

### 2. `M3EHapticConfig`

Configuration parameters for custom haptic tracking and feedback behavior.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableContinuousDrag` | `bool` | `true` | Enables micro-ticks during movement. |
| `deltaProgressForDragThreshold` | `double` | `0.015` | Minimum progress change required to trigger a drag tick. |
| `vibrateOnLowerBookend` | `bool` | `true` | Trigger click vibration when hitting the bottom boundary. |
| `vibrateOnUpperBookend` | `bool` | `true` | Trigger click vibration when hitting the top boundary. |
| `lowerBookendThreshold` | `double` | `0.01` | Progress threshold for the lower bookend trigger. |
| `upperBookendThreshold` | `double` | `0.99` | Progress threshold for the upper bookend trigger. |
| `progressBasedDragMinScale` | `double` | `0.10` | The minimum amplitude scale for drag micro-ticks. |
| `progressBasedDragMaxScale` | `double` | `0.85` | The maximum amplitude scale for drag micro-ticks. |
| `additionalVelocityMaxBump` | `double` | `0.25` | Extra amplitude added dynamically at maximum velocity. |
| `maxVelocityToScale` | `double` | `200.0` | Target velocity (px/sec) representing the maximum bump. |

#### 🏗️ Built-in Config Presets

* **`M3EHapticConfig.continuous()`** — Tailored for continuous components like sliders.
* **`M3EHapticConfig.discrete()`** — Tailored for discrete segments/tick-snaps.

```dart
const config = M3EHapticConfig.continuous();
```

---

### 3. `M3EHapticTracker`

A lifecycle tracker class that manages drag positions, velocities, and triggers haptics at specific thresholds.

#### Methods

* **`void start(double initialProgress, Offset globalPosition)`** — Initializes tracking state when user interaction begins.
* **`void update(double currentProgress, Offset globalPosition)`** — Updates tracker state, calculates gesture velocity, and automatically dispatches boundary or drag micro-tick events based on configuration.
* **`void triggerTick(double progress)`** — Forces a standalone tick event using the progress-scaled amplitude.

```dart
final tracker = M3EHapticTracker(
  baseHaptic: M3EHapticFeedback.light,
  config: const M3EHapticConfig.continuous(),
);
```

---

### 4. `M3EHapticListener`

A generic wrapper for progress-driven widgets. It tracks pointer position and progress changes for you, so the same wrapper can be used around sliders, swipe actions, loaders, and custom controls.

```dart
M3EHapticListener(
  tracker: tracker,
  progress: progress,
  child: child,
);
```

---

### 5. Engine Functions

Low-level static functions for direct haptic invocation.

```dart
/// Trigger predefined haptic
void applyHaptic(M3EHapticFeedback haptic);

/// Dispatch raw composition by ID with specific amplitude (0.0 to 1.0)
void applyTypedHaptic(String type, double amplitude);
```

Available Type IDs:
* `'dragTexture'`
* `'tickCrossing'`
* `'bookendLower'`
* `'bookendUpper'`

---

## 🐞 Found a bug? or ✨ You have a Feature Request?

Feel free to open an [Issue](https://github.com/Mudit200408/m3e_haptics/issues) or [Contribute](https://github.com/Mudit200408/m3e_haptics/pulls) to the project.

Hope You Love It!

---

### Radhe Radhe 🙏
