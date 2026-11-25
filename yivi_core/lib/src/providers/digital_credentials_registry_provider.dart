import "package:flutter_riverpod/flutter_riverpod.dart";

/// Tells the platform which credentials a website can ask Yivi for through the
/// W3C Digital Credentials API. The platform only routes a request to Yivi when
/// it matches an entry registered here.
///
/// Injected from the outside via `runYiviApp`: on Android the registration is
/// stored by Google Play services, through a proprietary library that must not
/// enter the FOSS (F-Droid) build. There the provider stays `null` and nothing
/// is registered.
abstract class DigitalCredentialsRegistry {
  /// Replaces what is registered with [entries].
  ///
  /// The entries are the Go core's, as decoded JSON: see
  /// `clientmodels.DigitalCredentialsRegistryEntry` in irmago for their shape
  /// and `GetDigitalCredentialsRegistry` for what is listed. They come in
  /// several credential formats; an implementation registers the ones its
  /// platform knows and leaves out the rest.
  Future<void> register(List<Map<String, dynamic>> entries);
}

/// Null by default. Overridden in `runYiviApp` with a concrete implementation
/// in the Play Store build; left null in the F-Droid build.
final digitalCredentialsRegistryProvider =
    Provider<DigitalCredentialsRegistry?>((ref) => null);
