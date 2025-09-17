import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/passport_repository.dart';

class PassportRepositoryProvider extends InheritedWidget {
  final PassportRepository repository;

  const PassportRepositoryProvider({required this.repository, required super.child});

  static PassportRepository of(BuildContext context) {
    final PassportRepositoryProvider? result = context.dependOnInheritedWidgetOfExactType<PassportRepositoryProvider>();
    assert(result != null, 'No PassportRepository found in context');
    return result!.repository;
  }

  @override
  bool updateShouldNotify(PassportRepositoryProvider oldWidget) => oldWidget.repository != repository;
}

final passportRepositoryProvider = Provider<PassportRepository>(
  (ref) {
    return PassportRepository();
  },
);
