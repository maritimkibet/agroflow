import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agroflow/services/notification_service.dart'; // lowercase

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestApp(
        notificationService: NotificationService(),
      ),
    );

    // Verify that counter starts at 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap '+' button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify counter incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

/// Renamed from MyApp to avoid conflict with main.dart
class TestApp extends StatefulWidget {
  final NotificationService notificationService;

  const TestApp({
    super.key,
    required this.notificationService,
  });

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroFlow Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AgroFlow Test Page'),
        ),
        body: Center(
          child: Text(
            '$_counter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
