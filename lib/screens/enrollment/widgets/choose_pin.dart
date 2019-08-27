import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/widgets/PinField.dart';

import 'confirm_pin.dart';

class ChoosePin extends StatefulWidget {
  @override
  _ChoosePinState createState() => _ChoosePinState();
}

class _ChoosePinState extends State<ChoosePin> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
                FlutterI18n.translate(context, 'enrollment.choose_pin.title')),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, false),
            )),
        body: Form(
            key: _formKey,
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  Text(
                    FlutterI18n.translate(
                        context, 'enrollment.choose_pin.instruction'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PinField(onSubmit: (String pin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ConfirmPin()),
                    );
                  }),
                  const SizedBox(height: 20),
                  RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConfirmPin()),
                      );
                    },
                    child: Text(
                        FlutterI18n.translate(
                            context, 'enrollment.choose_pin.next'),
                        style: TextStyle(fontSize: 20)),
                  ),
                ]))));
  }
}
