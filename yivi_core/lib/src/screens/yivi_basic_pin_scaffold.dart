import "package:material_ui/material_ui.dart";

import "../providers/irma_repository_provider.dart";
import "../util/navigation.dart";
import "../widgets/irma_app_bar.dart";
import "pin/yivi_pin_screen.dart";

class YiviBasicPinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback? cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final String instructionKey;

  /// A wrong PIN: what the line under the title says (the tries left).
  final String? error;

  YiviBasicPinScaffold({
    required this.submit,
    this.cancel,
    required this.instructionKey,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleString: "",
        leading: YiviBackButton(
          onTap: cancel != null
              ? () async {
                  cancel?.call();
                  if (!await Navigator.of(context).maybePop()) {
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  }
                }
              : null,
        ),
        hasBorder: false,
      ),
      body: StreamBuilder<bool>(
        stream: prefs.getLongPin(),
        builder: (context, snapshot) {
          final maxPinSize = (snapshot.data ?? false)
              ? longPinSize
              : shortPinSize;

          return YiviPinScreen(
            instructionKey: instructionKey,
            lockIcon: true,
            maxPinSize: maxPinSize,
            onSubmit: submit,
            onForgotPin: context.pushResetPinScreen,
            detail: error,
            detailKind: PinDetailKind.error,
            pinError: error != null,
            listener: (context, state) {
              if (maxPinSize == shortPinSize &&
                  state.pin.length == maxPinSize) {
                submit(state.toString());
              }
            },
          );
        },
      ),
    );
  }
}
