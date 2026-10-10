import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "choice_option_row.dart";

/// A choice between options the user does not have yet, such as "Paspoort of
/// ID-kaart": one row per option, and a tap on a row starts obtaining it.
class SingleTapChoice extends StatelessWidget {
  final List<IssuanceBundle> options;
  final ValueChanged<int> onObtain;

  const SingleTapChoice({
    super.key,
    required this.options,
    required this.onObtain,
  });

  static String _bundleName(IssuanceBundle bundle) =>
      bundle.credentials.map((c) => c.name).join(", ");

  // An empty bundle has nothing to obtain, so guard against `every` being
  // vacuously true.
  static bool _isObtainable(IssuanceBundle bundle) =>
      bundle.credentials.isNotEmpty &&
      bundle.credentials.every((c) => c.issueURL != null);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          joinChoiceNames(context, options.map(_bundleName)),
          style: theme.themeData.textTheme.headlineMedium,
        ),
        SizedBox(height: theme.tinySpacing),
        TranslatedText(
          "disclosure_permission.choice.none_yet",
          style: theme.themeData.textTheme.bodyMedium,
        ),
        SizedBox(height: theme.defaultSpacing),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: ChoiceOptionRow(
              name: _bundleName(options[i]),
              logo: options[i].credentials.firstOrNull?.image,
              onTap: _isObtainable(options[i]) ? () => onObtain(i) : null,
            ),
          ),
      ],
    );
  }
}
