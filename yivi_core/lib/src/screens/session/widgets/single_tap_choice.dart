import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_summary.dart";
import "../../../widgets/dashed_border.dart";
import "../../../widgets/translated_text.dart";
import "choice_option_row.dart";

const _cardColor = Color(0xFFF7FAFC);
const _borderColor = Color(0xFFA3AEB9);
const _borderWidth = 2.0;
const _cardRadius = 10.0;
const _cardHorizontalPadding = 14.0;
const _titleLineHeight = 22.0;

/// A choice between options the user does not have yet, such as "Paspoort of
/// ID-kaart": a dashed card with one row per option, and a tap on a row starts
/// obtaining it.
class SingleTapChoice extends StatelessWidget {
  final List<IssuanceBundle> options;
  final ValueChanged<int> onObtain;

  const SingleTapChoice({
    super.key,
    required this.options,
    required this.onObtain,
  });

  // An empty bundle has nothing to obtain, so guard against `every` being
  // vacuously true.
  static bool _isObtainable(IssuanceBundle bundle) =>
      bundle.credentials.isNotEmpty &&
      bundle.credentials.every((c) => c.issueURL != null);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final gap = theme.smallSpacing + theme.tinySpacing;
    final titleStyle = theme.textTheme.bodyMedium!;

    return DashedBorder(
      color: _borderColor,
      width: _borderWidth,
      radius: _cardRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.all(Radius.circular(_cardRadius)),
        ),
        // The dashed border is painted over the padding, so add its width.
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _cardHorizontalPadding + _borderWidth,
            vertical: gap + _borderWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                joinChoiceNames(context, options.map(issuanceBundleName)),
                style: titleStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  height: _titleLineHeight / titleStyle.fontSize!,
                ),
              ),
              TranslatedText(
                "disclosure_permission.choice.none_yet",
                style: credentialSubtitleStyle(theme),
              ),
              SizedBox(height: gap),
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < options.length - 1 ? theme.smallSpacing : 0,
                  ),
                  child: ChoiceOptionRow(
                    name: issuanceBundleName(options[i]),
                    logo: options[i].credentials.firstOrNull?.image,
                    onTap: _isObtainable(options[i]) ? () => onObtain(i) : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
