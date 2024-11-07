import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'special_scenarios/attribute_order.dart';
import 'special_scenarios/combined_disclosure_issuance.dart';
import 'special_scenarios/decline_disclosure.dart';
import 'special_scenarios/nullables.dart';
import 'special_scenarios/random_blind.dart';
import 'special_scenarios/revocation.dart';
import 'special_scenarios/signing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('disclosure-session', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group('special-scenarios', () {
      // Session with an optional attribute that cannot be null
      testWidgets(
        'nullables',
            (tester) => nullablesTest(
          tester,
          irmaBinding,
        ),
      );

      // Disclosure session and signing a message
      testWidgets(
        'signing',
            (tester) => signingTest(
          tester,
          irmaBinding,
        ),
      );

      // Issuance and disclosure in one session
      testWidgets(
        'combined-disclosure-issuance-session',
            (tester) => combinedDisclosureIssuanceSessionTest(
          tester,
          irmaBinding,
        ),
      );

      // Entering a session with a revoked credential
      testWidgets(
        'revocation',
            (tester) => revocationTest(
          tester,
          irmaBinding,
        ),
      );

      // Address from municipality with different attribute order
      testWidgets(
        'attribute-order',
            (tester) => attributeOrderTest(
          tester,
          irmaBinding,
        ),
      );

      // Disclosing stempas credential which is an unobtainable credential (no IssueURL) and contains a random blind attribute.
      testWidgets(
        'random-blind',
            (tester) => randomBlindTest(
          tester,
          irmaBinding,
        ),
      );

      // Decline disclosure at the last moment
      testWidgets(
        'decline-disclosure',
            (tester) => declineDisclosure(
          tester,
          irmaBinding,
        ),
      );
    });
  });
}
