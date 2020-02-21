import 'package:flutter/material.dart';

enum NudgeState {
  addCards,
  digidProef,
  gemeente,
}

class Nudge extends InheritedWidget {
  final NudgeState nudgeState;

  const Nudge({Key key, @required this.nudgeState, @required Widget child})
      : assert(nudgeState != null),
        assert(child != null),
        super(
          key: key,
          child: child,
        );

  static Nudge of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Nudge>();
  }

  @override
  bool updateShouldNotify(Nudge oldWidget) => nudgeState != oldWidget.nudgeState;
}
