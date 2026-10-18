import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_barbershop_finance/screens/operasional_screen.dart';

void main() {
  testWidgets('OperasionalScreen layout test', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      throw details.exception;
    };
    
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OperasionalScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    
    expect(find.byType(OperasionalScreen), findsOneWidget);
  });
}
