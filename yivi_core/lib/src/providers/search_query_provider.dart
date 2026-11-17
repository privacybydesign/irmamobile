import "package:flutter_riverpod/flutter_riverpod.dart";

/// The Data tab's search: what is typed, whether it is on (from a tap in
/// the field until Cancel, also with nothing typed yet), and whether the
/// field gets the keyboard back when a card opened from the results
/// closes. Kept outside the tab, so the search is still there when the tab
/// is built anew.
typedef DataSearch = ({String query, bool active, bool refocus});

final dataSearchProvider = NotifierProvider<DataSearchNotifier, DataSearch>(
  DataSearchNotifier.new,
);

class DataSearchNotifier extends Notifier<DataSearch> {
  @override
  DataSearch build() => (query: "", active: false, refocus: false);

  void type(String query) =>
      state = (query: query, active: state.active, refocus: state.refocus);

  void start() =>
      state = (query: state.query, active: true, refocus: state.refocus);

  /// Cancel: nothing typed, and no search.
  void stop() => state = (query: "", active: false, refocus: state.refocus);

  /// A card opened from the results: with the keyboard up, the field gets
  /// it back when the card closes.
  void cardOpened({required bool keyboardUp}) => state = (
    query: state.query,
    active: state.active,
    refocus: state.active && keyboardUp,
  );

  /// Whether the field should get the keyboard back; asking clears it.
  bool takeRefocus() {
    final refocus = state.refocus;
    if (refocus) {
      state = (query: state.query, active: state.active, refocus: false);
    }
    return refocus;
  }
}
