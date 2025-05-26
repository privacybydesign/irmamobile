import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/irma_preferences.dart';

final preferencesProvider = Provider<IrmaPreferences>(
  (ref) => throw UnimplementedError("should be overwritten in main, so we don't have to make it async"),
);
