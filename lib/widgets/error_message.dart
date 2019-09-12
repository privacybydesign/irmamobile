import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class ErrorMessage extends StatelessWidget {
  final String message;

  ErrorMessage({
    @required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: 20),
        color: Colors.red,
        child: Text(FlutterI18n.translate(context, message),
            style: TextStyle(color: Colors.white, fontSize: 20)));
  }
}
