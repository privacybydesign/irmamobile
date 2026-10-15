import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);
  final List<Credential> items;
  @override
  Future<List<Credential>> build() async => items;
}

final _card = testCredential(
  type: "pbdf.sidn-pbdf.email",
  hash: "email",
  name: "Email address",
  // Enough to scroll.
  attributes: [
    stringAttr("email", "s.devries@werk.example"),
    for (var i = 0; i < 20; i++) stringAttr("extra$i", "value $i"),
  ],
);

/// iOS bounces at the top, Android stretches: the pull works on both.
final _platforms = TargetPlatformVariant(const {
  TargetPlatform.iOS,
  TargetPlatform.android,
});

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<void> openDetail(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: <Override>[
        irmaRepositoryProvider.overrideWithValue(repo),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder([_card]),
        ),
      ],
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CredentialDetailScreen(hash: "email"),
              ),
            ),
            child: const Text("open"),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.byType(CredentialDetailScreen), findsOneWidget);
  }

  testWidgets("pulling down at the top dismisses the page", (tester) async {
    await openDetail(tester);

    await tester.drag(
      find.byType(ListView),
      const Offset(0, 260),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CredentialDetailScreen), findsNothing);
  }, variant: _platforms);

  testWidgets("a drag that starts scrolled down only scrolls, past the top "
      "too", (tester) async {
    await openDetail(tester);
    final list = find.byType(ListView);
    final top = tester.getTopLeft(list);
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position;
    position.jumpTo(200);
    await tester.pump();

    // One drag down: back to the top and on, far enough to dismiss.
    final gesture = await tester.startGesture(tester.getCenter(list));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
    }
    // At the top, or bouncing past it on iOS.
    expect(position.pixels, lessThanOrEqualTo(position.minScrollExtent));
    // The page did not move down: no pull, only the usual stretch.
    expect(tester.getTopLeft(list), top);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(CredentialDetailScreen), findsOneWidget);
  }, variant: _platforms);

  testWidgets("a short pull springs back", (tester) async {
    await openDetail(tester);
    final top = tester.getTopLeft(find.byType(ListView));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    // The page follows the finger.
    expect(tester.getTopLeft(find.byType(ListView)).dy, greaterThan(top.dy));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(CredentialDetailScreen), findsOneWidget);
    expect(tester.getTopLeft(find.byType(ListView)), top);
  }, variant: _platforms);

  test("scrolled down, a drag scrolls; only at the top it pulls", () {
    final pull = ValueNotifier<double>(0);
    final physics = PullToDismissPhysics(
      pull: pull,
      canPull: () => true,
      onRelease: (_) {},
    );
    FixedScrollMetrics at(double pixels) => FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: pixels,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    // Scrolled down: dragging down scrolls back up, no pull.
    expect(physics.applyPhysicsToUserOffset(at(300), 40), 40);
    expect(pull.value, 0);

    // At the top: dragging down pulls instead of scrolling.
    expect(physics.applyPhysicsToUserOffset(at(0), 40), 0);
    expect(pull.value, greaterThan(0));

    // Dragging back up takes the pull away first.
    physics.applyPhysicsToUserOffset(at(0), -1000);
    expect(pull.value, 0);
  });
}
