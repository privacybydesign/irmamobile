import 'dart:io';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_header.dart';

class CredentialCardIcon extends StatelessWidget {
  final CredentialHeaderType type;
  final String? logo;

  const CredentialCardIcon({
    this.logo,
    this.type = CredentialHeaderType.normal,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarRadius = 18;
    const double avatarSize = 24;

    return SizedBox(
      width: 40,
      child: Builder(
        builder: (context) {
          switch (type) {
            case CredentialHeaderType.normal:
              return CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  radius: avatarRadius,
                  child: logo != null && logo != ''
                      ? SizedBox(height: avatarSize, child: Image.file(File(logo!), excludeFromSemantics: true))
                      : Container());
            case CredentialHeaderType.error:
              return const CircleAvatar(
                backgroundColor: Colors.red,
                radius: avatarRadius,
                child: SizedBox(
                  height: avatarSize,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              );
            case CredentialHeaderType.success:
              return const CircleAvatar(
                backgroundColor: Colors.green,
                radius: avatarRadius,
                child: SizedBox(
                  height: avatarSize,
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                ),
              );
            case CredentialHeaderType.template:
              return CircleAvatar(
                backgroundColor: IrmaTheme.of(context).themeData.colorScheme.primary,
                radius: avatarRadius,
                child: const SizedBox(
                  height: avatarSize,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
