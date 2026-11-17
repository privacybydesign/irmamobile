import "package:material_ui/material_ui.dart";

import "../../../util/after_frame.dart";

/// The field of a home tab's search: its text and focus, and "a tap in the
/// field starts the search" ([onFocus], each time it gets the focus). Made
/// and disposed by the tab's State ([host]).
class SearchTabController {
  final State host;
  final TextEditingController field;
  final FocusNode focus = FocusNode();

  SearchTabController(
    this.host, {
    String text = "",
    required VoidCallback onFocus,
  }) : field = TextEditingController(text: text) {
    focus.addListener(() {
      if (focus.hasFocus) onFocus();
    });
  }

  /// Runs [start], then focuses the field once it has moved into the bar.
  void startInBar(VoidCallback start) {
    start();
    host.afterFrame(focus.requestFocus);
  }

  /// Empties the field and puts the keyboard away.
  void stop() {
    field.clear();
    focus.unfocus();
  }

  /// Brings the keyboard back once the card above the tab has gone, when
  /// [wanted] says so once this page is on top: the tab is also built anew
  /// while the card is still open, and then it waits for the next call
  /// (didPopNext).
  void showKeyboardWhenOnTop(bool Function() wanted) => host.afterFrame(() {
    if (ModalRoute.of(host.context)?.isCurrent == false) return;
    if (!wanted()) return;
    _whenCardGone(_showKeyboard);
  });

  /// Runs [then] once the card above this page has finished going, looked
  /// at frame by frame: the route's animation does not report it.
  void _whenCardGone(VoidCallback then, {int frames = 120}) {
    final going = ModalRoute.of(host.context)?.secondaryAnimation;
    if (going == null || going.isDismissed || frames == 0) return then();
    host.afterFrame(() => _whenCardGone(then, frames: frames - 1));
    WidgetsBinding.instance.scheduleFrame();
  }

  /// As the card goes, the page gives the field its focus back by itself,
  /// but without the keyboard, and asking a field that has the focus does
  /// not bring it up then (seen on iOS): the field lets go and is asked
  /// afresh, as a tap on it would.
  void _showKeyboard() {
    void ask() => focus.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.requestKeyboard();
    if (!focus.hasFocus) return ask();
    focus.unfocus();
    host.afterFrame(ask);
  }

  void dispose() {
    field.dispose();
    focus.dispose();
  }
}
