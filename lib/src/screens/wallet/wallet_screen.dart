import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_bloc.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_drawer.dart';

class WalletScreen extends StatelessWidget {
  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    final bloc = WalletBloc();

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
      appBar: AppBar(
        title: const Text('IRMA Wallet'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState.openDrawer(),
        ),
      ),
      body: StreamBuilder<Credentials>(
        stream: widget.bloc.credentials,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Wallet(credentials: snapshot.data.values.toList(), qrCallback: qrActivate);
          } else {
            return Center(child: const Text('Loading...'));
          }
        },
      ),
      drawer: WalletDrawer(),
    );
  }

  void qrActivate() {
    debugPrint("QR button pressed.");
  }
}
