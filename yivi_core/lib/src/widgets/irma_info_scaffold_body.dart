import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "glass/glass_dialog.dart";
import "glass/pill_buttons.dart";
import "irma_dialog.dart";
import "status_body.dart";
import "translated_text.dart";

class IrmaInfoScaffoldBody extends StatelessWidget {
  final String titleTranslationKey;
  final Map<String, String>? titleTranslationParams;
  final String? bodyTranslationKey;
  final Map<String, String>? bodyTranslationParams;
  final String? imagePath;
  final IconData? icon;
  final Color? iconColor;
  final String? linkTranslationKey;
  final String? linkDialogText;

  /// Colours the disc behind [icon] or [imagePath].
  final DialogTone tone;

  const IrmaInfoScaffoldBody({
    super.key,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    this.bodyTranslationParams,
    required this.bodyTranslationKey,
    this.imagePath,
    this.icon,
    this.iconColor,
    this.linkDialogText,
    this.linkTranslationKey,
    this.tone = DialogTone.neutral,
  }) : assert(
         iconColor == null || icon != null,
         "Icon color can only be used when an icon is provided",
       ),
       assert(
         linkTranslationKey != null || linkDialogText == null,
         "If you specify a linkKey, also set a linkDialogKey",
       ),
       assert(
         imagePath == null || icon == null,
         "You cannot provide both an icon and an image path",
       );

  Future _showIrmaDialog(BuildContext context) async => showDialog(
    context: context,
    builder: (context) {
      return IrmaDialog(
        title: FlutterI18n.translate(context, "error.details_title"),
        content: linkDialogText!,
        child: FancyPillButton(
          label: FlutterI18n.translate(context, "error.button_ok"),
          size: PillSize.regular,
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key, Map<String, String>? params) =>
        FlutterI18n.translate(context, key, translationParams: params);

    return StatusBody(
      title: t(titleTranslationKey, titleTranslationParams),
      message: bodyTranslationKey == null
          ? null
          : t(bodyTranslationKey!, bodyTranslationParams),
      icon: icon,
      iconColor: iconColor,
      tone: tone,
      picture: imagePath == null
          ? null
          : SizedBox.square(
              dimension: 96,
              child: imagePath!.endsWith("svg")
                  ? SvgPicture.asset(imagePath!)
                  : Image.asset(imagePath!),
            ),
      footer: linkTranslationKey == null
          ? null
          : Semantics(
              link: true,
              child: GestureDetector(
                onTap: () {
                  _showIrmaDialog(context);
                  Feedback.forTap(context);
                },
                child: TranslatedText(
                  linkTranslationKey!,
                  style: palette
                      .body(16, weight: FontWeight.w600)
                      .copyWith(
                        decoration: TextDecoration.underline,
                        color: palette.link,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
