import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "glass/glass_dialog.dart";
import "status_body.dart";

class IrmaInfoScaffoldBody extends StatelessWidget {
  final String titleTranslationKey;
  final String? bodyTranslationKey;
  final IconData? icon;

  /// Colours the disc behind [icon].
  final DialogTone tone;

  const IrmaInfoScaffoldBody({
    super.key,
    required this.titleTranslationKey,
    required this.bodyTranslationKey,
    this.icon,
    this.tone = DialogTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBody(
      title: FlutterI18n.translate(context, titleTranslationKey),
      message: bodyTranslationKey == null
          ? null
          : FlutterI18n.translate(context, bodyTranslationKey!),
      icon: icon,
      tone: tone,
    );
  }
}
