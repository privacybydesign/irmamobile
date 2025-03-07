import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/irma_client_bridge.dart';
import '../data/irma_preferences.dart';
import '../data/irma_repository.dart';

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

final preferencesProvider = Provider<IrmaPreferences>(
  (ref) => throw UnimplementedError("should be overwritten in main, so we don't have to make it async"),
);

final irmaRepositoryProvider = Provider<IrmaRepository>(
  (ref) {
    final preferences = ref.watch(preferencesProvider);
    return IrmaRepository(
      client: IrmaClientBridge(debugLogging: kDebugMode),
      preferences: preferences,
    );
  },
);
