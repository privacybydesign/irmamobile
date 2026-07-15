import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_client_bridge.dart";
import "../data/irma_repository.dart";
import "preferences_provider.dart";
import "store_review_provider.dart";

class IrmaRepositoryProvider extends InheritedWidget {
  final IrmaRepository repository;

  const IrmaRepositoryProvider({
    required this.repository,
    required super.child,
  });

  static IrmaRepository of(BuildContext context) {
    final IrmaRepositoryProvider? result = context
        .dependOnInheritedWidgetOfExactType<IrmaRepositoryProvider>();
    assert(result != null, "No IrmaRepository found in context");
    return result!.repository;
  }

  /// Like [of] but returns null instead of asserting when no provider is in
  /// scope (e.g. widget previews that render a PIN screen standalone).
  static IrmaRepository? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<IrmaRepositoryProvider>()
      ?.repository;

  @override
  bool updateShouldNotify(IrmaRepositoryProvider oldWidget) =>
      oldWidget.repository != repository;
}

final irmaRepositoryProvider = Provider<IrmaRepository>((ref) {
  final preferences = ref.watch(preferencesProvider);
  // Only count successful sessions for the review prompt when a store-review
  // service is injected (i.e. not in the F-Droid build).
  final storeReview = ref.watch(storeReviewServiceProvider);
  return IrmaRepository(
    client: IrmaClientBridge(debugLogging: kDebugMode),
    preferences: preferences,
    countSuccessForReview: storeReview != null,
  );
});
