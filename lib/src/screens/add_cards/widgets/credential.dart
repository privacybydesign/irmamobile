import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Credential extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subTitle;
  final bool obtained;
  final VoidCallback onTap;

  const Credential({
    @required this.icon,
    @required this.title,
    @required this.subTitle,
    @required this.obtained,
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 20.0,
              minWidth: 20.0,
              maxHeight: 40.0,
              maxWidth: 40.0,
            ),
            child: icon,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: IrmaTheme.of(context).textTheme.title.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subTitle,
                    style: IrmaTheme.of(context).textTheme.caption,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            child: obtained
                ? Icon(
                    IrmaIcons.synchronize,
                    color: Colors.black,
                  )
                : Icon(
                    IrmaIcons.add,
                    size: 24,
                    color: Colors.black,
                  ),
          ))
        ],
      ),
    );
  }
}
