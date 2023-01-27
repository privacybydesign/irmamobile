import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/session.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/issuer_verifier_header.dart';

class ActivityVerifierHeader extends StatelessWidget {
  final RequestorInfo requestorInfo;
  const ActivityVerifierHeader({
    required this.requestorInfo,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      child: IssuerVerifierHeader(
        title: requestorInfo.name.translate(
          FlutterI18n.currentLocale(context)!.languageCode,
        ),
        titleTextStyle: IrmaTheme.of(context).textTheme.headline5!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
