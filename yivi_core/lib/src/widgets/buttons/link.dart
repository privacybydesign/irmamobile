import "package:material_ui/material_ui.dart";

import "../../providers/irma_repository_provider.dart";
import "../../util/i18n.dart";
import "../feedback/dialog.dart";
import "pill_buttons.dart";

/// Opens a new e-mail to Yivi support, or explains in a dialog that no mail
/// app could be opened.
Future<void> openSupportMail(BuildContext context) async {
  final String address = context.tr("help.contact");
  final String subject = Uri.encodeComponent(context.tr("help.mail_subject"));
  final mail = "mailto:$address?subject=$subject";
  try {
    await browserOf(context).openExternally(mail);
  } catch (_) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return YiviDialog(
            title: context.tr("help.mail_error_title"),
            message: context.tr("help.mail_error"),
            actions: [
              PrimaryPillButton(
                label: context.tr("help.mail_error_button"),
                size: PillSize.regular,
                onPressed: () => Navigator.pop(context),
              ),
            ],
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
      child: TextLink(label: context.tr(label), onPressed: onTap),
    );
  }
}
