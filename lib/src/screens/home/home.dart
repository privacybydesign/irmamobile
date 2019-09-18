import 'package:flutter/material.dart';
import 'package:irmamobile/src/mockdata/card.dart';
import 'package:irmamobile/src/widgets/card.dart';

class Home extends StatefulWidget {
  Home() : super();

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('IRMA Home'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          )),
      body: Center(child: 
        IrmaCard(mockCredentials["personalData"], mockIssuers["amsterdam"])
      ),
    );
  }
}
