import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/flight/yivi_flight.dart";

const _copy = Key("flight_copy");

void main() {
  final source = GlobalKey(debugLabel: "source");
  final target = GlobalKey(debugLabel: "target");
  late BuildContext page;

  tearDown(YiviFlight.reset);

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            disableAnimations: reduceMotion,
          ),
          child: Builder(
            builder: (context) {
              page = context;
              return Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 100,
                    child: FlightSpot(
                      flightKey: source,
                      child: const SizedBox(width: 100, height: 60),
                    ),
                  ),
                  Positioned(
                    left: 200,
                    top: 500,
                    child: FlightSpot(
                      flightKey: target,
                      child: const SizedBox(width: 160, height: 100),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double spotOpacity(WidgetTester tester, GlobalKey key) => tester
      .widget<Opacity>(
        find
            .ancestor(of: find.byKey(key), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  bool start(
    WidgetTester tester, {
    VoidCallback? onLanded,
    Duration delay = Duration.zero,
  }) => YiviFlight.start(
    page,
    from: source,
    to: YiviFlight.boxOf(target),
    copy: (context, frame) => SizedBox.fromSize(size: frame.size),
    keys: FlightKey.carry(),
    duration: const Duration(milliseconds: 620),
    delay: delay,
    hide: [source, target],
    copyKey: _copy,
    onLanded: onLanded,
  );

  testWidgets("follows the beats: picked up in place, carried, put down", (
    tester,
  ) async {
    await pump(tester);
    expect(start(tester), isTrue);
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(_copy)), const Offset(20, 100));

    // At the end of the first beat it is still where it was, lifted 4 up.
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.getTopLeft(find.byKey(_copy)).dx, closeTo(20, 0.5));
    expect(tester.getTopLeft(find.byKey(_copy)).dy, closeTo(96, 0.5));

    // At the hold it is over the target, still lifted.
    await tester.pump(const Duration(milliseconds: 380));
    expect(tester.getTopLeft(find.byKey(_copy)).dx, closeTo(200, 0.5));
    expect(tester.getSize(find.byKey(_copy)), const Size(160, 100));
  });

  testWidgets("hides both places, shows them before the copy goes", (
    tester,
  ) async {
    await pump(tester);
    var landed = false;
    start(tester, onLanded: () => landed = true);
    await tester.pump();
    expect(spotOpacity(tester, source), 0);
    expect(spotOpacity(tester, target), 0);

    await tester.pump(const Duration(milliseconds: 640));
    expect(landed, isTrue);
    await tester.pump();
    // The places show while the copy is still there: no frame without both.
    expect(spotOpacity(tester, target), 1);
    expect(find.byKey(_copy), findsOneWidget);

    await tester.pump();
    await tester.pump();
    expect(find.byKey(_copy), findsNothing);
    expect(YiviFlight.isFlying, isFalse);
  });

  testWidgets("waits at the start during its delay", (tester) async {
    await pump(tester);
    start(tester, delay: const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getTopLeft(find.byKey(_copy)), const Offset(20, 100));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_copy), findsNothing);
  });

  testWidgets("with reduce motion nothing flies and it lands at once", (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);
    var landed = false;
    expect(start(tester, onLanded: () => landed = true), isFalse);
    expect(landed, isTrue);
    await tester.pump();
    expect(find.byKey(_copy), findsNothing);
    expect(spotOpacity(tester, target), 1);
  });

  testWidgets("a place hidden while a new page builds: no error, and the "
      "places already there hear of it after the frame", (tester) async {
    final place = GlobalKey();
    final show = ValueNotifier(false);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            FlightSpot(flightKey: place, child: const SizedBox(height: 10)),
            ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (context, shown, _) =>
                  shown ? _HidesOnInit(place) : const SizedBox(),
            ),
          ],
        ),
      ),
    );
    show.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(YiviFlight.hidden.value, contains(place));
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byType(SizedBox).first,
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0,
    );
  });
}

/// Hides [place] in its initState, as a sheet hides the row a card lands
/// on.
class _HidesOnInit extends StatefulWidget {
  final GlobalKey place;

  const _HidesOnInit(this.place);

  @override
  State<_HidesOnInit> createState() => _HidesOnInitState();
}

class _HidesOnInitState extends State<_HidesOnInit> {
  @override
  void initState() {
    super.initState();
    YiviFlight.hide([widget.place]);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
