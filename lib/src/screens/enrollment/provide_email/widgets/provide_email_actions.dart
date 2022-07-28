import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_text_button.dart';
import 'skip_email_confirmation_dialog.dart';

class ProvideEmailActions extends StatelessWidget {
  final void Function() submitEmail;
  final void Function() skipEmail;
  final void Function() enterEmail;

  const ProvideEmailActions({
    required this.submitEmail,
    required this.skipEmail,
    required this.enterEmail,
  });

  Future<void> _showConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => SkipEmailConfirmationDialog(),
        ) ??
        false;
    confirmed ? skipEmail() : enterEmail();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Expanded(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(theme.defaultSpacing),
          color: theme.background,
          child: Row(
            children: [
              Expanded(
                child: IrmaTextButton(
                  key: const Key('enrollment_skip_email'),
                  label: 'ui.skip',
                  textStyle: theme.hyperlinkTextStyle,
                  onPressed: () => _showConfirmationDialog(context),
                  minWidth: 0.0,
                ),
              ),
              SizedBox(width: theme.defaultSpacing),
              Expanded(
                child: IrmaButton(
                  key: const Key('enrollment_email_next'),
                  label: 'ui.next',
                  onPressed: submitEmail,
                  minWidth: 0.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
