import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/error/custom_error.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

enum CustomErrorType {
  expired,
  pairingRejected,
}

class CustomErrorScreen extends StatelessWidget {
  static const _translationKeys = {
    CustomErrorType.expired: "error.types.expired",
    CustomErrorType.pairingRejected: "error.types.pairing_rejected",
  };

  final VoidCallback onTapClose;
  final CustomErrorType errorType;

  const CustomErrorScreen({@required this.onTapClose, @required this.errorType});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onTapClose();
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(
              context,
              'error.title',
            ),
          ),
          leadingAction: onTapClose,
        ),
        body: CustomError(
          errorText: TranslatedText(
            _translationKeys[errorType],
            style: IrmaTheme.of(context).textTheme.bodyText2,
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'error.button_back'),
          onPrimaryPressed: onTapClose,
        ),
      ),
    );
  }
}
