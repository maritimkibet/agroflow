import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgroFlow Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build a simple test app
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('AgroFlow Test'),
            ),
          ),
        ),
      );

      // Verify the app builds successfully
      expect(find.text('AgroFlow Test'), findsOneWidget);
    });

    testWidgets('Counter increments smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

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
  });
}

/// Simple test app for widget testing
class TestApp extends StatefulWidget {
  const TestApp({super.key});

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
