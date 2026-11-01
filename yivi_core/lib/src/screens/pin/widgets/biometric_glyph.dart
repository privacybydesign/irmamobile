import "dart:io";

import "package:flutter_svg/flutter_svg.dart";
import "package:local_auth/local_auth.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";

/// The glyph of biometric unlock for [type], in [color]: Apple's Face ID
/// glyph for face unlock on iOS, the face icon for face unlock elsewhere,
/// and the fingerprint otherwise (Touch ID, fingerprint sensors, unknown).
class BiometricGlyph extends StatelessWidget {
  final BiometricType? type;
  final Color color;

  /// Its width and height; the icon theme's size when null.
  final double? size;

  const BiometricGlyph({
    super.key,
    required this.type,
    required this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (type != BiometricType.face) {
      return Icon(Icons.fingerprint, size: size, color: color);
    }
    // Face ID's glyph is Apple's: only on iOS.
    if (!Platform.isIOS) return Icon(Icons.face, size: size, color: color);
    return SvgPicture.asset(
      yiviAsset("ui/face_id.svg"),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
