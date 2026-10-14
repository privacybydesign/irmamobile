import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";

/// What the detail pane of a tablet layout shows. Null means nothing was
/// picked yet; each tab then picks its own default.
class PaneSelection<T> extends Notifier<T?> {
  @override
  T? build() => null;

  void select(T? value) => state = value;
}

/// The card (credential instance hash) open in the data tab's detail pane.
final selectedCardProvider = NotifierProvider<PaneSelection<String>, String?>(
  PaneSelection<String>.new,
);

/// The log entry open in the activity tab's detail pane.
final selectedActivityProvider =
    NotifierProvider<PaneSelection<LogInfo>, LogInfo?>(
      PaneSelection<LogInfo>.new,
    );

/// The card open in the notifications tab's detail pane.
final selectedNotificationCardProvider =
    NotifierProvider<PaneSelection<String>, String?>(PaneSelection<String>.new);
