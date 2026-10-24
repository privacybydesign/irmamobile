import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../providers/irma_repository_provider.dart";
import "glass/pill_buttons.dart";
import "irma_dialog.dart";

/// Opens a new e-mail to Yivi support, or explains in a dialog that no mail
/// app could be opened.
Future<void> openSupportMail(BuildContext context) async {
  final String address = FlutterI18n.translate(context, "help.contact");
  final String subject = Uri.encodeComponent(
    FlutterI18n.translate(context, "help.mail_subject"),
  );
  final mail = "mailto:$address?subject=$subject";
  try {
    await IrmaRepositoryProvider.of(context).openURLExternally(mail);
  } catch (_) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return IrmaDialog(
            title: FlutterI18n.translate(context, "help.mail_error_title"),
            content: FlutterI18n.translate(context, "help.mail_error"),
            child: FancyPillButton(
              label: FlutterI18n.translate(context, "help.mail_error_button"),
              size: PillSize.regular,
              onPressed: () => Navigator.pop(context),
            ),
          );
        },
      );
    }
  }
}

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
      child: TextLink(
        label: FlutterI18n.translate(context, label),
        textAlign: TextAlign.center,
        onPressed: onTap,
      ),
    );
  }
}
