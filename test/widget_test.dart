import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/main.dart';

void main() {
  testWidgets('App launches and shows Discover', (tester) async {
    await tester.pumpWidget(const WayfarerApp());
    expect(find.text('Wayfarer'), findsOneWidget);
  });
}