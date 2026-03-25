import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_bronnen/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MijnBronnenApp());
    expect(find.text('MijnBronnen'), findsAny);
  });
}
