import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_client_bridge.dart";
import "../data/irma_repository.dart";
import "preferences_provider.dart";

/// The repository, for code that has a context but no `ref`: callbacks in
/// plain widgets and free functions that take a [BuildContext].
IrmaRepository repositoryOf(BuildContext context) => ProviderScope.containerOf(
  context,
  listen: false,
).read(irmaRepositoryProvider);

final irmaRepositoryProvider = Provider<IrmaRepository>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return IrmaRepository(
    client: IrmaClientBridge(debugLogging: kDebugMode),
    preferences: preferences,
  );
});
