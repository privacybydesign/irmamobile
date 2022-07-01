import 'package:flutter/material.dart';

const _expandDuration = Duration(milliseconds: 250); // expand duration of _Collapsible

// TODO: move to class
Future<void> jumpToCollapsable(ScrollController scrollController, GlobalKey key) async {
  await Future.delayed(_expandDuration);

  RenderObject? scrollableRenderObject;
  key.currentContext?.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is Scrollable && widget.controller == scrollController) {
      scrollableRenderObject = element.renderObject;
      return false;
    }
    return true;
  });
  if (scrollableRenderObject == null) return;

  final collapsable = key.currentContext?.findRenderObject();
  if (collapsable == null || collapsable is! RenderBox) return;

  var desiredScrollPosition =
      collapsable.localToGlobal(Offset(0, scrollController.offset), ancestor: scrollableRenderObject).dy;
  if (desiredScrollPosition > scrollController.position.maxScrollExtent) {
    desiredScrollPosition = scrollController.position.maxScrollExtent;
  }
  scrollController.animateTo(
    desiredScrollPosition,
    duration: const Duration(
      milliseconds: 500,
    ),
    curve: Curves.ease,
  );
}
