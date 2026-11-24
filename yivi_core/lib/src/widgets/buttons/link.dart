import "package:material_ui/material_ui.dart";

import "../../util/i18n.dart";
import "pill_buttons.dart";

/// A text link: [label] (a translation key or a text) as a [TextLink].
class Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const Link({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      key: const Key("irma_link"),
      child: TextLink(label: context.tr(label), onPressed: onTap),
    );
  }
}
