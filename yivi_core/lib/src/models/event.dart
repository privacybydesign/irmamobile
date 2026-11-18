abstract class Event {}

/// An event the app sends over the bridge, to Go or the native plugins.
/// They match it on [wireName], so the name stays the same when the Dart
/// class is renamed or moved (and does not depend on `runtimeType`).
abstract interface class BridgeEvent implements Event {
  /// The name the event goes by on the bridge channel.
  String get wireName;

  Map<String, dynamic> toJson();
}
