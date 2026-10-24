import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/session/models/disclosure_view_model.dart"
    show inSentence;
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/empty_card_spot.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";

import "../util.dart";

/// Taps the share button (Share with …, Sign and share, Share and add
/// card…). It is the consent: the session continues straight away. Only
/// when nobody vouches for the requestor ("Share anyway") does the app ask
/// once more, and this confirms it.
Future<void> tapShare(WidgetTester tester) async {
  final button = find.byKey(const Key("share_button"));
  await tester.waitFor(button);
  await tester.tapAndSettle(button);
  await confirmShareAnyway(tester);
}

/// Confirms "Share with a party Yivi doesn't know?" if it is showing.
Future<void> confirmShareAnyway(WidgetTester tester) async {
  final confirm = find.byKey(const Key("share_anyway_confirm"));
  if (confirm.evaluate().isNotEmpty) await tester.tapAndSettle(confirm);
}

/// Whether the share button can be pressed now.
bool shareButtonEnabled(WidgetTester tester) {
  final button = find.descendant(
    of: find.byKey(const Key("share_button")),
    matching: find.byWidgetPredicate(
      (w) => w is FancyPillButton || w is PillButton,
    ),
  );
  final widget = tester.widget(button);
  return switch (widget) {
    FancyPillButton(:final onPressed) => onPressed != null,
    PillButton(:final onPressed) => onPressed != null,
    _ => false,
  };
}

Future<void> evaluateFeedback(
  WidgetTester tester, {
  feedbackType = DisclosureFeedbackType.success,
  isSignatureSession = false,
}) async {
  // Expect the success screen
  final feedbackScreenFinder = find.byType(DisclosureFeedbackScreen);
  expect(feedbackScreenFinder, findsOneWidget);
  expect(
    (feedbackScreenFinder.evaluate().single.widget as DisclosureFeedbackScreen)
        .feedbackType,
    feedbackType,
  );

  if (feedbackType == DisclosureFeedbackType.success) {
    // The result: a check and "Shared with …" or "Signed and shared" (or
    // "Done" when nothing was shared).
    expect(
      find.descendant(
        of: feedbackScreenFinder,
        matching: find.byKey(const Key("share_done_check")),
      ),
      findsOneWidget,
    );
    final title = find.byKey(const Key("share_done_title"));
    expect(title, findsOneWidget);
    final text = tester.widget<Text>(title).data!;
    if (isSignatureSession) {
      expect(text, "Signed and shared");
    } else {
      expect(text.startsWith("Shared with") || text == "Done", isTrue);
    }

    await tester.tapAndSettle(find.byKey(const Key("ok_button")));
  } else {
    if (feedbackType == DisclosureFeedbackType.canceled) {
      expect(find.text("Canceled"), findsOneWidget);
    }
    await tester.waitFor(find.text("OK"));
    await tester.tapAndSettle(find.text("OK"));
  }

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);
}

/// Checks the requestor card of the share screen: the name, "Registered
/// with Yivi" or "Not checked", and the red wash behind the page for a
/// requestor nobody vouches for. [requestorHeaderFinder] defaults to the
/// one card on screen.
Future<void> evaluateRequestorHeader(
  WidgetTester tester,
  Finder? requestorHeaderFinder, {
  required String localizedRequestorName,
  required bool isVerified,
}) async {
  final header = requestorHeaderFinder ?? find.byType(RequestorCard);
  expect(header, findsOneWidget);
  expect(
    tester
        .widget<Text>(
          find.descendant(
            of: header,
            matching: find.byKey(const Key("session_requestor_name")),
          ),
        )
        .data,
    localizedRequestorName,
  );
  expect(
    find.descendant(
      of: header,
      matching: find.text(isVerified ? "Registered with Yivi" : "Not checked"),
    ),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key("share_trust_wash")),
    isVerified ? findsNothing : findsOneWidget,
  );
}

/// Finds [text] in [card], leaving out the card picture. A card tile draws
/// the credential name twice: next to the picture and on it.
Finder findCardText(Finder card, String text) => find.descendant(
  of: card,
  matching: find.byElementPredicate((element) {
    final widget = element.widget;
    if (widget is! Text || widget.data != text) return false;
    var onPicture = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is CredentialCardArt) {
        onPicture = true;
        return false;
      }
      return true;
    });
    return !onPicture;
  }),
);

/// The scroll view of the activity tab's entries. The tab has a search field
/// as well, which has a [Scrollable] of its own.
Finder activityScrollable() => find
    .descendant(of: find.byType(ActivityTab), matching: find.byType(Scrollable))
    .first;

// ---------------------------------------------------------------------------
// Cards that are not in the app yet: empty spots on the share screen.
// ---------------------------------------------------------------------------

/// The empty spot of requested item [i]: a required card that is not in the
/// app yet. Tapping it adds the card in the Change sheet.
Finder findEmptySpot(int i) => find.byKey(Key("share_spot_$i"));

/// The green "New" on the card of requested item [i], once a card was
/// added for it during the request.
Finder findAddedNote(int i) => find.descendant(
  of: findShareSlot(i),
  matching: find.byKey(const Key("shared_card_new")),
);

/// A spot's title as the screen writes it: the types after the first in
/// sentence case ("Demo Address or demo iDIN").
String spotTitle(String name) {
  final parts = name.split(" or ");
  return [
    parts.first,
    for (final p in parts.skip(1)) inSentence(p),
  ].join(" or ");
}

/// The reason above the share button ("Add … first."), if any.
String? shareReason(WidgetTester tester) {
  final reason = find.byKey(const Key("share_reason"));
  return reason.evaluate().isEmpty ? null : tester.widget<Text>(reason).data;
}

/// Checks that requested item [i] is an empty spot for [title] (the types
/// it can be filled with, joined with " or "), with [hint] (the issuer of
/// the one type, "You pick one when adding", "Can't be added in Yivi. …")
/// when given. With one card to add, the spot also lists the requested
/// fields as "Not in your app yet"; see [expectEmptySpotRows].
void expectEmptySpot(int i, String title, {String? hint}) {
  final spot = findEmptySpot(i);
  expect(spot, findsOneWidget, reason: "empty spot $i");
  expect(
    find.descendant(of: spot, matching: find.text(spotTitle(title))),
    findsOneWidget,
  );
  if (hint != null) {
    expect(
      find.descendant(of: spot, matching: find.text(hint)),
      findsOneWidget,
      reason: "hint of empty spot $i",
    );
  }
}

/// Checks the rows of empty spot [i]: each requested field [labels], with
/// "Not in your app yet" (or "Must be …").
void expectEmptySpotRows(int i, List<String> labels) {
  final spot = findEmptySpot(i);
  for (final label in labels) {
    expect(
      find.descendant(of: spot, matching: find.text(label)),
      findsOneWidget,
      reason: "row $label of empty spot $i",
    );
  }
}

/// Checks that Share waits for [name] (the first empty spot's title):
/// disabled, with "Add your {name} first. Then you can share." above it.
void expectShareWaitsFor(WidgetTester tester, String name) {
  expect(shareButtonEnabled(tester), isFalse, reason: "share button");
  expect(
    shareReason(tester),
    "Add your ${inSentence(spotTitle(name))} first. Then you can share.",
  );
}

/// Checks that empty spot [i] cannot be filled from Yivi ("Can't be added
/// in Yivi. …", not tappable), and that the share button is "Close" with
/// "Yivi can't add …" above it.
void expectCannotAdd(WidgetTester tester, int i) {
  expect(
    find.descendant(
      of: findEmptySpot(i),
      matching: find.textContaining("Can't be added in Yivi."),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key("share_button")),
      matching: find.text("Close"),
    ),
    findsOneWidget,
  );
  expect(shareReason(tester), startsWith("Yivi can't add "));
}

/// Checks that requested item [i] was filled with a card added during the
/// request: the card in its place, with "New" on it.
Future<void> expectAddedInPlace(WidgetTester tester, int i) async {
  await tester.waitFor(findAddedNote(i));
  expect(findEmptySpot(i), findsNothing);
  expect(findShareSlot(i), findsOneWidget);
}

/// Taps the empty spot of requested item [i]: the Change sheet opens, on
/// the details of the one type that fills it, or on the choice when there
/// are several.
Future<void> tapSpot(WidgetTester tester, int i) async {
  final spot = find.byKey(Key("share_spot_$i"), skipOffstage: false);
  await _scrollToCentre(tester, spot);
  await tester.tapAndSettle(spot);
  expect(findChoiceSheet(), findsOneWidget);
}

/// Taps "Add" on the details in the open sheet (step 1 of 3), then "Open
/// website" on the page that says where adding goes (step 2): the issuer's
/// website opens while the sheet waits (see [startAdding]).
Future<void> tapAddOnDetails(WidgetTester tester) async {
  final go = find.byKey(const Key("sheet_go_button"));
  expect(go, findsOneWidget);
  await tester.tapAndSettle(go);
  await tester.tapAndSettle(find.byKey(const Key("sheet_open_website")));
  expect(find.byKey(const Key("sheet_opened_note")), findsOneWidget);
}

// ---------------------------------------------------------------------------
// The share screen and its Change sheet.
// ---------------------------------------------------------------------------

/// The card of requested item [i] on the share screen.
Finder findShareSlot(int i) => find.byKey(Key("share_slot_$i"));

/// The open Change sheet.
Finder findChoiceSheet() => find.byKey(const Key("disclosure_choice_sheet"));

/// Opens the Change sheet of requested item [i].
Future<void> changeChoice(WidgetTester tester, int i) async {
  final change = find.byKey(Key("share_change_$i"), skipOffstage: false);
  await _scrollToCentre(tester, change);
  await tester.tapAndSettle(change);
  expect(findChoiceSheet(), findsOneWidget);
}

/// Optional item [i] that is not shared yet. With a card in the app it is
/// that card, faded, with "Share too": a tap shares it, no sheet. Without
/// one it is an empty spot: a tap opens the Change sheet to add one.
Future<void> addOptional(WidgetTester tester, int i) async {
  final row = find.byKey(Key("share_add_optional_$i"), skipOffstage: false);
  await _scrollToCentre(tester, row);
  final viaSheet = find
      .descendant(of: row, matching: find.byType(EmptyCardSpot))
      .evaluate()
      .isNotEmpty;
  await tester.tapAndSettle(row);
  if (viaSheet) {
    expect(findChoiceSheet(), findsOneWidget);
  } else {
    expect(findShareSlot(i), findsOneWidget);
  }
}

/// Opens the Change sheet of optional item [i]: when it has a card in the
/// app, shares that first ("Share too") and then taps "Change choice";
/// otherwise taps Add on its empty spot.
Future<void> openOptionalSheet(WidgetTester tester, int i) async {
  if (findShareSlot(i).evaluate().isEmpty) await addOptional(tester, i);
  if (findChoiceSheet().evaluate().isEmpty) await changeChoice(tester, i);
}

/// Leaves out optional item [i] again ("Don't share").
Future<void> removeOptional(WidgetTester tester, int i) async {
  final remove = find.byKey(Key("share_remove_$i"), skipOffstage: false);
  await _scrollToCentre(tester, remove);
  await tester.tapAndSettle(remove);
}

/// The "In your app" rows of the open sheet.
Finder findSheetOwnedRows() => find.descendant(
  of: findChoiceSheet(),
  matching: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith("sheet_owned_"),
  ),
);

/// The empty card of the open sheet that adds [credentialId].
Finder findSheetAddRow(String credentialId) => find.descendant(
  of: findChoiceSheet(),
  matching: find.byKey(Key("sheet_add_$credentialId")),
);

/// Checks the open sheet's "Not in your app yet" card for [credentialId]:
/// its [name] (or "Another {name}") and its [issuer].
void expectSheetAddRow(String credentialId, String name, String issuer) {
  final row = findSheetAddRow(credentialId);
  expect(row, findsOneWidget, reason: "sheet card for $credentialId");
  // "{name}" (or "Another {name}", the name in sentence case).
  expect(
    find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? "").toLowerCase().contains(name.toLowerCase()),
      ),
    ),
    findsWidgets,
  );
  // The issuer below it (a card can be named after its issuer: "Demo iDIN").
  expect(find.descendant(of: row, matching: find.text(issuer)), findsWidgets);
}

/// The "In your app" rows of the open sheet that show [text] (or, with
/// [partial], a text containing it). Each row once, however often the text
/// appears in it.
Finder findSheetOwnedRowShowing(String text, {bool partial = false}) =>
    find.descendant(
      of: findChoiceSheet(),
      matching: find.byElementPredicate((row) {
        final key = row.widget.key;
        if (key is! ValueKey<String> || !key.value.startsWith("sheet_owned_")) {
          return false;
        }
        var shows = false;
        void visit(Element e) {
          if (shows) return;
          final w = e.widget;
          final data = w is Text ? w.data : null;
          if (data != null && (partial ? data.contains(text) : data == text)) {
            shows = true;
            return;
          }
          e.visitChildren(visit);
        }

        row.visitChildren(visit);
        return shows;
      }),
    );

/// Picks the card in the open sheet whose row shows [text] (e.g. a value
/// that tells it apart). The sheet closes.
Future<void> pickOwned(WidgetTester tester, String text) async {
  final row = findSheetOwnedRowShowing(text);
  expect(row, findsOneWidget, reason: "sheet row with '$text'");
  await tester.tapAndSettle(row);
  await tester.waitUntilDisappeared(findChoiceSheet());
}

/// Adds [credentialId] from the open sheet: opens its details (step 1 of 3)
/// and taps "Add", which opens the issuer's website while the sheet waits.
///
/// In tests the website does not open (see [pumpYiviApp]); tests then issue
/// the card directly, as the website would. That issuance shows in the
/// sheet (step 3), and "Back to {requestor}" closes it with the new card
/// selected (and an optional item included); [issueCredentials] does both.
Future<void> startAdding(WidgetTester tester, String credentialId) async {
  final row = findSheetAddRow(credentialId);
  await tester.scrollUntilVisible(
    row,
    100,
    scrollable: find
        .descendant(of: findChoiceSheet(), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tapAndSettle(row);
  // The sheet waits for the user to come back from the website.
  await tapAddOnDetails(tester);
}

/// Closes the open sheet without changing anything: its close button, or
/// on the pages of adding a card (which have none) a drag down on its
/// header.
Future<void> closeChoiceSheet(WidgetTester tester) async {
  final close = find.descendant(
    of: findChoiceSheet(),
    matching: find.bySemanticsLabel("Close"),
  );
  if (close.hitTestable().evaluate().isNotEmpty) {
    await tester.tapAndSettle(close.hitTestable().first);
  } else {
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const Key("glass_sheet_title")).last),
    );
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, 50));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
  }
  await tester.waitUntilDisappeared(findChoiceSheet());
}

/// Scrolls [finder] into view and then to the middle of its scroll view, so
/// it is not under the floating bars.
Future<void> _scrollToCentre(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 100);
  // A jump, not an animation: awaiting a scroll animation can hang in the
  // integration binding.
  unawaited(Scrollable.ensureVisible(tester.element(finder), alignment: 0.5));
  await tester.pumpAndSettle();
}

/// Waits for a started request to show: the share screen, also when a card
/// is still missing (an empty spot).
Future<void> waitForRequest(WidgetTester tester) =>
    tester.waitFor(find.byType(DisclosureShareScreen));
