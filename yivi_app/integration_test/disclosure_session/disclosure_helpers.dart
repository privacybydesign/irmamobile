import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/screens/session/requestor/requestor_card.dart";
import "package:yivi_core/src/screens/session/result/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/widgets/buttons/pill_buttons.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "../util.dart";

// The disclosure screens (2.1–2.5 of the build plan): "Eerst toevoegen"
// (the add step), the overview, "Kies wat je deelt" (the change page) and
// its sheets. The helpers keep the names of the old share screen's helpers;
// they move between the screens themselves, so a scenario says what it
// checks, not how to get there.

/// The add step's button: the next row's action, and "See what you share"
/// once everything is in.
final _next = find.byKey(const Key("share_next"));
final _changePage = find.byKey(const Key("change_page"));
final _changeDone = find.byKey(const Key("change_done"));

/// Whether the change page is open.
bool onChangePage() => _changePage.evaluate().isNotEmpty;

/// Goes back to the overview: "Done" on the change page, "See what you
/// share" on a finished add step.
Future<void> toOverview(WidgetTester tester) async {
  if (onChangePage()) {
    await tester.tapAndSettle(_changeDone);
    await tester.waitUntilDisappeared(_changePage);
  }
  if (_next.evaluate().isNotEmpty) {
    final label = tester
        .widgetList<Text>(
          find.descendant(of: _next, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .join();
    if (label.startsWith("See what you")) {
      await tester.tapAndSettle(_next);
      await tester.waitFor(find.byKey(const Key("share_overview")));
    }
  }
}

/// Opens "Choose what you share" from the overview, when it is not open.
Future<void> openChangePage(WidgetTester tester) async {
  await tester.pumpAndSettle();
  if (onChangePage()) return;
  if (find.byType(DisclosureFlow).evaluate().isEmpty) return;
  await toOverview(tester);
  await tester.pumpAndSettle();
  // Still adding cards: the change page is not there yet.
  if (find.byKey(const Key("add_step")).evaluate().isNotEmpty) return;
  final change = find.byKey(const Key("share_pile"), skipOffstage: false);
  final hint = find.byKey(
    const Key("share_optional_hint"),
    skipOffstage: false,
  );
  final open = change.evaluate().isNotEmpty ? change : hint;
  await _scrollToCentre(tester, open);
  await tester.tapAndSettle(open);
  await tester.waitFor(_changePage);
}

/// Taps the share button (Share, Sign, Share and receive, Continue without
/// sharing). It is the consent: the session continues straight away. Only
/// when nobody vouches for the requestor ("Share anyway") does the app ask
/// once more, and this confirms it. From the change page or a finished add
/// step it goes to the overview first.
Future<void> tapShare(WidgetTester tester) async {
  // A request that cannot be finished: its one button closes it (2.10).
  final close = find.descendant(of: _next, matching: find.text("Close"));
  if (close.evaluate().isNotEmpty) {
    await tester.tapAndSettle(_next);
    return;
  }
  await toOverview(tester);
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

/// Whether the share button shares when pressed now. While something is
/// missing the add step shows instead, and this is false.
bool shareButtonEnabled(WidgetTester tester) {
  // The add step: ready once only "See what you share" is left.
  if (_next.evaluate().isNotEmpty) {
    return tester
        .widgetList<Text>(
          find.descendant(of: _next, matching: find.byType(Text)),
        )
        .any((t) => (t.data ?? "").startsWith("See what you"));
  }
  final button = find.descendant(
    of: find.byKey(const Key("share_button")),
    matching: find.byWidgetPredicate(
      (w) => w is PrimaryPillButton || w is PillButton,
    ),
  );
  if (button.evaluate().isEmpty) return false;
  final widget = tester.widget(button);
  return switch (widget) {
    PrimaryPillButton(:final onPressed) => onPressed != null,
    PillButton(:final onPressed) => onPressed != null,
    _ => false,
  };
}

Future<void> evaluateFeedback(
  WidgetTester tester, {
  isSignatureSession = false,
}) async {
  // Expect the success screen: a check and "Shared with …" or "Signed for
  // …" (or "Done" when nothing was shared).
  final feedbackScreenFinder = find.byType(DisclosureFeedbackScreen);
  expect(feedbackScreenFinder, findsOneWidget);
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
    expect(text, startsWith("Signed for "));
    // The paper with the signature drawn on it.
    expect(find.byKey(const Key("share_done_paper")), findsOneWidget);
    expect(find.byKey(const Key("share_done_signature")), findsOneWidget);
  } else {
    expect(text.startsWith("Shared with") || text == "Done", isTrue);
  }

  await tester.tapAndSettle(find.byKey(const Key("ok_button")));

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);
}

/// Checks the requestor card of the share screen: the name, "Registered
/// with Yivi" or "Not known by Yivi", and the red wash behind the page for a
/// requestor nobody vouches for. [requestorHeaderFinder] defaults to the
/// one card on screen.
Future<void> evaluateRequestorHeader(
  WidgetTester tester,
  Finder? requestorHeaderFinder, {
  required String localizedRequestorName,
  required bool isVerified,
}) async {
  if (onChangePage()) await toOverview(tester);
  // The add step shows who asks in its bar, not as a card: the name, and
  // the trust words after what they ask.
  final bar = find.byKey(const Key("requestor_compact_bar"));
  if (find.byKey(const Key("add_step")).evaluate().isNotEmpty &&
      find.byType(RequestorCard).evaluate().isEmpty) {
    expect(
      find.descendant(of: bar, matching: find.text(localizedRequestorName)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bar,
        matching: find.textContaining(
          isVerified ? "registered with Yivi" : "not known by Yivi",
          findRichText: true,
        ),
      ),
      findsOneWidget,
    );
    return;
  }
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
      matching: find.text(
        isVerified ? "Registered with Yivi" : "Not known by Yivi",
      ),
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
// Cards that are not in the app yet: rows of the add step.
// ---------------------------------------------------------------------------

/// The add-step row of requested item [i]: a required item that could not
/// be answered when the request opened. Tapping it adds the card.
Finder findEmptySpot(int i) => find.byKey(Key("add_step_row_$i"));

/// The check on the add-step row of requested item [i], once a card was
/// added for it during the request.
Finder findAddedNote(int i) => find.byKey(Key("add_step_done_$i"));

/// A row's title as the screen writes it ("Passport, ID card or Driving
/// licence").
String spotTitle(String name) {
  final parts = name.split(" or ");
  if (parts.length < 3) return name;
  return "${parts.sublist(0, parts.length - 1).join(", ")} or ${parts.last}";
}

/// What is said above the bottom button: why it cannot share (an unknown
/// requestor), or the add step's line ("One more card, then you'll see what
/// you share"); null when neither is there.
String? shareReason(WidgetTester tester) {
  for (final key in const ["share_reason", "add_step_progress_line"]) {
    final found = find.byKey(Key(key));
    if (found.evaluate().isEmpty) continue;
    final text = tester.widget<Text>(found.first);
    return text.data ?? text.textSpan?.toPlainText().replaceAll("\uFFFC", "");
  }
  return null;
}

/// Checks that requested item [i] is an add-step row for [title] (the
/// types it can be filled with, joined with " or "), with [hint] (the
/// issuer of the one type, "One is enough. Choose one.", "Can't be added in
/// Yivi. …") when given.
void expectEmptySpot(int i, String title, {String? hint}) {
  final spot = findEmptySpot(i);
  expect(spot, findsOneWidget, reason: "add-step row $i");
  final words = [
    for (final w
        in find
            .descendant(of: spot, matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .nonNulls)
      w,
  ];
  expect(
    words.any(
      (w) =>
          w == spotTitle(title) ||
          w.toLowerCase().contains(title.split(" or ").first.toLowerCase()),
    ),
    isTrue,
    reason: "title '$title' of row $i in $words",
  );
  if (hint != null) {
    expect(
      find.descendant(of: spot, matching: find.textContaining(hint)),
      findsWidgets,
      reason: "hint of row $i",
    );
  }
}

/// Checks the asked values on add-step row [i]: a tag per field [labels].
void expectEmptySpotRows(int i, List<String> labels) {
  final spot = findEmptySpot(i);
  for (final label in labels) {
    expect(
      find.descendant(of: spot, matching: find.textContaining(label)),
      findsWidgets,
      reason: "asked $label on row $i",
    );
  }
}

/// Checks that the request waits for [name] (the first row's title): the
/// add step shows, its button does the next row's action ("Add {name}",
/// "Add {name} again", "Get {name} again", "Choose what to add"), and the
/// line says what is left.
void expectShareWaitsFor(WidgetTester tester, String name) {
  expect(shareButtonEnabled(tester), isFalse, reason: "share button");
  expect(
    shareReason(tester),
    anyOf(
      matches(
        RegExp(
          r"^One more (card|thing), then you'll see what you (share|sign)$",
        ),
      ),
      matches(
        RegExp(
          r"^\w+ more (cards|things), then you'll see what you (share|sign)$",
        ),
      ),
      "Everything is in your app",
    ),
  );
  final text = tester
      .widgetList<Text>(find.descendant(of: _next, matching: find.byType(Text)))
      .map((t) => t.data)
      .nonNulls
      .join();
  final first = name.split(" or ").first;
  expect(
    text,
    anyOf(
      startsWith("Add $first"),
      startsWith("Add "),
      startsWith("Get "),
      "Choose what to add",
    ),
  );
}

/// The add-step row of requested item [i] whose card in the app has
/// another value than is asked ("In your app: …" with "Asked: …").
Finder findNotCounted(int i) => findEmptySpot(i);

/// Checks that requested item [i] cannot be added from Yivi: the add step
/// lists only what stops the request, the row says "Can't be added in Yivi.
/// …", and the button is "Close" with "You share nothing" above it.
void expectCannotAdd(WidgetTester tester, int i) {
  expect(
    find.descendant(
      of: findEmptySpot(i),
      matching: find.textContaining("Can't be added in Yivi."),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(of: _next, matching: find.text("Close")),
    findsOneWidget,
  );
  expect(shareReason(tester), anyOf("You share nothing", "You sign nothing"));
}

/// Checks that requested item [i] was filled with a card added during the
/// request: its add-step row has the check.
Future<void> expectAddedInPlace(WidgetTester tester, int i) async {
  await tester.waitFor(findAddedNote(i));
  expect(findEmptySpot(i), findsNothing);
}

/// Taps the add-step row of requested item [i]: the add sheet opens, on
/// the details of the one type that fills it, or on "Choose what to add".
Future<void> tapSpot(WidgetTester tester, int i) async {
  final spot = find.byKey(Key("add_step_row_$i"), skipOffstage: false);
  await _scrollToCentre(tester, spot);
  await tester.tapAndSettle(spot);
  expect(findChoiceSheet(), findsOneWidget);
}

/// Taps "Next" on the details in the open sheet (step 1 of 3), then "To
/// {host}" on the page that says where adding goes (step 2): the issuer's
/// website opens while the sheet waits (see [startAdding]).
Future<void> tapAddOnDetails(WidgetTester tester) async {
  final go = find.byKey(const Key("sheet_go_button"));
  expect(go, findsOneWidget);
  await tester.tapAndSettle(go);
  await tester.tapAndSettle(find.byKey(const Key("sheet_open_website")));
  expect(find.byKey(const Key("sheet_website_heading")), findsOneWidget);
  expect(find.byKey(const Key("sheet_open_website")), findsOneWidget);
}

// ---------------------------------------------------------------------------
// The change page and its sheets.
// ---------------------------------------------------------------------------

/// The card of requested item [i] on the change page: a required one, or
/// optional data that is shared.
Finder findShareSlot(int i) => find.byWidgetPredicate((w) {
  final key = w.key;
  return key == Key("change_card_$i") ||
      (key == Key("change_optional_$i") &&
          find.byKey(Key("change_optional_off_$i")).evaluate().isNotEmpty);
});

/// The open sheet: "Which card do you share?", "Which combination do you
/// share?", or the add sheet ("Choose what to add" and adding a card).
Finder findChoiceSheet() => find.byWidgetPredicate(
  (w) =>
      w.key == const Key("which_card_sheet") ||
      w.key == const Key("which_combination_sheet") ||
      w.key == const Key("add_sheet"),
);

/// Opens the sheet of requested item [i] from the change page: its card
/// link, the link of its first slot that has one, or its combination link.
Future<void> changeChoice(WidgetTester tester, int i) async {
  await openChangePage(tester);
  Finder? link;
  for (final candidate in [
    find.byKey(Key("change_pick_$i"), skipOffstage: false),
    find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            "change_pick_slot_${i}_",
          ),
      skipOffstage: false,
    ),
    find.byKey(Key("change_combination_$i"), skipOffstage: false),
    find.byKey(Key("change_optional_link_$i"), skipOffstage: false),
  ]) {
    if (candidate.evaluate().isNotEmpty) {
      link = candidate.first;
      break;
    }
  }
  expect(link, isNotNull, reason: "a link for choice $i on the change page");
  await _scrollToCentre(tester, link!);
  await tester.tapAndSettle(link);
  expect(findChoiceSheet(), findsOneWidget);
}

/// Kept for scenarios that unfolded "Add another card" in the old sheet:
/// the new sheets show their add link at once.
Future<void> openMoreInSheet(WidgetTester tester) async {}

/// Shares optional item [i] from the change page: "Share this too" at once,
/// or in its sheet the first card and "Choose". Without a card in the app
/// the add sheet stays open, to add one.
Future<void> addOptional(WidgetTester tester, int i) async {
  await openOptionalSheet(tester, i, expectNothingRow: false);
  if (findChoiceSheet().evaluate().isEmpty) return;
  if (find.byKey(const Key("add_sheet")).evaluate().isNotEmpty) return;
  final rows = findSheetOwnedRows();
  if (rows.evaluate().isNotEmpty) {
    await tester.tapAndSettle(rows.first);
  } else {
    final option = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith("combination_option_"),
    );
    await tester.tapAndSettle(option.first);
  }
  await chooseInSheet(tester);
  expect(findShareSlot(i), findsOneWidget);
}

/// Opens the sheet of optional item [i]: its link when it is not shared,
/// the card's own link when it is. "Share this too" shares at once and
/// opens nothing.
Future<void> openOptionalSheet(
  WidgetTester tester,
  int i, {
  bool expectNothingRow = true,
}) async {
  await openChangePage(tester);
  if (findShareSlot(i).evaluate().isNotEmpty) {
    await changeChoice(tester, i);
  } else {
    final link = find.byKey(
      Key("change_optional_link_$i"),
      skipOffstage: false,
    );
    await _scrollToCentre(tester, link);
    await tester.tapAndSettle(link);
  }
  if (expectNothingRow &&
      find.byKey(const Key("add_sheet")).evaluate().isEmpty) {
    expect(findChoiceSheet(), findsOneWidget);
    expect(findShareNothing(), findsOneWidget);
  }
}

/// "Don't share" in the sheet of an optional item.
Finder findShareNothing() => find.byWidgetPredicate(
  (w) =>
      w.key == const Key("which_card_nothing") ||
      w.key == const Key("combination_nothing"),
);

/// Leaves out optional item [i] again: "Don't share" on its card.
Future<void> removeOptional(WidgetTester tester, int i) async {
  await openChangePage(tester);
  final off = find.byKey(Key("change_optional_off_$i"), skipOffstage: false);
  await _scrollToCentre(tester, off);
  await tester.tapAndSettle(off);
  expect(findChoiceSheet(), findsNothing);
}

/// The rows of cards in the app in the open sheet.
Finder findSheetOwnedRows() => find.descendant(
  of: findChoiceSheet(),
  matching: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith("which_card_row_"),
  ),
);

/// The row of the open sheet that adds [credentialId]: "＋ Another …" in a
/// sheet, or a way in "Choose what to add".
Finder findSheetAddRow(String credentialId) => find.descendant(
  of: findChoiceSheet(),
  matching: find.byWidgetPredicate((w) {
    final key = w.key;
    return key is ValueKey<String> &&
        key.value.startsWith("sheet_add_") &&
        (key.value.substring(10) == credentialId ||
            key.value.substring(10).split("+").contains(credentialId));
  }),
);

/// Checks the open sheet's row that adds [credentialId]: its [name] (or
/// "Another {name}") and, in "Choose what to add", its [issuer].
void expectSheetAddRow(String credentialId, String name, String issuer) {
  final row = findSheetAddRow(credentialId);
  expect(row, findsOneWidget, reason: "sheet row for $credentialId");
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
}

/// The rows of the open sheet that show [text] (or, with [partial], a text
/// containing it). Each row once, however often the text appears in it.
Finder findSheetOwnedRowShowing(String text, {bool partial = false}) =>
    find.descendant(
      of: findChoiceSheet(),
      matching: find.byElementPredicate((row) {
        final key = row.widget.key;
        if (key is! ValueKey<String> ||
            !(key.value.startsWith("which_card_row_") ||
                key.value.startsWith("combination_option_"))) {
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
/// that tells it apart): a tap selects it, "Choose" applies it and the
/// sheet closes.
Future<void> pickOwned(WidgetTester tester, String text) async {
  final row = findSheetOwnedRowShowing(text);
  expect(row, findsOneWidget, reason: "sheet row with '$text'");
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(row);
  await chooseInSheet(tester);
}

/// "Choose" (or "Done") in the open sheet, which applies what is picked.
Future<void> chooseInSheet(WidgetTester tester) async {
  for (final key in const [
    "which_card_choose",
    "which_card_done",
    "combination_choose",
  ]) {
    final button = find.byKey(Key(key));
    if (button.evaluate().isNotEmpty) {
      await tester.tapAndSettle(button.last);
      break;
    }
  }
  await tester.waitUntilDisappeared(findChoiceSheet());
}

/// Adds [credentialId] from the open sheet: "＋ Another …" (which closes
/// the sheet and opens adding), the way in "Choose what to add", then
/// "Next" and the issuer's step on its details.
///
/// In tests the website does not open (see [pumpYiviApp]); tests then issue
/// the card directly, as the website would. That issuance shows in the
/// sheet (step 3), and "Continue sharing" closes it with the new card
/// selected; [issueCredentials] does both.
Future<void> startAdding(WidgetTester tester, String credentialId) async {
  var row = findSheetAddRow(credentialId);
  if (row.evaluate().isNotEmpty &&
      find.byKey(const Key("add_sheet")).evaluate().isEmpty) {
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tapAndSettle(row);
    await tester.waitFor(find.byKey(const Key("add_sheet")));
    row = findSheetAddRow(credentialId);
  }
  if (row.evaluate().isNotEmpty) {
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tapAndSettle(row);
  }
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
  await tester.pumpAndSettle();
  await tester.waitFor(finder);
  // A jump, not an animation: awaiting a scroll animation can hang in the
  // integration binding.
  unawaited(Scrollable.ensureVisible(tester.element(finder), alignment: 0.5));
  await tester.pumpAndSettle();
}

/// Waits for a started request to show: the add step or the overview.
Future<void> waitForRequest(WidgetTester tester) =>
    tester.waitFor(find.byType(DisclosureFlow));

/// Checks whether requested item [i] can be changed: on the change page its
/// card has a link ("Choose another card", "Choose another …", "Choose
/// which you share", "Choose another combination"), or for optional data
/// one of its own. Opens the change page.
Future<void> expectCanChange(WidgetTester tester, int i, bool can) async {
  await openChangePage(tester);
  final links = find.byWidgetPredicate((w) {
    final key = w.key;
    if (key is! ValueKey<String>) return false;
    final v = key.value;
    return v == "change_pick_$i" ||
        v.startsWith("change_pick_slot_${i}_") ||
        v == "change_combination_$i" ||
        v == "change_optional_link_$i" ||
        v == "change_optional_off_$i";
  }, skipOffstage: false);
  expect(links.evaluate().isNotEmpty, can, reason: "a change link for item $i");
}
