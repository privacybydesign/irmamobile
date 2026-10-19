import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../models/eudi_configuration.dart";
import "../../../../widgets/glass/pill_buttons.dart";

class CertManagerTile extends StatelessWidget {
  final Cert cert;
  final Function()? onTap;
  final Function()? onDelete;

  const CertManagerTile({required this.cert, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(cert.subject),
      onTap: onTap,
      trailing: cert.deleteable && onDelete != null
          ? PlainIconButton(
              icon: Icons.delete_outline_rounded,
              danger: true,
              semanticsLabel: FlutterI18n.translate(
                context,
                "debug.cert_management.remove_cert",
              ),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
