import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class SuccessAlert extends StatelessWidget {
  final String title;
  final String body;

  const SuccessAlert({Key key, @required this.title, @required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: IrmaTheme.of(context).interactionValid,
        border: Border.all(color: const Color(0xffbbbbbb)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              IrmaIcons.valid,
              size: 24,
              color: Colors.white,
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
                    style: Theme.of(context).textTheme.title.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(
                    height: 0.5 * IrmaTheme.of(context).spacing,
                  ),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.body1.copyWith(
                          color: Colors.white,
                        ),
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
