import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class ErrorAlert extends StatelessWidget {
  final String title;
  final String body;

  const ErrorAlert({Key key, @required this.title, @required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: IrmaTheme.of(context).grayscale90,
        border: Border.all(color: Color(0xffbbbbbb)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.error,
              size: 24,
            ),
            SizedBox(
              width: 0.5 * IrmaTheme.of(context).spacing,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.title,
                  ),
                  SizedBox(
                    height: IrmaTheme.of(context).spacing,
                  ),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.body1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
