import "package:flutter/material.dart";

import "../../../../models/eudi_configuration.dart";

class CertManagerTile extends StatelessWidget {
  final Cert cert;
  final Function()? onTap;

  const CertManagerTile({required this.cert, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(cert.subject), onTap: onTap);
  }
}
