import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/yivi_themed_button.dart";

class ProvideTransactionCodeDialog extends StatefulWidget {
  const ProvideTransactionCodeDialog({
    super.key,
    required this.transactionCodeParameters,
  });

  final PreAuthorizationCodeTransactionCodeParametersState
  transactionCodeParameters;

  @override
  State<ProvideTransactionCodeDialog> createState() =>
      _ProvideTransactionCodeDialogState();
}

class _ProvideTransactionCodeDialogState
    extends State<ProvideTransactionCodeDialog> {
  final controller = TextEditingController();
  bool isAddButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    isAddButtonEnabled = widget.transactionCodeParameters.length == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final navigator = Navigator.of(context);

    var widget = context.widget as ProvideTransactionCodeDialog;

    return IrmaDialog(
      title: FlutterI18n.translate(
        context,
        "issuance.pre-authorized_code.transactioncode_dialog.title",
      ),
      content: widget.transactionCodeParameters.description ?? "",
      child: Wrap(
        runSpacing: theme.defaultSpacing,
        alignment: WrapAlignment.center,
        children: [
          // TODO: create a prettier input field for transaction codes
          TextField(
            controller: controller,
            autocorrect: false,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType:
                widget.transactionCodeParameters.inputMode == "numeric"
                ? TextInputType.number
                : TextInputType.text,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            maxLength: widget.transactionCodeParameters.length,
            onChanged: (value) => {
              setState(() {
                isAddButtonEnabled =
                    widget.transactionCodeParameters.length == null ||
                    controller.text.length ==
                        widget.transactionCodeParameters.length!;
              }),
            },
            onSubmitted: (transactionCode) => navigator.pop(transactionCode),
          ),
          YiviThemedButton(
            label: "ui.add",
            onPressed: isAddButtonEnabled
                ? () => navigator.pop(controller.text)
                : null,
          ),
        ],
      ),
    );
  }
}
