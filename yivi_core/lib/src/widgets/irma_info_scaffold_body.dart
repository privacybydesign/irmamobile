import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/i18n.dart";
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
      title: context.tr(titleTranslationKey),
      message: bodyTranslationKey == null
          ? null
          : context.tr(bodyTranslationKey!),
      icon: icon,
      tone: tone,
    );
  }
}

/// A screen that only says something: an [IrmaInfoScaffoldBody] between an
/// optional [appBar] and the [bottomBar] with what to do.
class IrmaInfoScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final IconData icon;
  final DialogTone tone;
  final String titleTranslationKey;
  final String bodyTranslationKey;
  final Widget bottomBar;

  const IrmaInfoScreen({
    super.key,
    this.appBar,
    required this.icon,
    required this.tone,
    required this.titleTranslationKey,
    required this.bodyTranslationKey,
    required this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: appBar,
      body: IrmaInfoScaffoldBody(
        icon: icon,
        tone: tone,
        titleTranslationKey: titleTranslationKey,
        bodyTranslationKey: bodyTranslationKey,
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
