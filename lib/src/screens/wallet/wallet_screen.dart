import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/debug/debug_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_bloc.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_drawer.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class WalletScreen extends StatelessWidget {
  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    final WalletBloc bloc = WalletBloc();

    return BlocProvider<WalletBloc>.value(value: bloc, child: _WalletScreen(bloc: bloc));
  }
}

class _WalletScreen extends StatefulWidget {
  final WalletBloc bloc;

  const _WalletScreen({this.bloc}) : super();

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<_WalletScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void qrScannerPressed() {
    Navigator.pushNamed(context, ScannerScreen.routeName);
  }

  void helpPressed() {
    Navigator.pushNamed(context, HelpScreen.routeName);
  }

  void addCardsPressed() {
    Navigator.pushNamed(context, CardStoreScreen.routeName);
  }

  void onDebugPressed() {
    Navigator.pushNamed(context, DebugScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'wallet.title')),
        leadingIcon:
            Icon(IrmaIcons.menu, semanticLabel: FlutterI18n.translate(context, "accessibility.menu"), size: 20.0),
        leadingAction: () {
          _scaffoldKey.currentState.openDrawer();
        },
        actions: <Widget>[
          if (!kReleaseMode) ...[
            IconButton(
              icon: Icon(Icons.videogame_asset),
              onPressed: onDebugPressed,
            )
          ],
          IconButton(
            icon: Icon(
              IrmaIcons.lock,
              size: 20,
              semanticLabel: FlutterI18n.translate(context, "wallet.lock"),
            ),
            onPressed: () {
              PinBloc().dispatch(Lock());
              Navigator.of(context).pushNamed(PinScreen.routeName);
            },
          ),
        ],
      ),
      body: StreamBuilder<Credentials>(
        stream: widget.bloc.credentials,
        builder: (context, snapshot) => Wallet(
            credentials: snapshot.hasData ? snapshot.data.values.toList() : null,
            hasLoginLogoutAnimation: false,
            isOpen: true,
            onQRScannerPressed: qrScannerPressed,
            onHelpPressed: helpPressed,
            onAddCardsPressed: addCardsPressed),
      ),
      drawer: WalletDrawer(),
    );
  }
}
