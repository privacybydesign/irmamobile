import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart" show LogoImage;
import "base64_image.dart";
import "irma_avatar.dart";

/// The deep colours of a party without a logo: one per name, so the same
/// party always gets the same colour and parties are told apart.
const _fills = [
  Color(0xFF2F5D8A),
  Color(0xFF7A1F2E),
  Color(0xFF3D6B4F),
  Color(0xFF6B4E8A),
  Color(0xFF8A5A2F),
];

/// The fill behind [name]'s initial, the same wherever the party shows (its
/// name may have non-breaking hyphens in one place and plain ones in another).
Color partyInitialFill(String name) {
  final key = name.trim().replaceAll("‑", "-");
  return _fills[key.codeUnits.fold(0, (a, c) => a + c) % _fills.length];
}

/// The first letter of a party without a logo, white, for a [size] disc or
/// tile in [partyInitialFill].
class PartyInitial extends StatelessWidget {
  final String name;
  final double size;

  const PartyInitial({super.key, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return Text(
      trimmed.isEmpty ? "?" : trimmed.characters.first.toUpperCase(),
      style: TextStyle(
        fontFamily: "Alexandria",
        fontWeight: FontWeight.w700,
        fontSize: size * 0.44,
        height: 1,
        color: Colors.white,
      ),
    );
  }
}

/// A party's logo as a circle: the share screen's requestor, the other
/// party in Activity. Without a logo its initial on [partyInitialFill].
class PartyAvatar extends StatelessWidget {
  final String name;
  final LogoImage? image;
  final String? imagePath;
  final double size;

  const PartyAvatar({
    super.key,
    required this.name,
    required this.size,
    this.image,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image == null && imagePath == null) {
      return Semantics(
        label: name,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: partyInitialFill(name),
            shape: BoxShape.circle,
          ),
          child: ExcludeSemantics(
            child: PartyInitial(name: name, size: size),
          ),
        ),
      );
    }
    return IrmaAvatar(
      size: size,
      logoImage: image == null
          ? null
          : Base64Image(base64: image.base64, mimeType: image.mimeType),
      logoPath: image == null ? imagePath : null,
      logoSemanticsLabel: name,
      initials: name.isEmpty ? "?" : name.characters.first,
    );
  }
}
