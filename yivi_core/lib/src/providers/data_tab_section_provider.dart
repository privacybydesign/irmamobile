import "package:flutter_riverpod/flutter_riverpod.dart";

import "./provider_helpers.dart" as helpers;

/// What the data tab shows: the credentials in the wallet, or the bank
/// accounts the user connected.
enum DataTabSection { credentials, accounts }

/// The section the data tab shows. Kept outside the data tab's own state,
/// because the home screen is built anew when the app comes back from the
/// browser or the PIN screen, and the user should then be where they were.
final dataTabSectionProvider = NotifierProvider(
  () => helpers.ValueNotifier(DataTabSection.credentials),
);
