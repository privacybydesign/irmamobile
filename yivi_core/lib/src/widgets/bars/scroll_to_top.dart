import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

/// Scrolls the vertical lists shown under [root] back to their top, as iOS
/// does on a tap on the status bar or on the selected tab. Only the lists the
/// user sees: a hit test at a list's centre has to reach it, so a list under
/// a sheet, in a tab kept out of sight or on a page under another is left
/// alone. Every one that is visible scrolls (both panes side by side, say).
void scrollListsToTop(BuildContext root) {
  final view = View.maybeOf(root);
  if (view == null) return;
  final lists = <ScrollableState>[];
  void visit(Element element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      lists.add(element.state as ScrollableState);
    }
    element.visitChildren(visit);
  }

  root.visitChildElements(visit);
  for (final list in lists) {
    if (axisDirectionToAxis(list.axisDirection) != Axis.vertical) continue;
    final position = list.position;
    if (!position.hasPixels || position.pixels <= position.minScrollExtent) {
      continue;
    }
    if (!_seen(list, view.viewId)) continue;
    position.animateTo(
      position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }
}

/// Whether a tap at the centre of [list] would reach it.
bool _seen(ScrollableState list, int viewId) {
  final box = list.context.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return false;
  final centre = box.localToGlobal(box.size.center(Offset.zero));
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, centre, viewId);
  return result.path.any((entry) => entry.target == box);
}

/// On iOS, a tap on the status bar scrolls the lists in sight to their top
/// ([scrollListsToTop]), as in native apps, also in a sheet. The tap never
/// reaches the app as a touch: iOS sends it to the engine, which passes it
/// on as [WidgetsBindingObserver.handleStatusBarTap].
class StatusBarScrollsToTop extends StatefulWidget {
  final Widget child;

  const StatusBarScrollsToTop({super.key, required this.child});

  @override
  State<StatusBarScrollsToTop> createState() => _StatusBarScrollsToTopState();
}

class _StatusBarScrollsToTopState extends State<StatusBarScrollsToTop>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void handleStatusBarTap() => scrollListsToTop(context);

  @override
  Widget build(BuildContext context) => widget.child;
}
