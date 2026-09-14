import 'package:flutter_test/flutter_test.dart';
import 'package:shinra_core/main.dart';

void main() {
  testWidgets('Shinra app boots', (tester) async {
    await tester.pumpWidget(const ShinraApp());
    expect(find.text('SHINRA CORE'), findsWidgets);
  });
}
