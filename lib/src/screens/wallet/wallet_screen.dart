import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_bloc.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_drawer.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_bloc.dart';
import 'package:irmamobile/src/widgets/card.dart';

class WalletScreen extends StatelessWidget {
  static final routeName = "/";

  Widget build(BuildContext context) {
    IrmaClientBloc irmaClientBloc = BlocProvider.of<IrmaClientBloc>(context);
    WalletBloc bloc = WalletBloc(irmaClientBloc: irmaClientBloc);

    return BlocProvider<WalletBloc>.value(value: bloc, child: _WalletScreen(bloc: bloc));
  }
}

class _WalletScreen extends StatefulWidget {
  final WalletBloc bloc;

  _WalletScreen({this.bloc}) : super();

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
          title: Text('IRMA Wallet'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState.openDrawer(),
          )),
      body: StreamBuilder(
          stream: widget.bloc.credentials,
          builder: (context, AsyncSnapshot<List<RichCredential>> snapshot) {
            if (snapshot.hasData) {
              return ListView(
                  children: snapshot.data
                      .map((credential) => IrmaCard(credential: credential, onRefresh: () => {}, onRemove: () => {}))
                      .toList());
            } else
              return Center(child: Text('Loading...'));
          }),
      drawer: WalletDrawer(),
    );
  }
}
