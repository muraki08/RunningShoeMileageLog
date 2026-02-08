import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:running_shoe_mileage_log/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ランニングシューズ記録'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}