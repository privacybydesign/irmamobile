import "package:flutter_riverpod/flutter_riverpod.dart";

/// The tabs of the home screen.
enum HomeTab { data, activity, notifications, more }

/// The tab the home screen shows. Kept outside the HomeScreen widget, so
/// the choice survives the separate instances that different route
/// transitions create.
final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.data;

  void select(HomeTab tab) => state = tab;
}
