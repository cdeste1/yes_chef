import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_chef/main.dart';

void main() {
  testWidgets('App launches and shows the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    expect(find.text('Cook Bold. Elevate Your Dish.'), findsOneWidget);

    // Flush the splash screen's navigation timer so it doesn't leak into the next test.
    await tester.pump(const Duration(seconds: 3));
  });
}
