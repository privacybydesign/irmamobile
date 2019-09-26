import 'package:flutter/material.dart';

class BrowserBar extends StatelessWidget implements PreferredSizeWidget {
  final String url;
  final VoidCallback onOpenInBrowserPress;

  const BrowserBar({@required this.url, this.onOpenInBrowserPress, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.lock),
                ),
                Text(
                  stripHostnameFromURL(),
                  style: Theme.of(context).textTheme.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.open_in_browser),
              onPressed: onOpenInBrowserPress,
            )
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(48);

  String stripHostnameFromURL() {
    try {
      var uri = Uri.parse(url);
      return uri.host;
    } catch (FormatException) {
      return "";
    }
  }
}
