import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class LoadingData extends StatelessWidget {
  const LoadingData({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xffe6e6e6),
        border: Border.all(color: Color(0xffbbbbbb)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              FlutterI18n.translate(context, "issuance.loading.title"),
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              FlutterI18n.translate(context, "issuance.loading.body"),
              style: Theme.of(context).textTheme.body1,
            ),
          ],
        ),
      ),
    );
  }
}
