import "package:flutter/material.dart";

import "../../../../models/eudi_configuration.dart";
import "../../../../widgets/irma_icon_button.dart";

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
          ? IrmaIconButton(
              icon: Icons.delete,
              semanticsLabelKey: "debug.cert_management.remove_cert",
              onTap: onDelete!,
            )
          : null,
    );
  }
}
