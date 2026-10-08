import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi/portrait_lock.dart";

void main() {
  testWidgets(
    "holds the app in portrait while shown and allows all orientations after",
    (tester) async {
      final requested = <List<Object?>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == "SystemChrome.setPreferredOrientations") {
            requested.add(call.arguments as List<Object?>);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(const PortraitLock(child: SizedBox()));
      expect(requested.last, ["DeviceOrientation.portraitUp"]);

      await tester.pumpWidget(const SizedBox());
      expect(
        requested.last,
        unorderedEquals([
          "DeviceOrientation.portraitUp",
          "DeviceOrientation.portraitDown",
          "DeviceOrientation.landscapeLeft",
          "DeviceOrientation.landscapeRight",
        ]),
      );
    },
  );
}
