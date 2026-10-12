import "dart:convert";
import "dart:io";

import "package:flutter/rendering.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/data/widgets/email_link_banner.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/linking_code_widgets.dart";
import "package:yivi_core/src/screens/session/widgets/email_link_permission.dart";
import "package:yivi_core/src/screens/session/widgets/email_linked_screen.dart";
import "package:yivi_core/src/screens/session/widgets/success_graphic.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_bottom_bar.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

import "support/onboarding_v2_harness.dart";
import "support/pump_translated.dart";

// The boards are 390 x 844 px. The positions below are the ones of the boards
// "Final (A1-K5)" of the Yivi UX proposals canvas: A6 and A7 (banner and its
// sheet), B1 (enter address), B2 and B8 (code), B3 (confirm) and B5 (done).
const _screen = Size(390, 844);
const _footerButton = 48.0;
const _footerGap = 8.0;
const _footerTop = 16.0;
const _footerBottom = 32.0;

class _FakeEmailIssuerApi implements EmailIssuerApi {
  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {}

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async => SessionPointer(
    u: "https://email-issuer.example/irma/session/abc",
    irmaqr: "issuing",
    protocol: Protocol.irma,
    continueOnSecondDevice: true,
  );
}

final _emailCredential = Credential(
  credentialId: "pbdf.sidn-pbdf.email",
  hash: "hash",
  name: "Email address",
  issuer: TrustedParty(
    id: "pbdf.sidn-pbdf.email",
    name: "Yivi",
    url: null,
    parent: null,
    verified: true,
  ),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: [
    Attribute(
      claimPath: const ["email"],
      displayName: "Email address",
      value: AttributeValue(
        type: AttributeType.string,
        string: "rosanne@example.com",
      ),
    ),
  ],
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = IrmaThemeData();
  late IrmaPreferences prefs;
  late IrmaRepository repo;

  setUp(() async {
    prefs = await freshPreferences();
    repo = IrmaRepository(client: RecordingBridge(), preferences: prefs);
  });

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    double bottomInset = 0,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: bottomInset);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        irmaRepositoryProvider.overrideWithValue(repo),
        emailIssuerApiProvider.overrideWithValue(_FakeEmailIssuerApi()),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);

    await pumpTranslated(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: IrmaRepositoryProvider(
          repository: repo,
          child: IrmaTheme(
            builder: (themeContext) => MaterialApp(
              theme: IrmaTheme.of(themeContext).themeData,
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: FileTranslationLoader(
                    basePath: "assets/locales",
                    forcedLocale: const Locale("en", "US"),
                  ),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
              builder: (context, child) => LegacyMaterialBridge(child: child!),
              home: screen,
            ),
          ),
        ),
      ),
    );
    return container;
  }

  TextStyle styleOf(WidgetTester tester, Finder finder) =>
      tester.renderObject<RenderParagraph>(finder).text.style!;

  Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

  BoxDecoration decorationOf(WidgetTester tester, Finder finder) {
    final box = tester.widget<Container>(finder);
    return box.decoration! as BoxDecoration;
  }

  /// A button of the flat bottom bar is [_footerButton] high and the bar is
  /// padded [_footerTop] above and [_footerBottom] below its buttons.
  void expectFlatFooter(WidgetTester tester, {required int buttons}) {
    var bottom = _screen.height - _footerBottom;
    final secondary = find.byKey(const Key("bottom_bar_secondary"));
    final primary = find.byKey(const Key("bottom_bar_primary"));

    if (buttons == 2) {
      final rect = rectOf(tester, secondary);
      expect(rect.height, _footerButton);
      expect(rect.bottom, bottom);
      bottom = rect.top - _footerGap;
    }

    final rect = rectOf(tester, primary);
    expect(rect.height, _footerButton);
    expect(rect.bottom, bottom);
    expect(rect.left, theme.defaultSpacing);
    expect(rect.right, _screen.width - theme.defaultSpacing);
    expect(
      find
          .ancestor(of: primary, matching: find.byType(Container))
          .evaluate()
          .map((e) => e.widget as Container)
          .any((c) {
            final decoration = c.decoration;
            return decoration is BoxDecoration &&
                decoration.boxShadow?.single.offset == const Offset(0, -1) &&
                decoration.boxShadow?.single.blurRadius == 6 &&
                decoration.boxShadow?.single.color == Colors.grey.shade300 &&
                c.padding?.resolve(TextDirection.ltr).top == _footerTop;
          }),
      isTrue,
    );
  }

  group("flat bottom bar", () {
    Widget bar(IrmaBottomBarStyle style) => Scaffold(
      bottomNavigationBar: IrmaBottomBar(
        style: style,
        primaryButtonLabel: "email_linking.confirm.add",
        onPrimaryPressed: () {},
        secondaryButtonLabel: "email_linking.confirm.cancel",
        onSecondaryPressed: () {},
      ),
    );

    testWidgets("puts 48 px buttons 8 px apart in a hairline shadow", (
      tester,
    ) async {
      await pumpScreen(tester, bar(IrmaBottomBarStyle.flat));

      expectFlatFooter(tester, buttons: 2);
    });

    testWidgets("keeps clear of the gesture area when that is larger", (
      tester,
    ) async {
      await pumpScreen(tester, bar(IrmaBottomBarStyle.flat), bottomInset: 48);

      final secondary = rectOf(
        tester,
        find.byKey(const Key("bottom_bar_secondary")),
      );
      expect(secondary.bottom, _screen.height - 48);
    });

    testWidgets("leaves the standard bar as it was", (tester) async {
      await pumpScreen(tester, bar(IrmaBottomBarStyle.standard));

      expect(
        rectOf(tester, find.byKey(const Key("bottom_bar_primary"))).height,
        YiviButtonSize.medium.value,
      );
      expect(
        rectOf(tester, find.byKey(const Key("bottom_bar_secondary"))).height,
        YiviButtonSize.medium.value,
      );
    });
  });

  group("button", () {
    testWidgets("draws a 1 px outline when it is slim", (tester) async {
      await pumpScreen(
        tester,
        const Scaffold(
          body: Column(
            children: [
              YiviThemedButton(
                key: Key("slim"),
                label: "email_linking.confirm.cancel",
                style: YiviButtonStyle.outlined,
                size: YiviButtonSize.slim,
              ),
              YiviThemedButton(
                key: Key("medium"),
                label: "email_linking.confirm.cancel",
                style: YiviButtonStyle.outlined,
              ),
            ],
          ),
        ),
      );

      double outline(Key key) {
        final ink = tester.widget<Ink>(
          find.descendant(of: find.byKey(key), matching: find.byType(Ink)),
        );
        return ((ink.decoration! as BoxDecoration).border! as Border).top.width;
      }

      expect(outline(const Key("slim")), 1);
      expect(outline(const Key("medium")), 1.7);
    });

    testWidgets("shows the leading widget 10 px before the label", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(
          body: YiviThemedButton(
            label: "email_linking.verify_code.checking",
            leading: SizedBox.square(key: Key("leading"), dimension: 18),
          ),
        ),
      );

      final leading = rectOf(tester, find.byKey(const Key("leading")));
      final label = rectOf(tester, find.text("Checking code…"));
      expect(label.left - leading.right, 10);
      expect(leading.center.dy, label.center.dy);
    });
  });

  group("A6 banner", () {
    Future<void> pumpBanner(WidgetTester tester) => pumpScreen(
      tester,
      Scaffold(
        backgroundColor: theme.backgroundTertiary,
        body: const SafeArea(child: Column(children: [EmailLinkBanner()])),
      ),
    );

    testWidgets("is a flat light blue surface 16 px from the edges", (
      tester,
    ) async {
      await pumpBanner(tester);

      final banner = find.byKey(const Key("email_link_banner"));
      final decoration = decorationOf(tester, banner);
      expect(decoration.color, theme.tertiary);
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNull);

      final rect = rectOf(tester, banner);
      expect(rect.left, 16);
      expect(rect.top, 16);
      expect(rect.width, _screen.width - 32);
    });

    testWidgets("leaves 8 px below it, 24 px with the list padding", (
      tester,
    ) async {
      await pumpBanner(tester);

      final outer = rectOf(tester, find.byType(EmailLinkBanner));
      final banner = rectOf(tester, find.byKey(const Key("email_link_banner")));
      expect(outer.bottom - banner.bottom, 8);
    });

    testWidgets("has a 32 px shield and text 12 px further on", (tester) async {
      await pumpBanner(tester);

      final shield = find.byIcon(Icons.verified_user);
      expect(rectOf(tester, shield), const Rect.fromLTWH(32, 32, 32, 32));
      expect(tester.widget<Icon>(shield).color, theme.link);

      final title = rectOf(tester, find.text("Secure your Yivi app"));
      expect(title.left, 76);
      expect(title.top, 32);
    });

    testWidgets("sets the title, text and link in the sizes of the board", (
      tester,
    ) async {
      await pumpBanner(tester);

      final title = styleOf(tester, find.text("Secure your Yivi app"));
      expect(title.fontSize, 16);
      expect(title.fontWeight, FontWeight.w700);
      expect(title.height, 22 / 16);
      expect(title.color, theme.dark);

      final body = styleOf(
        tester,
        find.textContaining("Link your email address."),
      );
      expect(body.fontSize, 14);
      expect(body.fontWeight, FontWeight.w400);
      expect(body.height, 20 / 14);
      expect(body.color, theme.dark);

      final link = styleOf(tester, find.text("Link email address"));
      expect(link.fontSize, 14);
      expect(link.fontWeight, FontWeight.w700);
      expect(link.height, 20 / 14);
      expect(link.color, theme.link);
      expect(link.decoration, TextDecoration.underline);
    });

    testWidgets("has a 44 px close button 2 px from the corner", (
      tester,
    ) async {
      await pumpBanner(tester);

      final banner = rectOf(tester, find.byKey(const Key("email_link_banner")));
      final close = find.descendant(
        of: find.byKey(const Key("email_link_banner_close")),
        matching: find.byType(InkWell),
      );
      final rect = rectOf(tester, close);
      expect(rect.size, const Size(44, 44));
      expect(rect.top - banner.top, 2);
      expect(banner.right - rect.right, 2);

      final icon = find.byIcon(Icons.close);
      expect(tester.getSize(icon), const Size(18, 18));
      expect(tester.widget<Icon>(icon).color, theme.dark);
      expect(
        tester.getSemantics(close),
        matchesSemantics(
          label: "Close notification",
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
    });
  });

  group("A7 sheet", () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: const SafeArea(child: Column(children: [EmailLinkBanner()])),
        ),
      );
      await tester.tap(find.byKey(const Key("email_link_banner_close")));
      await tester.pumpAndSettle();
    }

    testWidgets("is white with a 16 px corner radius and a 45% scrim", (
      tester,
    ) async {
      await pumpSheet(tester);

      final sheet = find.ancestor(
        of: find.text("Remind you later?"),
        matching: find.byType(Container),
      );
      final decoration = decorationOf(tester, sheet.first);
      expect(decoration.color, theme.surfacePrimary);
      expect(
        decoration.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(16)),
      );
      expect(
        tester.widgetList<ModalBarrier>(find.byType(ModalBarrier)).last.color,
        Colors.black.withValues(alpha: 0.45),
      );
    });

    testWidgets("has a 40 by 4 px grab handle and no close button", (
      tester,
    ) async {
      await pumpSheet(tester);

      final handle = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == theme.neutralLight,
      );
      final rect = rectOf(tester, handle);
      expect(rect.size, const Size(40, 4));
      expect(rect.center.dx, _screen.width / 2);
      expect(find.byIcon(Icons.close), findsNWidgets(1));
    });

    testWidgets("sets the title in 18 px and pads the sides 24 px", (
      tester,
    ) async {
      await pumpSheet(tester);

      final title = find.text("Remind you later?");
      final style = styleOf(tester, title);
      expect(style.fontSize, 18);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.height, 26 / 18);
      expect(style.color, theme.neutralExtraDark);
      expect(rectOf(tester, title).left, 24);
    });

    testWidgets("ends in two 48 px buttons, 32 px above the bottom", (
      tester,
    ) async {
      await pumpSheet(tester);

      final remind = rectOf(
        tester,
        find.byKey(const Key("email_link_later_remind")),
      );
      final dismiss = rectOf(
        tester,
        find.byKey(const Key("email_link_later_dismiss")),
      );
      expect(remind.height, 48);
      expect(dismiss.height, 48);
      expect(dismiss.bottom, _screen.height - 32);
      expect(dismiss.top - remind.bottom, 8);
      expect(remind.left, 24);
      expect(remind.right, _screen.width - 24);
    });
  });

  group("B1 and B2 screens", () {
    Future<ProviderContainer> pumpFlow(
      WidgetTester tester, {
      EmailIssuancePurpose purpose = EmailIssuancePurpose.linkKeyshare,
    }) => pumpScreen(tester, EmailIssuanceScreen(purpose: purpose));

    Scaffold scaffold(WidgetTester tester) =>
        tester.widget<Scaffold>(find.byType(Scaffold).last);

    testWidgets("B1 is a blue page with a borderless bar", (tester) async {
      await pumpFlow(tester);

      expect(scaffold(tester).backgroundColor, theme.backgroundTertiary);
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.shape, isNull);
      expect(bar.backgroundColor, theme.light);
      expect(tester.getSize(find.byType(AppBar)).height, 56);
    });

    testWidgets("B1 has a black back arrow centred in the bar", (tester) async {
      await pumpFlow(tester);

      final arrow = find.byIcon(Icons.arrow_back_sharp);
      expect(tester.widget<Icon>(arrow).color, theme.dark);
      expect(tester.getCenter(arrow), const Offset(28, 28));
    });

    testWidgets("B1 sets the heading in 20 px, 80 px from the top", (
      tester,
    ) async {
      await pumpFlow(tester);

      final heading = find.text("What is your email address?");
      final style = styleOf(tester, heading);
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.height, 28 / 20);
      expect(style.color, theme.neutralExtraDark);

      final rect = rectOf(tester, heading);
      expect(rect.left, 16);
      expect(rect.top, 80);
    });

    testWidgets("B1 ends in the flat bar with 48 px buttons", (tester) async {
      await pumpFlow(tester);

      expectFlatFooter(tester, buttons: 2);
    });

    testWidgets("adding the credential keeps the standard screen", (
      tester,
    ) async {
      await pumpFlow(tester, purpose: EmailIssuancePurpose.addCredential);

      expect(scaffold(tester).backgroundColor, isNull);
      expect(tester.widget<AppBar>(find.byType(AppBar)).shape, isNotNull);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.arrow_back_sharp)).color,
        theme.neutralExtraDark,
      );
      expect(
        rectOf(tester, find.byKey(const Key("bottom_bar_primary"))).height,
        YiviButtonSize.medium.value,
      );
    });

    group("B2 code", () {
      Future<void> pumpCodeScreen(WidgetTester tester) async {
        final container = await pumpFlow(tester);
        container
            .read(emailIssuanceProvider.notifier)
            .startVerification(email: "rosanne@example.com");
        await tester.pump();
      }

      testWidgets("sets the address in bold in the text", (tester) async {
        await pumpCodeScreen(tester);

        final text = tester
            .widgetList<RichText>(find.byType(RichText))
            .firstWhere(
              (rich) => rich.text.toPlainText().contains("We've sent an email"),
            );
        final spans = <TextSpan>[];
        text.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) spans.add(span);
          return true;
        });
        final address = spans.singleWhere(
          (span) => span.text == "rosanne@example.com",
        );
        expect(address.style?.fontWeight, FontWeight.bold);
      });

      testWidgets("has six white boxes of 46 by 58 px under a Code label", (
        tester,
      ) async {
        await pumpCodeScreen(tester);

        final label = find.text("Code");
        final labelStyle = styleOf(tester, label);
        expect(labelStyle.fontSize, 12);
        expect(labelStyle.fontWeight, FontWeight.w600);
        expect(labelStyle.height, 16 / 12);
        expect(labelStyle.color, theme.neutralExtraDark);

        final boxes = find.descendant(
          of: find.byType(Pinput),
          matching: find.byType(AnimatedContainer),
        );
        expect(boxes, findsNWidgets(6));
        final rects = [for (var i = 0; i < 6; i++) rectOf(tester, boxes.at(i))];
        for (final rect in rects) {
          expect(rect.size, const Size(46, 58));
        }
        expect(rects.first.left, 16);
        expect(rects.last.right, closeTo(_screen.width - 16, 0.01));
        final gaps = [
          for (var i = 1; i < 6; i++) rects[i].left - rects[i - 1].right,
        ];
        for (final gap in gaps) {
          expect(gap, closeTo(gaps.first, 0.01));
        }

        expect(rects.first.top - rectOf(tester, label).bottom, 8);
      });

      testWidgets("ends in the flat bar", (tester) async {
        await pumpCodeScreen(tester);

        expectFlatFooter(tester, buttons: 2);
      });
    });
  });

  group("B8 status and busy button", () {
    testWidgets("the status is a green check and 14 px green text", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(body: Center(child: CodeFromLinkStatus())),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, theme.success);
      expect(icon.size, 18);

      final style = styleOf(tester, find.text("Code filled in from the link"));
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, 20 / 14);
      expect(style.color, const Color(0xFF00602A));

      final iconRect = rectOf(tester, find.byIcon(Icons.check_circle));
      final textRect = rectOf(
        tester,
        find.text("Code filled in from the link"),
      );
      expect(textRect.left - iconRect.right, 8);
    });

    testWidgets("the spinner is 18 px with a 2.5 px stroke", (tester) async {
      await pumpScreen(
        tester,
        const Scaffold(body: Center(child: LinkingButtonSpinner())),
      );

      final spinner = find.byType(CircularProgressIndicator);
      expect(tester.getSize(spinner), const Size(18, 18));
      final indicator = tester.widget<CircularProgressIndicator>(spinner);
      expect(indicator.strokeWidth, 2.5);
      expect(indicator.color, theme.light);
      expect(indicator.backgroundColor, theme.light.withValues(alpha: 0.4));
      expect(indicator.value, isNull);
    });

    testWidgets(
      "the spinner stands still when the user asked for less motion",
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpScreen(
          tester,
          const Scaffold(body: Center(child: LinkingButtonSpinner())),
        );

        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .value,
          0.25,
        );
      },
    );
  });

  group("code boxes", () {
    final themes = LinkingPinThemes(theme, invalid: false);

    test("are 46 by 58 px with 24 px bold digits", () {
      for (final pin in [themes.normal, themes.focused, themes.filled]) {
        expect(pin.width, 46);
        expect(pin.height, 58);
        expect(pin.textStyle!.fontSize, 24);
        expect(pin.textStyle!.fontWeight, FontWeight.w700);
        expect(pin.textStyle!.color, theme.dark);
      }
    });

    LinearGradient gradientOf(PinTheme pin) =>
        pin.decoration!.gradient! as LinearGradient;

    test("have rounded top corners and a 1 px shadow", () {
      final decoration = themes.normal.decoration!;
      expect(
        decoration.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(8)),
      );
      final shadow = decoration.boxShadow!.single;
      expect(shadow.color, Colors.grey.shade300);
      expect(shadow.offset, const Offset(0, 1));
      expect(shadow.blurRadius, 3);
    });

    test("draw a 2 px grey line, blue when focused or filled", () {
      // The line is the last 2 of the 58 px of the gradient.
      final lineStart = 1 - 2 / 58;

      final normal = gradientOf(themes.normal);
      expect(normal.stops, [0, lineStart, lineStart, 1]);
      expect(normal.colors, [
        theme.light,
        theme.light,
        theme.neutralDark,
        theme.neutralDark,
      ]);

      final focused = gradientOf(themes.focused);
      expect(focused.colors, [
        const Color(0xFFF4F8FC),
        const Color(0xFFF4F8FC),
        theme.link,
        theme.link,
      ]);

      final filled = gradientOf(themes.filled);
      expect(filled.colors, [theme.light, theme.light, theme.link, theme.link]);
    });

    test("turn red for a wrong code", () {
      final invalid = LinkingPinThemes(theme, invalid: true);

      expect(gradientOf(invalid.normal).colors, [
        theme.errorSurface,
        theme.errorSurface,
        theme.error,
        theme.error,
      ]);
      expect(gradientOf(invalid.focused).colors.last, theme.error);
    });
  });

  group("B3 confirm", () {
    Future<void> pumpPermission(WidgetTester tester) => pumpScreen(
      tester,
      EmailLinkPermission(
        issuedCredentials: [_emailCredential],
        onDismiss: () {},
        onGivePermission: () {},
      ),
    );

    testWidgets("is a blue page with a bar that has no close button", (
      tester,
    ) async {
      await pumpPermission(tester);

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        theme.backgroundTertiary,
      );
      expect(find.text("Link email address"), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(tester.widget<AppBar>(find.byType(AppBar)).shape, isNull);
    });

    testWidgets("asks in the 20 px heading, 80 px from the top", (
      tester,
    ) async {
      await pumpPermission(tester);

      final heading = find.text(
        "Do you want to add this email address to your Yivi app?",
      );
      final style = styleOf(tester, heading);
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w700);
      expect(rectOf(tester, heading).top, 80);
    });

    testWidgets("shows a white card with a 44 px logo above the address", (
      tester,
    ) async {
      await pumpPermission(tester);

      final name = find.text("Email address").first;
      final issuer = find.text("Yivi");
      final label = find.text("Email address").last;
      final value = find.text("rosanne@example.com");

      final nameStyle = styleOf(tester, name);
      expect(nameStyle.fontSize, 16);
      expect(nameStyle.fontWeight, FontWeight.w700);
      expect(nameStyle.height, 22 / 16);

      final issuerStyle = styleOf(tester, issuer);
      expect(issuerStyle.fontSize, 14);
      expect(issuerStyle.color, theme.neutralExtraDark);

      final labelStyle = styleOf(tester, label);
      expect(labelStyle.fontSize, 14);
      expect(labelStyle.height, 20 / 14);
      expect(labelStyle.color, theme.neutralExtraDark);

      final valueStyle = styleOf(tester, value);
      expect(valueStyle.fontSize, 16);
      expect(valueStyle.fontWeight, FontWeight.w700);
      expect(valueStyle.height, 22 / 16);

      // The card has 16 px padding around the logo row, a hairline under it,
      // 12 px above the label and 16 px below the value.
      final logo = rectOf(tester, find.byType(ClipRRect).first);
      expect(logo.size, const Size(44, 44));
      expect(logo.left, 32);
      expect(rectOf(tester, name).left - logo.right, 12);
      final labelRect = rectOf(tester, label);
      expect(labelRect.top - (logo.bottom + 16 + 1), 12);
      expect(labelRect.left, 32);
      expect(rectOf(tester, value).bottom + 16, greaterThan(labelRect.bottom));
    });

    testWidgets("adds and cancels from the flat bar", (tester) async {
      await pumpPermission(tester);

      expect(find.text("Add"), findsOneWidget);
      expect(find.text("Cancel"), findsOneWidget);
      expectFlatFooter(tester, buttons: 2);
    });
  });

  group("B5 done", () {
    Future<void> pumpDone(WidgetTester tester) =>
        pumpScreen(tester, EmailLinkedScreen(onDismiss: (_) {}));

    testWidgets("is a blue page with a close button 4 px from the edge", (
      tester,
    ) async {
      await pumpDone(tester);

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        theme.backgroundTertiary,
      );
      expect(find.text("Link email address"), findsOneWidget);

      final close = find.byIcon(Icons.close);
      expect(tester.widget<Icon>(close).color, theme.dark);
      expect(tester.widget<Icon>(close).size, 22);
      expect(tester.getCenter(close), Offset(_screen.width - 28, 28));
    });

    testWidgets("shows a 260 px illustration 48 px under the bar", (
      tester,
    ) async {
      await pumpDone(tester);

      final graphic = rectOf(tester, find.byType(SuccessGraphic));
      expect(graphic.size, const Size(260, 260));
      expect(graphic.top, 56 + 48);
      expect(graphic.center.dx, _screen.width / 2);
    });

    testWidgets("sets Success 24 px, 24 px under the illustration", (
      tester,
    ) async {
      await pumpDone(tester);

      final title = find.text("Success");
      final style = styleOf(tester, title);
      expect(style.fontSize, 24);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.height, 30 / 24);
      expect(style.color, theme.neutralExtraDark);

      final graphic = rectOf(tester, find.byType(SuccessGraphic));
      final rect = rectOf(tester, title);
      expect(rect.top - graphic.bottom, 24);
      expect(rect.height, 30);

      final body = find.textContaining("Your email address has been added");
      expect(rectOf(tester, body).top - rect.bottom, 24);
      expect(rectOf(tester, body).left, 32);
    });

    testWidgets("ends in one 48 px button in the flat bar", (tester) async {
      await pumpDone(tester);

      expect(find.text("OK"), findsOneWidget);
      expectFlatFooter(tester, buttons: 1);
    });
  });

  group("Dutch copy", () {
    final nl =
        jsonDecode(File("assets/locales/nl.json").readAsStringSync())
            as Map<String, dynamic>;
    final linking = nl["email_linking"] as Map<String, dynamic>;

    test("matches the boards word for word", () {
      expect(linking["banner"], {
        "title": "Beveilig je Yivi-app",
        "body":
            "Koppel je e-mailadres. Dan kun je je app blokkeren als je telefoon kwijtraakt.",
        "link": "E-mailadres koppelen",
        "close": "Melding sluiten",
      });
      expect(linking["later"], {
        "title": "Later herinneren?",
        "body":
            "Zonder gekoppeld e-mailadres kun je je app niet op afstand blokkeren. Je kunt het altijd nog koppelen via Meer › Instellingen.",
        "remind_me": "Vraag het me later",
        "dismiss": "Negeren",
      });
      expect(linking["enter_email"], {
        "title": "E-mailadres koppelen",
        "header": "Wat is je e-mailadres?",
        "body":
            "Dan kun je je Yivi-app blokkeren als je telefoon kwijtraakt. We sturen je een e-mail met een code om het te bevestigen.",
        "label": "E-mailadres",
      });
      expect(linking["verify_code"], {
        "title": "E-mailadres koppelen",
        "header": "Vul de code in",
        "body":
            "We hebben een e-mail gestuurd naar {email}. Tik op deze telefoon op de link in de e-mail, of vul de code hier in.",
        "next_button": "Code controleren",
        "resend_button": "E-mail opnieuw sturen",
        "filled_from_link": "Code ingevuld vanuit de link",
        "label": "Code",
        "checking": "Code controleren…",
      });
      expect(linking["confirm"], {
        "title": "E-mailadres koppelen",
        "header": "Wil je dit e-mailadres aan je Yivi-app toevoegen?",
        "add": "Toevoegen",
        "cancel": "Annuleer",
      });
      expect(linking["done"], {
        "app_bar_title": "E-mailadres koppelen",
        "title": "Gelukt",
        "body":
            "Je e-mailadres is aan je Yivi-app toegevoegd. Je account is nu ook gekoppeld aan MijnYivi.",
      });
    });

    test("shares the buttons of B1 with the add-credential flow", () {
      final issuance = nl["email_issuance"] as Map<String, dynamic>;
      final enter = issuance["enter_email"] as Map<String, dynamic>;

      expect(enter["next_button"], "E-mail versturen");
      expect(enter["back_button"], "Annuleer");
    });
  });
}
