import "../../../models/schemaless/schemaless_events.dart";

/// The host of the requestor's website, or its name when it has no URL.
String requestorHost(TrustedParty requestor) {
  final host = Uri.tryParse(requestor.url ?? "")?.host;
  if (host == null || host.isEmpty) return requestor.name;

  return host;
}
