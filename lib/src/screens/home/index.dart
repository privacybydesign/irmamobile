import 'package:flutter/material.dart';
import 'package:irmamobile/src/mockdata/issuers.dart';
import 'package:irmamobile/src/widgets/card.dart';

class IrmaHome extends StatefulWidget {
  IrmaHome() : super();

  @override
  _IrmaHomeState createState() => _IrmaHomeState();
}

class _IrmaHomeState extends State<IrmaHome> {
  static const Map<String, List<Map<String, String>>> personalData = {
    'data': [
      {'key': 'Naam', 'value': 'Anouk Meijer', 'hidden': 'true'},
      {'key': 'Geboren', 'value': '4 juli 1990', 'hidden': 'true'},
      {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com', 'hidden': 'false'},
    ],
    'metadata': [
      {'key': 'Geldig tot', 'value': '18 november 2019'}
    ]
  };

  IrmaCard irmaCard = IrmaCard(personalData, mockIssuers["amsterdam"]);

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
