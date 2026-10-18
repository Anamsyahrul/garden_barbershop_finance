import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_barbershop_finance/screens/operasional_screen.dart';

void main() {
  testWidgets('OperasionalScreen layout test', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print("===== FLUTTER ERROR CAUGHT =====");
      print(details.exceptionAsString());
      print(details.stack.toString());
      print("================================");
    };
    
    await tester.pumpWidget(const MaterialApp(
      home: OperasionalScreen(),
    ));
    await tester.pump();
  });
}
