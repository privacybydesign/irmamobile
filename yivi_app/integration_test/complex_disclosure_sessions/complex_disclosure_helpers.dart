import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../disclose_sdjwt_over_openid4vp_test.dart"
    show navigateToLatestActivity, startOpenID4VPSession;
import "../disclosure_session/disclosure_helpers.dart";
import "../helpers/issuance_helpers.dart";
import "../irma_binding.dart";
import "../util.dart";

// The complex disclosure cases of the build plan (6.3): DCQL requests over
// OpenID4VP for the demo e-mail and mobile cards, which Yivi issues as
// SD-JWT (so several of a kind can be in the app, and they can be added from
// a request).

const emailVct = "irma-demo.sidn-pbdf.email";
const mobileVct = "irma-demo.sidn-pbdf.mobilenumber";
const emailId = "irma-demo.sidn-pbdf.email";
const mobileId = "irma-demo.sidn-pbdf.mobilenumber";

/// A DCQL query [id] for a card of [vct] asking [paths]; [values] limits
/// the first path to those values.
Map<String, dynamic> query(
  String id,
  String vct, {
  List<String> paths = const [],
  List<String>? values,
  bool multiple = false,
}) => {
  "id": id,
  "format": "dc+sd-jwt",
  "meta": {
    "vct_values": [vct],
  },
  if (multiple) "multiple": true,
  if (paths.isNotEmpty)
    "claims": [
      for (final (i, p) in paths.indexed)
        {
          "id": "${id}_$i",
          "path": [p],
          if (i == 0 && values != null) "values": values,
        },
    ],
};

Map<String, dynamic> mailQuery(String id, {List<String>? values}) => query(
  id,
  emailVct,
  paths: values == null ? ["email"] : ["domain"],
  values: values,
);

Map<String, dynamic> domainQuery(String id) =>
    query(id, emailVct, paths: ["domain"]);

Map<String, dynamic> phoneQuery(String id) =>
    query(id, mobileVct, paths: ["mobilenumber"]);

/// Issues one e-mail card per address, each from its own domain.
Future<void> issueEmails(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  List<String> emails,
) async {
  for (final e in emails) {
    await issueEmailAddress(
      tester,
      irmaBinding,
      sdJwtBatchSize: 10,
      email: e,
      domain: e.split("@").last,
    );
  }
}

Future<void> issuePhones(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  List<String> phones,
) async {
  for (final p in phones) {
    await issueMobileNumber(tester, irmaBinding, phone: p, sdJwtBatchSize: 10);
  }
}

/// Starts [dcql] with the EUDI verifier and waits for the request.
Future<void> startDcql(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, dynamic> dcql,
) async {
  final url = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(url);
  await waitForRequest(tester);
  await tester.pumpAndSettle();
}

/// The values shown in the overview's lists: the required one and one per
/// shared optional choice.
Finder inValues(String text) => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w.key == const Key("share_values") ||
        (w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              "share_optional_card_",
            )),
  ),
  matching: find.text(text),
);

/// Opens "Which card do you share?" of [slotId] in choice [i] from the
/// change page.
Future<void> pickInSlot(
  WidgetTester tester,
  int i,
  String slotId,
  String value,
) async {
  await openChangePage(tester);
  final link = find.byKey(Key("change_pick_slot_${i}_$slotId"));
  await tester.ensureVisible(link);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(link);
  await pickOwned(tester, value);
}

/// Opens the most recent activity entry and checks [values] are in it, and
/// [notShared] are not.
Future<void> expectInLatestActivity(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  List<String> values, {
  List<String> notShared = const [],
}) async {
  await navigateToLatestActivity(tester, irmaBinding);
  for (final v in values) {
    expect(find.textContaining(v), findsWidgets, reason: "'$v' in activity");
  }
  for (final v in notShared) {
    expect(find.textContaining(v), findsNothing, reason: "'$v' not shared");
  }
}
