import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gasplit/app.dart';

void main() {
  testWidgets('shows auth placeholder on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    expect(
      find.text('Sign in with Google or email/password to continue.'),
      findsOneWidget,
    );
  });
}
