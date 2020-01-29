import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_bloc.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_drawer.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class WalletScreen extends StatelessWidget {
  static const routeName = "/wallet";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'wallet.title')),
        // TODO: This icon should be sized 20, but the icon we have in IrmaIcons
        // doesn't match the VD icon. So as a temp fix I've increased the size
        // of this icon, but it should be replaced by a bolder icon in the
        // IrmaIcon set and put back to 20.
        leadingIcon: const Icon(IrmaIcons.menu, size: 32.0),
        leadingAction: () {
          _scaffoldKey.currentState.openDrawer();
        },
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

  void qrScannerPressed() {
    Navigator.pushNamed(context, ScannerScreen.routeName);
  }

  void helpPressed() {
    Navigator.pushNamed(context, HelpScreen.routeName);
  }

  void addCardsPressed() {
    Navigator.pushNamed(context, CardStoreScreen.routeName);
  }
}
