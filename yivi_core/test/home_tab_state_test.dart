import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/clear_all_data_event.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/home/widgets/irma_nav_bar.dart";

class _OtherEvent extends Event {}

void main() {
  late StreamController<Event> events;
  late HomeTabState tabs;

  setUp(() {
    events = StreamController<Event>();
    tabs = HomeTabState(repositoryEvents: events.stream);
    addTearDown(tabs.close);
    addTearDown(events.close);
  });

  test("starts on the data tab", () {
    expect(tabs.state, IrmaNavBarTab.data);
  });

  test("deleting all data goes back to the data tab", () async {
    tabs.add(IrmaNavBarTab.more);
    await pumpEventQueue();
    expect(tabs.state, IrmaNavBarTab.more);

    events.add(ClearAllDataEvent());
    await pumpEventQueue();

    expect(tabs.state, IrmaNavBarTab.data);
  });

  test("other events keep the tab", () async {
    tabs.add(IrmaNavBarTab.more);
    await pumpEventQueue();

    events.add(_OtherEvent());
    await pumpEventQueue();

    expect(tabs.state, IrmaNavBarTab.more);
  });
}
