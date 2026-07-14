// Copyright (c) 2026 Mudit Purohit
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:m3e_haptics/m3e_haptics.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M3E Haptics Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
          surface: const Color(0xFF141218),
        ),
      ),
      home: const HapticsDemoScreen(),
    );
  }
}

class HapticsDemoScreen extends StatefulWidget {
  const HapticsDemoScreen({super.key});

  @override
  State<HapticsDemoScreen> createState() => _HapticsDemoScreenState();
}

class _HapticsDemoScreenState extends State<HapticsDemoScreen> {
  // Slider values
  double _sliderValue = 0.5;
  M3EHapticTracker? _sliderTracker;

  // Slider Config Controls
  bool _enableContinuousDrag = true;
  bool _vibrateOnBookends = true;
  double _dragThreshold = 0.015;

  // Loader state
  double _loaderProgress = 0.0;
  bool _isLoaderRunning = false;
  M3EHapticTracker? _loaderTracker;

  // Swipe items state
  final List<String> _swipeItems =
      List.generate(4, (i) => 'Tactile Card Item #${i + 1}');
  final Map<String, double> _swipeProgress = {};
  final Map<String, M3EHapticTracker> _swipeTrackers = {};

  @override
  void initState() {
    super.initState();
    _initSliderTracker();
  }

  void _initSliderTracker() {
    _sliderTracker = M3EHapticTracker(
      baseHaptic: M3EHapticFeedback.light,
      config: M3EHapticConfig(
        enableContinuousDrag: _enableContinuousDrag,
        vibrateOnLowerBookend: _vibrateOnBookends,
        vibrateOnUpperBookend: _vibrateOnBookends,
        deltaProgressForDragThreshold: _dragThreshold,
        lowerBookendThreshold: 0.01,
        upperBookendThreshold: 0.99,
      ),
    );
  }

  M3EHapticTracker _createLoaderTracker() {
    return M3EHapticTracker(
      baseHaptic: M3EHapticFeedback.light,
      config: const M3EHapticConfig(
        enableContinuousDrag: true,
        deltaProgressForDragThreshold: 0.05,
        vibrateOnLowerBookend: true,
        vibrateOnUpperBookend: true,
        lowerBookendThreshold: 0.01,
        upperBookendThreshold: 0.99,
      ),
    );
  }

  M3EHapticTracker _createSwipeTracker() {
    return M3EHapticTracker(
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
  }

  // Simulate loader progress
  void _runLoader() async {
    if (_isLoaderRunning) return;
    setState(() {
      _isLoaderRunning = true;
      _loaderProgress = 0.0;
    });

    _loaderTracker = _createLoaderTracker();

    while (_loaderProgress < 1.0 && _isLoaderRunning) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || !_isLoaderRunning) break;
      setState(() {
        _loaderProgress = (_loaderProgress + 0.05).clamp(0.0, 1.0);
      });
    }

    setState(() {
      _isLoaderRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('M3E Haptics Showcase'),
        centerTitle: true,
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Slider Haptic Integration Demo
            _buildSliderDemoSection(cs),
            const SizedBox(height: 16),

            // 2. Determinate Loader Demo
            _buildLoaderDemoSection(cs),
            const SizedBox(height: 16),

            // 3. Swipe-to-Dismiss Resistance Demo
            _buildSwipeDemoSection(cs),
            const SizedBox(height: 16),

            // 4. Raw Composition Presets
            _buildPresetsSection(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderDemoSection(ColorScheme cs) {
    return _buildCardWrapper(
      title: 'Interactive AOSP Slider',
      subtitle:
          'Continuous drag textures, dynamic velocity bumps, and bookends.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volume / Progress Level: ${(_sliderValue * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Swipe the slider handle back and forth',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          M3EHapticListener(
            tracker: _sliderTracker!,
            progress: _sliderValue,
            child: Slider(
              value: _sliderValue,
              onChanged: (val) {
                setState(() {
                  _sliderValue = val;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          // Config controls
          SwitchListTile(
            title: const Text('Continuous Drag Haptics'),
            subtitle: const Text('Subtle LOW_TICK feedback on movement'),
            value: _enableContinuousDrag,
            onChanged: (val) {
              setState(() => _enableContinuousDrag = val);
              _initSliderTracker();
            },
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Lower/Upper Bookend haptics'),
            subtitle: const Text('Firm CLICK boundary hit feels'),
            value: _vibrateOnBookends,
            onChanged: (val) {
              setState(() => _vibrateOnBookends = val);
              _initSliderTracker();
            },
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            title: const Text('Drag Tick Interval'),
            subtitle: Text(
                'Distance threshold: ${_dragThreshold.toStringAsFixed(3)}'),
            contentPadding: EdgeInsets.zero,
            trailing: SizedBox(
              width: 140,
              child: Slider(
                value: _dragThreshold,
                min: 0.005,
                max: 0.05,
                divisions: 9,
                onChanged: _enableContinuousDrag
                    ? (val) {
                        setState(() => _dragThreshold = val);
                        _initSliderTracker();
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaderDemoSection(ColorScheme cs) {
    return _buildCardWrapper(
      title: 'Determinate Loading Stream',
      subtitle: 'Vibrates incrementally matching loading states.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              M3EHapticListener(
                tracker: _loaderTracker ?? _createLoaderTracker(),
                progress: _loaderProgress,
                listenToPointer: false,
                child: CircularProgressIndicator(
                  value: _loaderProgress,
                  strokeWidth: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Loading progress: ${(_loaderProgress * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoaderRunning ? null : _runLoader,
                      child: Text(_isLoaderRunning
                          ? 'Loading...'
                          : 'Start Loading Progress'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeDemoSection(ColorScheme cs) {
    return _buildCardWrapper(
      title: 'Swipe Resistance Haptics',
      subtitle:
          'Continuous drag texture increases amplitude as card is swiped.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Swipe card items horizontally. You will feel increasing tick vibration intensity as you pull further away from the center.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _swipeItems.length,
            itemBuilder: (context, index) {
              final item = _swipeItems[index];
              final tracker = _swipeTrackers.putIfAbsent(
                item,
                _createSwipeTracker,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: M3EHapticListener(
                  tracker: tracker,
                  progress: _swipeProgress[item] ?? 0.0,
                  child: Dismissible(
                    key: ValueKey(item),
                    onUpdate: (details) {
                      setState(() {
                        _swipeProgress[item] = details.progress;
                      });
                    },
                    onDismissed: (_) {
                      setState(() {
                        _swipeItems.removeAt(index);
                        _swipeProgress.remove(item);
                        _swipeTrackers.remove(item);
                      });
                    },
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.swipe, color: cs.primary),
                        title: Text(item),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_swipeItems.isEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _swipeItems.addAll(
                      List.generate(4, (i) => 'Tactile Card Item #${i + 1}'));
                  _swipeProgress.clear();
                  _swipeTrackers.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Swipeable List'),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(ColorScheme cs) {
    return _buildCardWrapper(
      title: 'Raw Composition Taps',
      subtitle: 'Fire standalone haptic compositions directly.',
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.touch_app),
            label: const Text('Subtle Tick (0.3)'),
            onPressed: () => applyTypedHaptic('tickCrossing', 0.3),
          ),
          ActionChip(
            avatar: const Icon(Icons.touch_app),
            label: const Text('Standard Tick (0.6)'),
            onPressed: () => applyTypedHaptic('tickCrossing', 0.6),
          ),
          ActionChip(
            avatar: const Icon(Icons.touch_app),
            label: const Text('Composed Drag burst'),
            onPressed: () => applyTypedHaptic('dragTexture', 0.7),
          ),
          ActionChip(
            avatar: const Icon(Icons.touch_app),
            label: const Text('Upper Bookend Click'),
            onPressed: () => applyTypedHaptic('bookendUpper', 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      color: const Color(0xFF25232A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
