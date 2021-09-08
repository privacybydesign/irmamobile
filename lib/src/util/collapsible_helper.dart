// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';

Duration expandDuration = const Duration(milliseconds: 250); // expand duration of _Collapsible

jumpToCollapsable(
  ScrollController scrollController,
  GlobalKey parentKey,
  GlobalKey collapsibleKey,
) async {
  await Future.delayed(expandDuration);
  final RenderObject scrollview = parentKey.currentContext.findRenderObject();
  final RenderBox collapsable = collapsibleKey.currentContext.findRenderObject() as RenderBox;
  var desiredScrollPosition = collapsable.localToGlobal(Offset(0, scrollController.offset), ancestor: scrollview).dy;
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
