import 'package:flutter/material.dart';
import '../../widgets/card.dart';

class IrmaHome extends StatefulWidget {
  IrmaHome() : super();

  @override
  _IrmaHomeState createState() => _IrmaHomeState();
}

class _IrmaHomeState extends State<IrmaHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('IRMA Home'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          )),
      body: Center(child: IrmaCard()),
    );
  }
}
