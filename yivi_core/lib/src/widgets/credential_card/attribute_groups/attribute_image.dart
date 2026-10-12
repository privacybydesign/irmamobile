import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../irma_app_bar.dart";
import "attribute_value_formatting.dart";

/// An image attribute as a thumbnail that opens full screen on tap. Renders
/// nothing when the attribute holds no usable image.
class TappableAttributeImage extends StatelessWidget {
  final schemaless.Attribute attribute;
  final double maxWidth;
  final double maxHeight;

  const TappableAttributeImage({
    super.key,
    required this.attribute,
    this.maxWidth = 66,
    this.maxHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeAttributeImage(attribute.value);
    if (bytes == null) return const SizedBox.shrink();
    final image = Image.memory(
      bytes,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: IrmaAppBar(titleString: attribute.effectiveDisplayName),
              body: SingleChildScrollView(child: Center(child: image)),
            ),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        // Slightly rounded, like other surfaces in the theme.
        child: ClipRRect(
          borderRadius: IrmaTheme.of(context).borderRadius,
          child: image,
        ),
      ),
    );
  }
}
