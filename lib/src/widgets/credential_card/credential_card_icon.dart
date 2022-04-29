import 'dart:io';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

class CredentialCardIcon extends StatelessWidget {
  final IrmaCardStyle style;
  final String? logo;

  const CredentialCardIcon({
    this.logo,
    this.style = IrmaCardStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarRadius = 18;
    const double avatarSize = 24;

    return SizedBox(
      width: 40,
      child: Builder(
        builder: (context) {
          switch (style) {
            case IrmaCardStyle.error:
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
            case IrmaCardStyle.success:
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
            case IrmaCardStyle.template:
              return CircleAvatar(
                backgroundColor: IrmaTheme.of(context).themeData.colorScheme.secondary,
                radius: avatarRadius,
                child: const SizedBox(
                  height: avatarSize,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              );
            case IrmaCardStyle.normal:
            default:
              return CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  radius: avatarRadius,
                  child: logo != null && logo != ''
                      ? SizedBox(height: avatarSize, child: Image.file(File(logo!), excludeFromSemantics: true))
                      : Container());
          }
        },
      ),
    );
  }
}
