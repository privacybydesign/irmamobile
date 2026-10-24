import "package:material_ui/material_ui.dart";

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
