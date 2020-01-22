import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';

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
                    icon: Icon(
                      IrmaIcons.arrowBack,
                      semanticLabel: FlutterI18n.translate(context, "accessibility.back"),
                    ),
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
                    icon: Icon(
                      Icons.open_in_browser,
                      semanticLabel: FlutterI18n.translate(context, "webview.open_browser"),
                    ),
                    onPressed: onOpenInBrowserPress,
                  )
                ],
              ),
              if (isLoading) ...[
                const SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(),
                ),
              ] else ...[
                const SizedBox(
                  height: 4,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);

  String stripHostnameFromURL() {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (FormatException) {
      return "";
    }
  }
}
