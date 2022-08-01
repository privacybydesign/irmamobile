import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../widgets/irma_repository_provider.dart';
import 'pin/yivi_pin_screen.dart';

class YiviBasicPinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback? cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final String titleTranslationKey;
  final String instructionKey;

  YiviBasicPinScaffold(
      {required this.submit, this.cancel, required this.titleTranslationKey, required this.instructionKey});

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: titleTranslationKey,
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        leadingAction: cancel != null
            ? () async {
                cancel?.call();
                if (!await Navigator.of(context).maybePop()) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              }
            : null,
      ),
      body: StreamBuilder<bool>(
        stream: prefs.getLongPin(),
        builder: (context, snapshot) {
          final maxPinSize = (snapshot.data ?? false) ? longPinSize : shortPinSize;
          final pinBloc = EnterPinStateBloc(maxPinSize);

          return YiviPinScreen(
            instructionKey: instructionKey,
            maxPinSize: maxPinSize,
            onSubmit: submit,
            pinBloc: pinBloc,
            listener: (context, state) {
              if (maxPinSize == shortPinSize && state.pin.length == maxPinSize) {
                submit(state.toString());
              }
            },
            hideSubmit: shortPinSize == maxPinSize,
          );
        },
      ),
    );
  }
}
