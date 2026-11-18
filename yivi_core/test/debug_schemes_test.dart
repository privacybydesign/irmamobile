// The debug screens over the schemes: the scheme list, a scheme's details, a
// requestor scheme's details, and the issuance requests the debug screen
// builds from the credential types.
import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/scheme_rules.dart";
import "package:yivi_core/src/screens/debug/debug_helper.dart";
import "package:yivi_core/src/screens/debug/debug_schemes.dart";
import "package:yivi_core/src/screens/debug/scheme_management/scheme_management_screen.dart";
import "package:yivi_core/src/screens/debug/scheme_management/scheme_manager_detail_screen.dart";
import "package:yivi_core/src/screens/debug/session/portrait_photo_mock.dart";
import "package:yivi_core/src/widgets/active_indicator.dart";

import "support/onboarding_v2_harness.dart";

Map<String, dynamic> _schemeManager(
  String id, {
  bool demo = false,
  String keyshareServer = "",
  String timestampServer = "",
}) => {
  "id": id,
  "demo": demo,
  "timestamp": 1700000000,
  "keyshare_server": keyshareServer,
  "timestamp_server": timestampServer,
};

Map<String, dynamic> _credentialType(
  String id,
  List<String> attributes, {
  Map<String, String> displayHints = const {},
}) => {
  "id": id,
  "scheme_manager_id": id.split(".").first,
  "name": {"en": id.split(".").last},
  "attributes": [
    for (final attribute in attributes)
      {
        "id": attribute,
        "name": {"en": attribute},
        "display_hint": ?displayHints[attribute],
      },
  ],
};

/// What Go answers a request for the schemes with, as JSON; each list
/// sorted by id.
final _schemesJson = <String, dynamic>{
  "scheme_managers": [
    _schemeManager("irma-demo", demo: true),
    _schemeManager(
      "pbdf",
      keyshareServer: "https://keyshare.example.com",
      timestampServer: "https://timestamp.example.com",
    ),
    _schemeManager(
      "pbdf-staging",
      keyshareServer: "https://keyshare-staging.example.com",
    ),
  ],
  "requestor_schemes": [
    {"id": "irma-demo-requestors", "demo": true},
    {"id": "pbdf-requestors", "demo": false},
  ],
  "credential_types": [
    _credentialType(
      "irma-demo.digidproef.personalData",
      ["initials", "photo", "surname"],
      displayHints: {"photo": "portraitPhoto"},
    ),
    _credentialType("irma-demo.gemeente.address", ["city", "street"]),
    _credentialType("pbdf.pbdf.email", ["domain", "email"]),
  ],
};

DebugHelper _debugHelper() =>
    DebugHelper(schemes: DebugSchemes.fromJson(_schemesJson));

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    bridge.deliver(
      EnrollmentStatusEvent(
        enrolledSchemeManagerIds: ["pbdf"],
        unenrolledSchemeManagerIds: ["pbdf-staging"],
      ),
    );
    bridge.respond = (event) => event is RequestDebugSchemesEvent
        ? DebugSchemesEvent.fromJson(_schemesJson)
        : null;
  });
  tearDown(() => repo.close());

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    phone(tester);
    await pumpHome(tester, repo: repo, home: screen);
    await settle(tester);
    await tester.pumpAndSettle();
  }

  /// The active dot in the row of [id], or null when it has none.
  bool? activeDot(WidgetTester tester, String id) {
    final dot = find.descendant(
      of: find.widgetWithText(ListTile, id),
      matching: find.byType(ActiveIndicator),
    );
    if (dot.evaluate().isEmpty) return null;
    return tester.widget<ActiveIndicator>(dot).isActive;
  }

  testWidgets("18. scheme management lists the schemes", (tester) async {
    await pump(tester, SchemeManagementScreen());

    expect(find.text("Issuer schemes"), findsOneWidget);
    for (final id in ["pbdf", "irma-demo", "pbdf-staging"]) {
      expect(find.widgetWithText(ListTile, id), findsOneWidget);
    }
    // A dot only where a keyshare server is set, lit when enrolled.
    expect(activeDot(tester, "pbdf"), isTrue);
    expect(activeDot(tester, "pbdf-staging"), isFalse);
    expect(activeDot(tester, "irma-demo"), isNull);

    expect(find.text("Requestor schemes"), findsOneWidget);
    expect(find.text("pbdf-requestors"), findsOneWidget);
    expect(find.text("irma-demo-requestors"), findsOneWidget);

    // A requestor scheme's details say what kind it is.
    await tester.tap(find.text("irma-demo-requestors"));
    await tester.pumpAndSettle();
    expect(find.text("Demo requestor scheme"), findsOneWidget);
  });

  group("19. a scheme's details", () {
    testWidgets("an enrolled scheme with both servers", (tester) async {
      await pump(tester, const SchemeManagerDetailScreen("pbdf"));

      expect(find.text("Status"), findsOneWidget);
      expect(find.text("Production scheme"), findsOneWidget);
      expect(find.textContaining("Timestamp 1700000000"), findsOneWidget);
      expect(find.text("https://keyshare.example.com"), findsOneWidget);
      expect(find.text("https://timestamp.example.com"), findsOneWidget);
      expect(find.text("Verify PIN"), findsOneWidget);
      expect(find.text("Activate"), findsNothing);
    });

    testWidgets("an unenrolled scheme without a timestamp server", (
      tester,
    ) async {
      await pump(tester, const SchemeManagerDetailScreen("pbdf-staging"));

      expect(find.text("https://keyshare-staging.example.com"), findsOneWidget);
      expect(find.text("(none)"), findsOneWidget);
      expect(find.text("Activate"), findsOneWidget);
      expect(find.text("Verify PIN"), findsNothing);
    });

    testWidgets("a demo scheme without servers", (tester) async {
      await pump(tester, const SchemeManagerDetailScreen("irma-demo"));

      expect(find.text("Status"), findsNothing);
      expect(find.text("Demo scheme"), findsOneWidget);
      expect(find.text("(none)"), findsNWidgets(2));
      expect(find.text("Activate"), findsNothing);
      expect(find.text("Verify PIN"), findsNothing);
    });
  });

  group("20. debug issuance requests", () {
    const demoAttributes = {
      "irma-demo.digidproef.personalData": {"initials", "surname", "photo"},
      "irma-demo.gemeente.address": {"street", "city"},
    };

    List<Map<String, dynamic>> credentials(String request) {
      final json = jsonDecode(request) as Map<String, dynamic>;
      expect(json["@context"], "https://irma.app/ld/request/issuance/v2");
      return (json["credentials"] as List).cast<Map<String, dynamic>>();
    }

    test("random issuance uses irma-demo types with all attributes", () async {
      // Random picks: ask often enough to see more than one.
      for (var i = 0; i < 10; i++) {
        final requested = credentials(
          await _debugHelper().randomIssuanceRequest(2),
        );
        expect(requested, hasLength(2));
        for (final credential in requested) {
          final id = credential["credential"] as String;
          expect(demoAttributes.keys, contains(id));
          final attributes = credential["attributes"] as Map<String, dynamic>;
          expect(attributes.keys.toSet(), demoAttributes[id]);
        }
      }
    });

    test("DigiD proef puts the portrait in the portrait attribute", () async {
      final requested = credentials(
        await _debugHelper().digidProefIssuanceRequest(),
      );
      expect(requested, hasLength(1));
      expect(
        requested.single["credential"],
        "irma-demo.digidproef.personalData",
      );
      final attributes = requested.single["attributes"] as Map<String, dynamic>;
      expect(attributes.keys.toSet(), {"initials", "surname", "photo"});
      expect(attributes["photo"], portraitPhotoMock);
      expect(attributes["initials"], isNot(portraitPhotoMock));
    });
  });

  group("the schemes provider", () {
    testWidgets("asks again after every scheme change", (tester) async {
      await pump(tester, SchemeManagementScreen());
      int asked() =>
          bridge.dispatched.whereType<RequestDebugSchemesEvent>().length;
      expect(asked(), 1);

      // Go sends new rules after updating, installing or removing a scheme.
      bridge.deliver(
        SchemeRulesEvent.fromJson({
          "minimum_app_version": {"android": 0, "ios": 0},
          "ul_issue_credential_ids": <String>[],
        }),
      );
      await settle(tester);
      await tester.pumpAndSettle();
      expect(asked(), 2);
    });

    test("a revocation attribute without a name is read", () {
      final type = DebugCredentialType.fromJson({
        "id": "irma-demo.example.card",
        "scheme_manager_id": "irma-demo",
        "name": {"en": "Card"},
        "attributes": [
          {"id": "revocation", "name": null},
        ],
      });
      expect(type.attributes.single.name, isEmpty);
      expect(type.attributes.single.displayHint, isNull);
    });
  });
}
