import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class BrowserBar extends StatefulWidget implements PreferredSizeWidget {
  final String url;
  final bool isLoading;
  final VoidCallback onOpenInBrowserPress;

  const BrowserBar({@required this.url, this.onOpenInBrowserPress, this.isLoading, Key key}) : super(key: key);

  @override
  _BrowserBarState createState() => _BrowserBarState();

  @override
  Size get preferredSize {
    return new Size.fromHeight(kToolbarHeight);
  }
}

class _BrowserBarState extends State<BrowserBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: IrmaTheme.of(context).backgroundBlue,
        child: Stack(
          children: <Widget>[
            Center(
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(IrmaIcons.close, size: 14.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(FontAwesomeIcons.lock, color: IrmaTheme.of(context).grayscale40, size: 12.0),
                        ), // Todo replace with IrmaIcon
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            stripHostnameFromURL(),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis, // Todo these ellipses are not working!
                            style: IrmaTheme.of(context).textTheme.title.copyWith(
                                  fontSize: 16.0,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    // Todo replace icon in iconfont to a horizontalNav and remove this rotate
                    angle: 90 * math.pi / 180,
                    child: IconButton(
                        icon: Icon(IrmaIcons.verticalNav, size: 16.0),
                        onPressed: () {
                          if (Platform.isAndroid) {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext _) {
                                return Container(
                                  child: Wrap(
                                    children: <Widget>[
                                      ListTile(
                                        leading: Icon(Icons.exit_to_app),
                                        title: Text(FlutterI18n.translate(context, 'webview.open_browser')),
                                        onTap: widget.onOpenInBrowserPress,
                                      ),
                                      Divider(),
                                      if (true)
                                        ListTile(
                                          title: Text(FlutterI18n.translate(context, 'webview.cancel')),
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                              isScrollControlled: true,
                            );
                          } else if (Platform.isIOS) {
                            final act = CupertinoActionSheet(
                                title: Text(FlutterI18n.translate(context, 'webview.select')),
                                actions: <Widget>[
                                  CupertinoActionSheetAction(
                                    child: Text(FlutterI18n.translate(context, 'webview.open_iOS')),
                                    onPressed: widget.onOpenInBrowserPress,
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  child: Text(FlutterI18n.translate(context, 'webview.cancel')),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ));
                            showCupertinoModalPopup(context: context, builder: (BuildContext context) => act);
                          }
                        }),
                  ),
                ],
              ),
            ),
            if (widget.isLoading) ...[
              Column(
                children: <Widget>[
                  Container(
                    height: kToolbarHeight - 4,
                  ),
                  const SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  String stripHostnameFromURL() {
    try {
      final uri = Uri.parse(widget.url);
      return uri.host;
    } catch (FormatException) {
      return "";
    }
  }
}
