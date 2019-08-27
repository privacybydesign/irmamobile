import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/widgets/PinField.dart';

class ConfirmPin extends StatefulWidget {
  @override
  _ConfirmPinState createState() => _ConfirmPinState();
}

class _ConfirmPinState extends State<ConfirmPin> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: true,
            title: Text(FlutterI18n.translate(
                context, 'enrollment.choose_pin.confirm_title')),
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
                        context, 'enrollment.choose_pin.confirm_instruction'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PinField(),
                  const SizedBox(height: 20),
                  RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () {},
                    child: Text(
                        FlutterI18n.translate(
                            context, 'enrollment.choose_pin.next'),
                        style: TextStyle(fontSize: 20)),
                  ),
                ]))));
  }
}
