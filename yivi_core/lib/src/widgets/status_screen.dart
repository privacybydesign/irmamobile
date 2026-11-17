import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../theme/yivi_tone.dart";
import "status_body.dart";

/// A screen that only says something (an error, a warning, "update
/// required"): a [StatusBody] between an optional [appBar] and the
/// [actions] at the bottom (an IrmaBottomBar). The texts arrive translated.
class StatusScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final String title;
  final String? message;
  final String? note;
  final IconData? icon;
  final Widget? picture;
  final YiviTone tone;

  /// Overrides the disc colour that [tone] picks, e.g. white behind a logo.
  final Color? discColor;
  final Widget? footer;
  final Widget? actions;

  const StatusScreen({
    super.key,
    this.appBar,
    required this.title,
    this.message,
    this.note,
    this.icon,
    this.picture,
    this.tone = YiviTone.neutral,
    this.discColor,
    this.footer,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: appBar,
      body: StatusBody(
        title: title,
        message: message,
        note: note,
        icon: icon,
        picture: picture,
        tone: tone,
        discColor: discColor,
        footer: footer,
      ),
      bottomNavigationBar: actions,
    );
  }
}
