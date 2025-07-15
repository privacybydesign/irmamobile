import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/irma_client_bridge.dart';
import '../data/irma_repository.dart';
import 'preferences_provider.dart';

class IrmaRepositoryProvider extends InheritedWidget {
  final IrmaRepository repository;

  const IrmaRepositoryProvider({required this.repository, required super.child});

  static IrmaRepository of(BuildContext context) {
    final IrmaRepositoryProvider? result = context.dependOnInheritedWidgetOfExactType<IrmaRepositoryProvider>();
    assert(result != null, 'No IrmaRepository found in context');
    return result!.repository;
  }

  @override
  bool updateShouldNotify(IrmaRepositoryProvider oldWidget) => oldWidget.repository != repository;
}

final irmaRepositoryProvider = Provider<IrmaRepository>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return IrmaRepository(
    client: IrmaClientBridge(debugLogging: kDebugMode),
    preferences: preferences,
  );
});
