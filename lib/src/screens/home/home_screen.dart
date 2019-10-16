import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/screens/home/models/home_bloc.dart';
import 'package:irmamobile/src/screens/home/widgets/home_drawer.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_bloc.dart';
import 'package:irmamobile/src/widgets/card.dart';

class HomeScreen extends StatelessWidget {
  static final routeName = "/";

  Widget build(BuildContext context) {
    IrmaClientBloc irmaClientBloc = BlocProvider.of<IrmaClientBloc>(context);
    HomeBloc bloc = HomeBloc(irmaClientBloc: irmaClientBloc);

    return BlocProvider<HomeBloc>.value(value: bloc, child: ProvidedHomeScreen(bloc: bloc));
  }
}

class ProvidedHomeScreen extends StatelessWidget {
  static final routeName = "/";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final HomeBloc bloc;

  ProvidedHomeScreen({this.bloc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          title: Text('IRMA Home'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState.openDrawer(),
          )),
      body: StreamBuilder(
          stream: bloc.credentials,
          builder: (context, AsyncSnapshot<List<RichCredential>> snapshot) {
            if (snapshot.hasData) {
              return ListView(children: snapshot.data.map((credential) => IrmaCard(credential: credential)).toList());
            } else
              return Center(child: Text('Loading...'));
          }),
      drawer: HomeDrawer(),
    );
  }
}
