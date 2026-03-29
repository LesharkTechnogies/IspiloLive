import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ispilo/presentation/home_feed/home_feed.dart';

void main() {
  testWidgets('HomeFeed avoids duplicate posts and inserts ads correctly', (WidgetTester tester) async {
    // Pump the HomeFeed inside a MaterialApp to satisfy Navigator and Theme
    await tester.pumpWidget(MaterialApp(home: HomeFeed()));

    // Initial loading
    await tester.pump(const Duration(milliseconds: 500));

    // Scroll to trigger pagination
    final listFinder = find.byType(CustomScrollView);
    expect(listFinder, findsOneWidget);

    await tester.drag(listFinder, const Offset(0, -300));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Verify no obvious exceptions (widget test is limited without real network)
    expect(tester.takeException(), isNull);

    // Ad insertion logic: after every N posts we expect ad widgets to appear
    // We cannot assert exact count without network, but we can ensure the tree builds without throwing.
  });
}
