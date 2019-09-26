import 'package:flutter/material.dart';

class Credential extends StatelessWidget {
  final Icon icon;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          icon,
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.title.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subTitle,
                    style: Theme.of(context).textTheme.caption,
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
                    Icons.refresh,
                    color: Colors.black,
                  )
                : Icon(
                    Icons.add,
                    size: 32,
                    color: Colors.black,
                  ),
          ))
        ],
      ),
      onTap: onTap,
    );
  }
}
