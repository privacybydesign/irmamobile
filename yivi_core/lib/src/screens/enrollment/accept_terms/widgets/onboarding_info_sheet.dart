import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../package_name.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/translated_text.dart";

const double _barrierOpacity = 0.45;
const double _cornerRadius = 16;
const double _topSpacing = 12;
const double _bottomSpacing = 40;
const double _handleWidth = 40;
const double _handleHeight = 4;
const double _closeButtonSize = 44;
const double _closeIconSize = 22;
// The close button reaches into the side padding, so its icon lines up with
// the edge of the text.
const double _closeButtonOverhang = 12;

/// Shows the info sheet of onboarding v2: a handle, a title with a close
/// button and a text.
Future<void> showOnboardingInfoSheet({
  required BuildContext context,
  required String titleKey,
  required String textKey,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: _barrierOpacity),
  builder: (context) =>
      _OnboardingInfoSheet(titleKey: titleKey, textKey: textKey),
);

class _OnboardingInfoSheet extends StatelessWidget {
  final String titleKey;
  final String textKey;

  const _OnboardingInfoSheet({required this.titleKey, required this.textKey});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_cornerRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            theme.mediumSpacing,
            _topSpacing,
            theme.mediumSpacing,
            _bottomSpacing,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.neutralLight,
                    borderRadius: BorderRadius.circular(_handleHeight / 2),
                  ),
                  child: const SizedBox(
                    width: _handleWidth,
                    height: _handleHeight,
                  ),
                ),
              ),
              SizedBox(height: theme.smallSpacing + theme.tinySpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: theme.smallSpacing),
                      child: TranslatedText(
                        titleKey,
                        style: theme.textTheme.displaySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 26 / 18,
                        ),
                        isHeader: true,
                      ),
                    ),
                  ),
                  SizedBox(width: theme.defaultSpacing),
                  Transform.translate(
                    offset: const Offset(_closeButtonOverhang, 0),
                    child: const _CloseButton(),
                  ),
                ],
              ),
              SizedBox(height: theme.smallSpacing + theme.tinySpacing),
              Flexible(
                child: SingleChildScrollView(child: TranslatedText(textKey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: FlutterI18n.translate(context, "accessibility.close"),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: Navigator.of(context).pop,
        child: SizedBox.square(
          dimension: _closeButtonSize,
          child: Center(
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                yiviAsset("ui/onboarding_close.svg"),
                width: _closeIconSize,
                height: _closeIconSize,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
