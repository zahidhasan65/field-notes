import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app.dart';

void main() {
  testWidgets('Field Notes app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldNotesApp());

    expect(find.text('Field Notes'), findsOneWidget);
  });
}
