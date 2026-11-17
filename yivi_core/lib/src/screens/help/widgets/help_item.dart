import "package:material_ui/material_ui.dart";

import "../../../util/i18n.dart";
import "../../../widgets/faq_fold.dart";

class HelpItem extends StatelessWidget {
  final String headerTranslationKey;
  final Widget body;

  const HelpItem({required this.headerTranslationKey, required this.body});

  @override
  Widget build(BuildContext context) =>
      FaqFold(question: context.tr(headerTranslationKey), answer: body);
}
