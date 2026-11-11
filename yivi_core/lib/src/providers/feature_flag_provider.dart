import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/feature_flags.dart";
import "preferences_provider.dart";

/// Whether [FeatureFlag] is switched on. Flow code reads it with
/// `ref.watch(featureFlagProvider(FeatureFlag.x)).value ?? false`.
final featureFlagProvider = StreamProvider.family<bool, FeatureFlag>(
  (ref, flag) => ref.watch(preferencesProvider).getFeatureFlag(flag),
);
