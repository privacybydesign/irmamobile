import 'package:flutter/cupertino.dart';

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
