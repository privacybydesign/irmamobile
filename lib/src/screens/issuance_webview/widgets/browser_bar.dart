import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma-icons.dart';

class BrowserBar extends StatelessWidget implements PreferredSizeWidget {
  final String url;
  final bool isLoading;
  final VoidCallback onOpenInBrowserPress;

  const BrowserBar({@required this.url, this.onOpenInBrowserPress, this.isLoading, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(IrmaIcons.arrowBack),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(IrmaIcons.lock),
                        ),
                        Flexible(
                          child: Text(
                            stripHostnameFromURL(),
                            style: Theme.of(context).textTheme.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.open_in_browser),
                    onPressed: onOpenInBrowserPress,
                  )
                ],
              ),
              isLoading
                  ? SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(),
                    )
                  : SizedBox(
                      height: 4,
                    )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(52);

  String stripHostnameFromURL() {
    try {
      var uri = Uri.parse(url);
      return uri.host;
    } catch (FormatException) {
      return "";
    }
  }
}
