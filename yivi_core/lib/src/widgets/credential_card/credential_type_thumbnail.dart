import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/yivi_palette.dart";
import "card_art/credential_card_art.dart";

/// The card of [descriptor] as an example, drawn from the type alone: no
/// values, no instances. What the user gets when they add it.
schemaless.Credential exampleCredentialOf(CredentialDescriptor descriptor) =>
    schemaless.Credential(
      credentialId: descriptor.credentialId,
      hash: descriptor.credentialId,
      name: descriptor.name,
      issuer: descriptor.issuer,
      image: descriptor.image,
      credentialInstanceIds: const {},
      batchInstanceCountsRemaining: const {},
      attributes: const [],
      revoked: false,
      revocationSupported: false,
      issueUrl: descriptor.issueURL,
    );

/// A credential type as a small card: its own card art, in place of the
/// round logo. [owned] puts a green check on its corner (the user has one
/// already). Excluded from semantics: the row around it says what it is.
class CredentialTypeThumbnail extends StatelessWidget {
  final CredentialDescriptor? descriptor;
  final double width;
  final bool owned;
  final bool greyedOut;

  const CredentialTypeThumbnail({
    super.key,
    required CredentialDescriptor this.descriptor,
    this.width = 56,
    this.owned = false,
    this.greyedOut = false,
  });

  /// A card yet to add: a dashed card's outline with a plus.
  const CredentialTypeThumbnail.add({super.key, this.width = 56})
    : descriptor = null,
      owned = false,
      greyedOut = false;

  /// The height of a card [width] wide.
  static double heightOf(double width) => width * 226 / 358;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final height = heightOf(width);
    final descriptor = this.descriptor;
    if (descriptor == null) {
      return ExcludeSemantics(
        child: CustomPaint(
          key: const Key("credential_type_thumbnail_add"),
          painter: _DashedCard(color: palette.secondaryText),
          child: SizedBox(
            width: width,
            height: height,
            child: Icon(
              Icons.add_rounded,
              size: height * 0.5,
              color: palette.link,
            ),
          ),
        ),
      );
    }
    final check = height * 0.56;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CredentialCardArt(
              credential: exampleCredentialOf(descriptor),
              width: width,
              greyedOut: greyedOut,
            ),
            if (owned)
              Positioned(
                key: Key("${descriptor.credentialId}_owned_check"),
                right: -check * 0.3,
                top: -check * 0.3,
                child: Container(
                  width: check,
                  height: check,
                  decoration: BoxDecoration(
                    color: palette.successText,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: check * 0.6,
                    color: palette.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The outline of a card to add: dashed, with the card's corners.
class _DashedCard extends CustomPainter {
  final Color color;

  const _DashedCard({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.13;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCard old) => old.color != color;
}
