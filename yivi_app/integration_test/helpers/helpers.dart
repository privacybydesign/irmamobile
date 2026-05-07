import "dart:convert";
import "dart:io";
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi/ocr_processor.dart";
import "package:yivi_core/app.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/rooted_device_detector_provider.dart";
import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_footer.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_header.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_avatar.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/radio_indicator.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";
import "package:yivi_core/yivi_core.dart";

import "../irma_binding.dart";
import "../util.dart";
import "fake_rooted_device_detector.dart";

/// Unlocks the IRMA app and waits until the wallet is displayed.
Future<void> unlockAndWaitForHome(WidgetTester tester) async {
  await unlock(tester);
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

Future<void> unlock(WidgetTester tester) async {
  await enterPin(tester, "12345");
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  final splitPin = pin.split("");
  for (final digit in splitPin) {
    await tester.tapAndSettle(
      find.byKey(Key("number_pad_key_${digit.toString()}")),
    );
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 1500));
}

Future<void> pumpYiviApp(
  WidgetTester tester,
  IrmaRepository repo, {
  Locale? defaultLanguage,
  List<Override>? providerOverrides,
  bool isDeviceRooted = false,
}) async {
  await tester.pumpWidgetAndSettle(
    ProviderScope(
      overrides: [
        irmaRepositoryProvider.overrideWithValue(repo),
        preferencesProvider.overrideWithValue(repo.preferences),
        rootedDeviceDetectorProvider.overrideWithValue(
          FakeRootedDeviceDetector(rooted: isDeviceRooted),
        ),
        ocrProcessorProvider.overrideWithValue(GoogleMLKitOcrProcessor()),
        if (providerOverrides != null) ...providerOverrides,
      ],
      child: TestContext(
        child: YiviApp(
          defaultLanguage: defaultLanguage ?? const Locale("en", "EN"),
        ),
      ),
    ),
  );

  // Wait for the App widget to be build inside of the YiviApp widget
  // (There is a builder wrapping the app widget that is used to check the preferred locale)
  await tester.waitFor(
    find.descendant(of: find.byType(YiviApp), matching: find.byType(App)),
  );
}

// Pump a new app and unlock it
Future<void> pumpAndUnlockApp(
  WidgetTester tester,
  IrmaRepository repo, {
  Locale? defaultLanguage,
  List<Override>? providerOverrides,
  bool isDeviceRooted = false,
}) async {
  await pumpYiviApp(
    tester,
    repo,
    defaultLanguage: defaultLanguage,
    providerOverrides: providerOverrides,
    isDeviceRooted: isDeviceRooted,
  );
  await unlockAndWaitForHome(tester);
}

Future<SessionPointer> createIssuanceSession({
  required Map<String, String> attributes,
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
}) async {
  final groupedAttributes = groupBy<MapEntry<String, String>, String>(
    attributes.entries,
    (attr) => attr.key.split(".").take(3).join("."),
  );
  final credentialsJson = jsonEncode(
    groupedAttributes.entries
        .map(
          (credEntry) => {
            "credential": credEntry.key,
            "attributes": {
              for (final attrEntry in credEntry.value)
                attrEntry.key.split(".")[3]: attrEntry.value,
            },
            if (revocationKeys.containsKey(credEntry.key))
              "revocationKey": revocationKeys[credEntry.key],
          },
        )
        .toList(),
  );

  return await createTestSession('''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''', continueOnSecondDevice: continueOnSecondDevice);
}

Map<String, List<MapEntry<String, String>>> groupAttributes(
  Map<String, String> attributes,
) {
  final groupedAttributes = groupBy<MapEntry<String, String>, String>(
    attributes.entries,
    (attr) => attr.key.split(".").take(3).join("."),
  );
  return groupedAttributes;
}

String createIssuanceRequest(
  Map<String, String> attributes, {
  Map<String, String> revocationKeys = const {},
  int? sdJwtBatchSize,
}) {
  final grouped = groupAttributes(attributes);
  return createIssuanceRequestWithGroupedAttributes(
    grouped,
    revocationKeys: revocationKeys,
    sdJwtBatchSize: sdJwtBatchSize,
  );
}

String createIssuanceRequestWithGroupedAttributes(
  Map<String, List<MapEntry<String, String>>> groupedAttributes, {
  Map<String, String> revocationKeys = const {},
  int? sdJwtBatchSize,
}) {
  final credentialsJson = jsonEncode(
    groupedAttributes.entries
        .map(
          (credEntry) => {
            "credential": credEntry.key,
            "attributes": {
              for (final attrEntry in credEntry.value)
                attrEntry.key.split(".")[3]: attrEntry.value,
            },
            if (revocationKeys.containsKey(credEntry.key))
              "revocationKey": revocationKeys[credEntry.key],
            if (sdJwtBatchSize != null) "sdJwtBatchSize": sdJwtBatchSize,
          },
        )
        .toList(),
  );

  return '''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''';
}

Future<void> startIssuanceSession(
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, List<MapEntry<String, String>>> groupedAttributes, {
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
  int? sdJwtBatchSize,
}) async {
  final request = createIssuanceRequestWithGroupedAttributes(
    groupedAttributes,
    revocationKeys: revocationKeys,
    sdJwtBatchSize: sdJwtBatchSize,
  );

  // Start session
  await irmaBinding.repository.startTestSession(
    request,
    continueOnSecondDevice: continueOnSecondDevice,
  );
}

/// Starts an issuing session that adds the given credentials to the IRMA app.
/// The attributes should be specified in the display order.
Future<void> issueCredentials(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, String> attributes, {
  Locale? locale,
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
  bool declineOffer = false,
  int? sdJwtBatchSize,
}) async {
  locale ??= Locale("en", "EN");
  final groupedAttributes = groupAttributes(attributes);
  await startIssuanceSession(
    irmaBinding,
    groupedAttributes,
    revocationKeys: revocationKeys,
    continueOnSecondDevice: continueOnSecondDevice,
    sdJwtBatchSize: sdJwtBatchSize,
  );

  var issuancePageFinder = find.byType(IssuancePermission);
  await tester.waitFor(issuancePageFinder);

  // Check whether all credentials are displayed.
  expect(
    find.byType(YiviCredentialCard),
    findsNWidgets(groupedAttributes.length),
  );

  if (sdJwtBatchSize != null) {
    if (locale == Locale("nl", "NL")) {
      expect(
        find.text("Nog $sdJwtBatchSize keer", skipOffstage: false),
        findsNWidgets(groupedAttributes.length),
      );
    } else {
      expect(
        find.text("$sdJwtBatchSize times left", skipOffstage: false),
        findsNWidgets(groupedAttributes.length),
      );
    }
  }

  // Check whether all credential type names are displayed.
  for (final credTypeId in groupedAttributes.keys) {
    final credType =
        irmaBinding.repository.irmaConfiguration.credentialTypes[credTypeId]!;
    expect(
      find.text(credType.name.translate(locale.languageCode)).last,
      findsOneWidget,
    );
  }

  // Check whether all attributes are displayed (order-independent).
  final attributeTexts = tester
      .getAllText(find.byType(YiviCredentialCardAttributeList))
      .toList();

  // Build a map of displayed attribute name -> value pairs.
  final displayedAttributes = <String, String>{};
  for (var i = 0; i < attributeTexts.length; i += 2) {
    displayedAttributes[attributeTexts[i]] = attributeTexts[i + 1];
  }

  // Build a map of expected attribute name -> value pairs.
  final expectedAttributes = <String, String>{};
  for (final entry in attributes.entries) {
    final attrName = irmaBinding
        .repository
        .irmaConfiguration
        .attributeTypes[entry.key]
        ?.name
        .translate(locale.languageCode);
    if (attrName != null) {
      expectedAttributes[attrName] = entry.value;
    }
  }

  // Verify that all expected attributes are present in the displayed attributes.
  for (final entry in expectedAttributes.entries) {
    expect(
      displayedAttributes[entry.key],
      entry.value,
      reason:
          "Attribute '${entry.key}' expected '${entry.value}' but got '${displayedAttributes[entry.key]}'",
    );
  }

  final buttonFinder = find.byKey(
    declineOffer
        ? const Key("bottom_bar_secondary")
        : const Key("bottom_bar_primary"),
  );
  expect(buttonFinder, findsOneWidget);

  await tester.tapAndSettle(buttonFinder);

  await tester.waitUntilDisappeared(issuancePageFinder);
}

/// Generates a revocation key that can be used for issueCredentials.
String generateRevocationKey() {
  final r = Random();
  return String.fromCharCodes(List.generate(20, (index) => r.nextInt(26) + 97));
}

/// Revokes a previously issued credential.
Future<void> revokeCredential(String credId, String revocationKey) async {
  final Uri uri = Uri.parse("https://is.demo.staging.yivi.app/revocation");

  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.write('''
    {
      "@context": "https://irma.app/ld/request/revocation/v1",
      "type": "$credId",
      "revocationKey": "$revocationKey"
    }
  ''');

  final response = await request.close();
  if (response.statusCode != 200) {
    throw Exception(
      "Credential $credId could not be revoked: status code ${response.statusCode}",
    );
  }
}

Future<void> evaluateRequestor(
  WidgetTester tester,
  Finder reqeustorInfoFinder,
  String expectedName,
) async {
  final finder = find.descendant(
    of: reqeustorInfoFinder,
    matching: find.byType(RequestorHeader),
    matchRoot: true,
  );
  expect(finder, findsAtLeast(1));
  final nameFinder = find.descendant(
    of: finder,
    matching: find.text(expectedName),
  );
  expect(nameFinder, findsOneWidget);
}

/// One label-value entry in an [attributes] list. The value is one of:
/// - `String`: a leaf row (label + value)
/// - `List<String>`: a primitive array, rendered as bullets
/// - [Block] (`List<AttrRow>`): a nested group
/// - `List<Block>`: an array of nested items
typedef AttrRow = (String label, Object value);

/// Ordered list of rows, used for nested groups and as item children.
typedef Block = List<AttrRow>;

Future<void> evaluateCredentialCard(
  WidgetTester tester,
  Finder credentialCardFinder, {
  String? credentialName,
  String? issuerName,
  int? instancesRemaining,
  /// Expected card attributes in render order. The DFS preorder of this list
  /// must match, element-for-element, the rendered leaves and primitive-array
  /// rows on the card. See [AttrRow] for the supported value shapes.
  List<AttrRow>? attributes,
  /// Color-comparison check for disclosure cards. Each row's value is the
  /// expected value the verifier asked for; the matcher checks that the
  /// rendered text for that label is colored green if it matches, red
  /// otherwise. Flat-only — only `String` values are honored.
  List<AttrRow>? attributesCompareTo,
  bool? isSelected,
  String? footerText,
  IrmaCardStyle? style,
  bool? isRevoked,
  bool? isExpired,
  bool? isExpiringSoon,
  /// Overrides the default Reobtain-button expectation. By default, the helper
  /// expects a Reobtain button when the cred is expired/revoked/expiring. Pass
  /// `false` for OID4VCI creds (no IssueURL → button never rendered, even when
  /// in a warning state).
  bool? expectReobtainButton,
}) async {
  expect(
    find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCard),
      matchRoot: true,
    ),
    findsOneWidget,
  );

  if (instancesRemaining != null) {
    final footer = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardFooter),
    );
    final instanceCountFinder = find.descendant(
      of: footer,
      matching: find.text("$instancesRemaining times left"),
    );
    expect(instanceCountFinder, findsOneWidget);
  }

  if (style != null) {
    // the style is detemined definitively inside of the build function of the credential card
    // so there is no way of knowing it for certain other than to look it up in the irma card
    final irmaCardFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(IrmaCard),
    );
    expect((irmaCardFinder.evaluate().first.widget as IrmaCard).style, style);
  }

  final shouldCheckCardStatus =
      isRevoked != null || isExpired != null || isExpiringSoon != null;
  final shouldCheckHeaderInfo = credentialName != null || issuerName != null;

  if (shouldCheckHeaderInfo || shouldCheckCardStatus) {
    // Card should have a header
    final cardHeaderFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardHeader),
    );
    expect(cardHeaderFinder, findsOneWidget);

    // Get the text from the header, excluding the avatar's fallback initials
    // text (rendered when no logo image is available).
    final avatarFinder = find.descendant(
      of: cardHeaderFinder,
      matching: find.byType(IrmaAvatar),
    );
    final avatarTexts = avatarFinder.evaluate().isEmpty
        ? const <String>{}
        : tester.getAllText(avatarFinder).toSet();
    var cardHeaderText = tester
        .getAllText(cardHeaderFinder)
        .where((t) => !avatarTexts.contains(t));
    final credentialStatusTexts = {
      "revoked": "Revoked",
      "expired": "Expired",
      "expiring": "About to expire",
    };

    if (shouldCheckCardStatus &&
        credentialStatusTexts.values.contains(cardHeaderText.first)) {
      final credentialStatus = cardHeaderText.first;

      if (isRevoked != null) {
        expect(credentialStatus == credentialStatusTexts["revoked"], isRevoked);
      }

      if (isExpired != null) {
        expect(credentialStatus == credentialStatusTexts["expired"], isExpired);
      }

      if (isExpiringSoon != null) {
        expect(
          credentialStatus == credentialStatusTexts["expiring"],
          isExpiringSoon,
        );
      }
    }

    if (shouldCheckHeaderInfo) {
      // Filter the status texts from the list, so we can test the rest.
      cardHeaderText = cardHeaderText.whereNot(
        (text) => credentialStatusTexts.values.contains(text),
      );

      // Compare the expected credential name
      if (credentialName != null) {
        expect(cardHeaderText.first, credentialName);
      }

      // Compare the issuer credential name
      if (issuerName != null) {
        expect(cardHeaderText.elementAt(1), issuerName);
      }
    }
  }

  if (attributes != null) {
    // Card should have an attribute list
    final cardAttList = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardAttributeList),
    );

    if (attributes.isNotEmpty) {
      _matchAttributes(tester, cardAttList, attributes);

      if (attributesCompareTo != null) {
        final renderedMap = _renderedLabelValues(tester, cardAttList);
        for (final (label, expected) in attributesCompareTo) {
          if (expected is! String) {
            throw ArgumentError(
              "attributesCompareTo only supports String values; got ${expected.runtimeType} for '$label'",
            );
          }
          final renderedValues = renderedMap[label];
          expect(
            renderedValues,
            isNotNull,
            reason: "attributesCompareTo: label '$label' not rendered",
          );
          expect(
            renderedValues!.length,
            1,
            reason:
                "attributesCompareTo: label '$label' must be a leaf, got ${renderedValues.length} values",
          );
          final renderedValue = renderedValues.single;
          final textFinder = find.descendant(
            of: cardAttList,
            matching: find.text(renderedValue),
          );
          expect(textFinder, findsOneWidget);

          final expectedTextColor = renderedValue == expected
              ? const Color(0xff00973a)
              : const Color(0xffbd1919);
          expect(
            (textFinder.evaluate().first.widget as Text).style?.color,
            expectedTextColor,
          );
        }
      }
    } else {
      // Expect no attribute list
      expect(cardAttList, findsNothing);
    }
  }

  if (isSelected != null) {
    final radioIndicatorFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(RadioIndicator),
    );

    expect(radioIndicatorFinder, findsOneWidget);
    final radioIndicatorWidget =
        radioIndicatorFinder.evaluate().single.widget as RadioIndicator;

    expect(radioIndicatorWidget.isSelected, isSelected);
  }

  // Check the footer
  if (footerText != null || shouldCheckCardStatus) {
    final footerFinder = find.byType(YiviCredentialCardFooter);

    if (shouldCheckCardStatus) {
      final isReobtainable =
          expectReobtainButton ??
          ((isExpired ?? false) ||
              (isRevoked ?? false) ||
              (isExpiringSoon ?? false));

      // Find reobtainable button
      final reobtainButtonFinder = find.descendant(
        of: find.byType(YiviThemedButton),
        matching: find.text("Reobtain"),
      );

      expect(
        reobtainButtonFinder,
        isReobtainable ? findsOneWidget : findsNothing,
      );
    }

    if (footerText != null) {
      expect(
        find.descendant(of: footerFinder, matching: find.text(footerText)),
        findsOneWidget,
      );
    }
  }
}

/// Walks the card's attribute list and pairs each label with its run of
/// following values, recovering an ordered list of (label, [values]) entries.
/// Classification keys off the font sizes used by the renderer
/// (`yivi_credential_card_attribute_list.dart`):
///   - 14: label (leaf or prim-array)
///   - 16: leaf value or prim-array bullet
///   - 12: eyebrow header (group/item) — closes the current run, ignored.
List<_LabelValues> _renderedRows(WidgetTester tester, Finder cardAttList) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: cardAttList, matching: find.byType(Text)),
      )
      .toList();

  final rendered = <_LabelValues>[];
  String? pendingLabel;
  List<String>? pendingValues;

  void flush() {
    if (pendingLabel != null) {
      rendered.add(_LabelValues(pendingLabel!, pendingValues ?? const []));
      pendingLabel = null;
      pendingValues = null;
    }
  }

  for (final t in texts) {
    final size = t.style?.fontSize;
    final data = t.data;
    if (data == null) continue;
    if (size == 14) {
      flush();
      pendingLabel = data;
      pendingValues = [];
    } else if (size == 16) {
      if (pendingLabel == null) continue;
      pendingValues!.add(data);
    } else {
      // Eyebrow (12) or unknown — closes the current label's value run.
      flush();
    }
  }
  flush();
  return rendered;
}

/// Convenience wrapper around [_renderedRows] for callers that want a
/// label-keyed lookup (used by [attributesCompareTo]). Asserts uniqueness.
Map<String, List<String>> _renderedLabelValues(
  WidgetTester tester,
  Finder cardAttList,
) {
  final rows = _renderedRows(tester, cardAttList);
  final map = <String, List<String>>{};
  for (final r in rows) {
    map[r.label] = r.values;
  }
  return map;
}

/// Flattens an ordered [List<AttrRow>] tree into a sequence of (label, [values])
/// expectations in DFS preorder. Mirrors the renderer's flatten step
/// (`yivi_credential_card_attribute_list.dart`): leaves emit one entry,
/// primitive arrays emit one entry with all bullets, item arrays recurse
/// into each item's children, and nested groups recurse into their children.
List<_LabelValues> _flattenExpected(List<AttrRow> rows) {
  final out = <_LabelValues>[];
  void walk(List<AttrRow> rows) {
    for (final (label, value) in rows) {
      if (value is String) {
        out.add(_LabelValues(label, [value]));
      } else if (value is List) {
        if (value.isEmpty) {
          out.add(_LabelValues(label, const []));
        } else if (value.every((v) => v is String)) {
          out.add(_LabelValues(label, value.cast<String>()));
        } else if (value.every((v) => v is List)) {
          // List<Block>: array of items. Recurse into each item.
          for (final item in value) {
            walk((item as List).cast<AttrRow>());
          }
        } else {
          throw ArgumentError(
            "Mixed list at '$label': expected List<String>, "
            "List<Block>, or List<AttrRow>; got $value",
          );
        }
      } else {
        throw ArgumentError(
          "Unsupported value type at '$label': ${value.runtimeType}",
        );
      }
    }
  }
  walk(rows);
  return out;
}

/// Order-strict matcher: rendered and expected sequences must match
/// element-for-element (label and value-list).
void _matchAttributes(
  WidgetTester tester,
  Finder cardAttList,
  List<AttrRow> expected,
) {
  final rendered = _renderedRows(tester, cardAttList);
  final flat = _flattenExpected(expected);

  if (rendered.length != flat.length) {
    fail(
      "Attribute row count mismatch.\n"
      "  expected (${flat.length}): $flat\n"
      "  rendered (${rendered.length}): $rendered",
    );
  }
  for (var i = 0; i < flat.length; i++) {
    expect(
      rendered[i].label,
      flat[i].label,
      reason: "Row $i label mismatch.\n  expected: $flat\n  rendered: $rendered",
    );
    expect(
      rendered[i].values,
      flat[i].values,
      reason: "Row $i values mismatch for '${flat[i].label}'.\n"
          "  expected: $flat\n  rendered: $rendered",
    );
  }
}

class _LabelValues {
  final String label;
  final List<String> values;
  const _LabelValues(this.label, this.values);

  @override
  String toString() => "($label → $values)";
}

Future<void> evaluateNotificationCard(
  WidgetTester tester,
  Finder notificationCardFinder, {
  String? title,
  String? content,
  bool? read,
}) async {
  expect(notificationCardFinder, findsOneWidget);

  if (title != null) {
    expect(
      find.descendant(of: notificationCardFinder, matching: find.text(title)),
      findsOneWidget,
    );
  }

  if (content != null) {
    expect(
      find.descendant(of: notificationCardFinder, matching: find.text(content)),
      findsOneWidget,
    );
  }

  if (read != null) {
    final notificationCardWidget =
        notificationCardFinder.evaluate().single.widget as NotificationCard;
    expect(notificationCardWidget.notification.read, read);
  }
}

Future<void> navigateBack(WidgetTester tester) async {
  await tester.tapAndSettle(find.byType(YiviBackButton));
}

Future<void> navigateToCredentialDetailsPage(
  WidgetTester tester,
  String credId,
) async {
  var categoryTileFinder = find.byKey(Key("${credId}_tile")).hitTestable();
  await tester.scrollUntilVisible(categoryTileFinder, 75);
  await tester.tapAndSettle(categoryTileFinder);

  // Expect detail page
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
}

Future<void> openAddCredentialDetailsScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  required String fullCredentialId,
  List<Override> overrides = const [],
}) async {
  await pumpAndUnlockApp(
    tester,
    binding.repository,
    providerOverrides: overrides.isEmpty ? null : overrides,
  );

  final addDataButton = find.byIcon(CupertinoIcons.add_circled_solid);
  await tester.tapAndSettle(addDataButton);

  final addCredentialTile = find.byKey(Key("${fullCredentialId}_tile"));
  await tester.scrollUntilVisible(
    addCredentialTile,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tapAndSettle(addCredentialTile);

  await tester.waitFor(find.byType(SchemalessAddDataDetailsScreen));
}
