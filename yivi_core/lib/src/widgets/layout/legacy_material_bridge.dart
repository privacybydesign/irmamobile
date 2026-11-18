import "package:flutter/foundation.dart" show SynchronousFuture;
import "package:flutter/material.dart" as core;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

/// Gives everything below it the core SDK Material context that the app root
/// used to provide before the move to `package:material_ui`.
///
/// Flutter 3.47 unbundled the Material and Cupertino widget libraries. A
/// `material_ui` [MaterialApp] installs `material_ui`'s [Theme], localizations
/// and [Material], so packages that still import `package:flutter/material.dart`
/// no longer find theirs: `flutter_markdown_plus`, `intl_phone_number_input` and
/// `flutter_zxing` would fall back to Material's default theme instead of the
/// Yivi one, and `pinput` asserts both a [core.Material] ancestor and the core
/// Material localizations, so the email, SMS and transaction-code screens would
/// not build at all.
///
/// The [core.Material] is transparent, so it paints nothing and absorbs no hit
/// tests; it is only there to be found. [App] wraps the whole app in this.
/// Delete it once those packages have moved to the standalone libraries.
///
/// `MaterialUiCompatibilityBridge` installs its localizations with a
/// [Localizations.override], which re-runs *every* delegate of the scope above
/// it in a second scope — including the app's asynchronous
/// [FlutterI18nDelegate]. Left alone that costs more than a frame:
///
///  * [Localizations] renders a `SizedBox.shrink()` until its delegates resolve,
///    so the whole app below this widget is unmounted for an extra asynchronous
///    load at startup, and no frame is scheduled while it is in flight.
///  * [FlutterI18nDelegate] keeps its `FlutterI18n` in a static field and skips
///    loading when the shared translation map is already populated for the
///    locale it is handed, so two scopes loading it race. On a language change
///    the inner scope can resolve against the map of the *old* locale and then
///    never rebuild, leaving every screen below this widget untranslated.
///
/// So hand the inner scopes the [FlutterI18n] the app root already resolved,
/// wrapped in a delegate that returns it synchronously. `Localizations` only
/// loads the first delegate per type, so the app's own [FlutterI18nDelegate] is
/// shadowed rather than run a second time, and since every other delegate in
/// play resolves synchronously the bridge as a whole costs no asynchronous hop.
class LegacyMaterialBridge extends StatelessWidget {
  final Widget child;

  const LegacyMaterialBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Widget bridged =
        // ignore: deprecated_member_use
        MaterialUiCompatibilityBridge(
          child: core.Material(
            type: core.MaterialType.transparency,
            child: child,
          ),
        );

    // Null only in a tree that has no FlutterI18n above this widget, which the
    // app never builds; there is then nothing to shadow.
    final i18n = Localizations.of<FlutterI18n>(context, FlutterI18n);
    if (i18n == null) return bridged;

    return Localizations.override(
      context: context,
      delegates: [_ResolvedFlutterI18nDelegate(i18n)],
      child: bridged,
    );
  }
}

/// Hands out an already-loaded [FlutterI18n] without going through
/// [FlutterI18nDelegate], whose `load` is asynchronous even when the
/// translations it would return are already in memory.
class _ResolvedFlutterI18nDelegate extends LocalizationsDelegate<FlutterI18n> {
  const _ResolvedFlutterI18nDelegate(this.i18n);

  final FlutterI18n i18n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FlutterI18n> load(Locale locale) => SynchronousFuture(i18n);

  @override
  bool shouldReload(_ResolvedFlutterI18nDelegate old) =>
      !identical(old.i18n, i18n);
}
