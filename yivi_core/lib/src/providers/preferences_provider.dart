import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_preferences.dart";

final preferencesProvider = Provider<IrmaPreferences>(
  (ref) => throw UnimplementedError(
    "should be overwritten in main, so we don't have to make it async",
  ),
);

/// Whether the user opted for a 16-digit PIN (vs the default 5-digit).
final longPinProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getLongPin(),
);
