import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

/// Unlocks the IRMA app and waits until the wallet is displayed.
Future<void> unlock(WidgetTester tester) async {
  await tester.enterTextAtFocusedAndSettle('12345');
  await tester.waitFor(find.byKey(const Key('wallet_present')));
}
