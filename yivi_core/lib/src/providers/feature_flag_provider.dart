import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/feature_flags.dart";
import "preferences_provider.dart";

final featureFlagProvider = StreamProvider.family<bool, FeatureFlag>(
  (ref, flag) => ref.watch(preferencesProvider).getFeatureFlag(flag),
);
