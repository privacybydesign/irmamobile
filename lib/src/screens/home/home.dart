import 'package:flutter/material.dart';
import 'package:irmamobile/src/mockdata/card.dart';
import 'package:irmamobile/src/widgets/card.dart';

import './widgets/home_drawer.dart';

class Home extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      body: Center(child: IrmaCard(mockCredentials["personalData"], mockIssuers["amsterdam"])),
      drawer: HomeDrawer(),
    );
  }
}
