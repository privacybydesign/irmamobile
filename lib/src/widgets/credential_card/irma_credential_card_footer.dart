import 'package:flutter/widgets.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../irma_button.dart';
import '../irma_repository_provider.dart';

class IrmaCredentialCardFooter extends StatelessWidget {
  final String? text;
  final bool isObtainable;
  final CredentialType credentialType;

  const IrmaCredentialCardFooter({
    required this.credentialType,
    this.text,
    this.isObtainable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text != null)
          Text(
            text!,
            style: theme.textTheme.bodyText2!.copyWith(color: theme.dark),
          ),
        if (isObtainable)
          Padding(
            padding: EdgeInsets.only(top: theme.smallSpacing),
            child: IrmaButton(
              label: 'credential.options.reobtain',
              onPressed: () => IrmaRepositoryProvider.of(context).openIssueURL(
                context,
                credentialType.fullId,
              ),
              minWidth: double.infinity,
            ),
          )
      ],
    );
  }
}
