import 'package:flutter/material.dart';
import '../../widgets/card.dart';
import '../../data/issuers.dart';

class IrmaHome extends StatefulWidget {
  IrmaHome() : super();

  @override
  _IrmaHomeState createState() => _IrmaHomeState();
}

class _IrmaHomeState extends State<IrmaHome> {


  static const Map<String, List<Map<String, String>>> personalData = {
    'data': [
      {'key': 'Naam', 'value': 'Anouk Meijer'},
      {'key': 'Geboren', 'value': '4 juli 1990'},
      {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com'},
    ],
    'metadata': [{'key': 'Geldig tot', 'value': '18 november 2019'}]
  };

  IrmaCard irmaCard = IrmaCard(personalData, issuers["amsterdam"]);

  @override
  void initState() {
      irmaCard.unfoldStream.stream.listen((data) {
      print('unfoldStream $data');
    });
    irmaCard.updateStream.stream.listen((data) {
      print('updateStream');
    });
    irmaCard.removeStream.stream.listen((data) {
      print('removeStream');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('IRMA Home'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          )),
      body: Center(child: irmaCard),
    );
  }
}
