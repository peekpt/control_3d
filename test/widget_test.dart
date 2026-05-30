import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:control_3d/app.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Control3DApp()));
    expect(find.text('Control 3D'), findsOneWidget);
  });
}
