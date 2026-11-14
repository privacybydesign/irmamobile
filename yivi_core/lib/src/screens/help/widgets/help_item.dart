import "package:material_ui/material_ui.dart";

import "../../../util/i18n.dart";
import "../../../widgets/collapsible.dart";

class HelpItem extends StatelessWidget {
  final String headerTranslationKey;
  final Widget body;

  const HelpItem({required this.headerTranslationKey, required this.body});

  @override
  Widget build(BuildContext context) =>
      Collapsible(header: context.tr(headerTranslationKey), content: body);
}
