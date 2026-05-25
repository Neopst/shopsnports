// File: C:/projects/admin_dashboard/test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp()); // 👈 use MyApp not AdminApp
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
