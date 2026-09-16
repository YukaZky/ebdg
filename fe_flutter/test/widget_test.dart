import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fe_flutter/main.dart';

void main() {
  testWidgets('GeoDesaConnect app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        title: 'GeoDesaConnect',
        home: Scaffold(body: Text('GeoDesaConnect')),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'GeoDesaConnect');
    expect(find.text('GeoDesaConnect'), findsOneWidget);
  });
}
