import "package:material_ui/material_ui.dart";

import "../../../../models/eudi_configuration.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/buttons/pill_buttons.dart";

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
          ? YiviIconButton(
              icon: Icons.delete_outline_rounded,
              danger: true,
              label: context.tr("debug.cert_management.remove_cert"),
              onTap: onDelete,
            )
          : null,
    );
  }
}
