import "package:flutter/material.dart" as core;
import "package:material_ui/material_ui.dart";

/// Gives everything below it the core SDK Material context that the app root
/// used to provide before the move to `package:material_ui`.
///
/// Flutter 3.47 unbundled the Material and Cupertino widget libraries. A
/// `material_ui` [MaterialApp] installs `material_ui`'s [Theme], localizations
/// and [Material], so packages that still import `package:flutter/material.dart`
/// no longer find theirs: `flutter_markdown`, `intl_phone_number_input` and
/// `flutter_zxing` would fall back to Material's default theme instead of the
/// Yivi one, and `pinput` asserts both a [core.Material] ancestor and the core
/// Material localizations, so the email, SMS and transaction-code screens would
/// not build at all.
///
/// The [core.Material] is transparent, so it paints nothing and absorbs no hit
/// tests; it is only there to be found. [App] wraps the whole app in this.
/// Delete it once those packages have moved to the standalone libraries.
class LegacyMaterialBridge extends StatelessWidget {
  final Widget child;

  const LegacyMaterialBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return MaterialUiCompatibilityBridge(
      child: core.Material(type: core.MaterialType.transparency, child: child),
    );
  }
}
