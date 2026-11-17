/// Something the Notifications tab shows. Immutable: marking it read or
/// dismissed makes a new one.
abstract class Notification {
  const Notification();

  String get id;
  bool get read;

  /// Dismissed by the user; kept in the records but not shown.
  bool get softDeleted;
  DateTime get timestamp;

  /// Translation keys of its title and message.
  String get titleKey;
  String get messageKey;

  /// This notification, read or dismissed.
  Notification copyWith({bool? read, bool? softDeleted});
}
