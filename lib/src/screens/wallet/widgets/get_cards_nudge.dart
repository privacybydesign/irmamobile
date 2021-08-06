import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class GetCardsNudge extends StatelessWidget {
  final Size size;
  final void Function() onAddCardsPressed;
  final List<Credential> credentials;
  final bool showButton;

  const GetCardsNudge({
    this.credentials,
    this.size,
    this.onAddCardsPressed,
    this.showButton = true,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: IrmaTheme.of(context).smallSpacing,
          ),
          SvgPicture.asset(
            'assets/wallet/wallet_illustration.svg',
            excludeFromSemantics: true,
            width: size.width / 2,
          ),
          Padding(
            padding: EdgeInsets.all(
              IrmaTheme.of(context).smallSpacing,
            ),
            child: Text(
              FlutterI18n.translate(context, 'wallet.caption'),
              textAlign: TextAlign.center,
              style: IrmaTheme.of(context).textTheme.body1,
            ),
          ),
          if (showButton) ...[
            SizedBox(
              height: IrmaTheme.of(context).defaultSpacing,
            ),
            IrmaOutlinedButton(
              label: 'wallet.add_data',
              onPressed: onAddCardsPressed,
            ),
          ],
          if (credentials == null) ...[
            Align(
              alignment: Alignment.center,
              child: LoadingIndicator(),
            )
          ],
        ],
      ),
    );
  }
}
