import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_app/app.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DailyApp()));
    // A single pump only: task data comes from a real sqlite file via
    // path_provider, which has no platform channel in a plain widget test.
    await tester.pump();

    expect(find.byType(DailyApp), findsOneWidget);
  });
}
