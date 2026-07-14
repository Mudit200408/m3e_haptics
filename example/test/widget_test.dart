// Copyright (c) 2026 Mudit Purohit
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_haptics_example/main.dart';

void main() {
  testWidgets('Haptics example app renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('M3E Haptics Showcase'), findsOneWidget);
  });
}
