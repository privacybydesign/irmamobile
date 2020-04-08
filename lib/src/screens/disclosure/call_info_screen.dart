import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class CallInfoScreen extends StatelessWidget {
  const CallInfoScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          FlutterI18n.translate(context, 'Bellen'),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'disclosure.call_info.continue_button'),
        onPrimaryPressed: () {
          //
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: IrmaTheme.of(context).smallSpacing,
                                  top: IrmaTheme.of(context).tinySpacing * 0.75,
                                  right: IrmaTheme.of(context).defaultSpacing),
                              child: Container(
                                child: CircleAvatar(
                                    child: Icon(IrmaIcons.valid),
                                    foregroundColor: IrmaTheme.of(context).primaryDark,
                                    backgroundColor: IrmaTheme.of(context).grayscaleWhite),
                                width: 26.0,
                                height: 26.0,
                                padding: const EdgeInsets.all(1.5), // borde width
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  FlutterI18n.translate(context, 'disclosure.call_info.success'),
                                  style: Theme.of(context).textTheme.body2,
                                ),
                                SizedBox(height: IrmaTheme.of(context).tinySpacing),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: TranslatedText(
                                        'disclosure.call_info.success_message_markdown',
                                        style: Theme.of(context).textTheme.body1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: IrmaTheme.of(context).smallSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: IrmaTheme.of(context).smallSpacing,
                                  top: IrmaTheme.of(context).tinySpacing * 0.75,
                                  right: IrmaTheme.of(context).defaultSpacing),
                              child: Container(
                                  child: CircleAvatar(
                                      child: const Text('1'),
                                      foregroundColor: IrmaTheme.of(context).primaryDark,
                                      backgroundColor: IrmaTheme.of(context).grayscaleWhite),
                                  width: 26.0,
                                  height: 26.0,
                                  padding: const EdgeInsets.all(1.5), // borde width
                                  decoration: new BoxDecoration(
                                    color: const Color(0xFF000000), // border color
                                    shape: BoxShape.circle,
                                  )),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  FlutterI18n.translate(context, 'disclosure.call_info.continue'),
                                  style: Theme.of(context).textTheme.body2,
                                ),
                                SizedBox(height: IrmaTheme.of(context).tinySpacing),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: TranslatedText(
                                        'disclosure.call_info.continue_message_1',
                                        style: Theme.of(context).textTheme.body1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: IrmaTheme.of(context).tinySpacing),
                      Center(
                        child: SizedBox(
                          height: 50.0,
                          child: SvgPicture.asset(
                            'assets/non-free/noun_number_pad_374833.svg',
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                      ),
                      SizedBox(height: IrmaTheme.of(context).tinySpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: IrmaTheme.of(context).smallSpacing,
                                  top: IrmaTheme.of(context).tinySpacing * 0.75,
                                  right: IrmaTheme.of(context).defaultSpacing),
                              child: Container(
                                width: 26.0,
                                height: 26.0,
                                padding: const EdgeInsets.all(1.5), // borde width
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: TranslatedText(
                                        'disclosure.call_info.continue_message_2',
                                        style: Theme.of(context).textTheme.body1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: IrmaTheme.of(context).smallSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: IrmaTheme.of(context).smallSpacing,
                                  top: IrmaTheme.of(context).tinySpacing * 0.75,
                                  right: IrmaTheme.of(context).defaultSpacing),
                              child: Container(
                                  child: CircleAvatar(
                                      child: const Text('2'),
                                      foregroundColor: IrmaTheme.of(context).primaryDark,
                                      backgroundColor: IrmaTheme.of(context).grayscaleWhite),
                                  width: 26.0,
                                  height: 26.0,
                                  padding: const EdgeInsets.all(1.5), // borde width
                                  decoration: new BoxDecoration(
                                    color: const Color(0xFF000000), // border color
                                    shape: BoxShape.circle,
                                  )),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  FlutterI18n.translate(context, 'disclosure.call_info.call'),
                                  style: Theme.of(context).textTheme.body2,
                                ),
                                SizedBox(height: IrmaTheme.of(context).tinySpacing),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: TranslatedText(
                                        'disclosure.call_info.call_message',
                                        style: Theme.of(context).textTheme.body1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: IrmaTheme.of(context).tinySpacing),
                      Center(
                        child: SizedBox(
                          height: 50.0,
                          child: SvgPicture.asset(
                            'assets/non-free/noun_call_906214.svg',
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                      ),
                      SizedBox(height: IrmaTheme.of(context).tinySpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: IrmaTheme.of(context).smallSpacing,
                                  top: IrmaTheme.of(context).tinySpacing * 0.75,
                                  right: IrmaTheme.of(context).defaultSpacing),
                              child: Container(
                                width: 26.0,
                                height: 26.0,
                                padding: const EdgeInsets.all(1.5), // borde width
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: IrmaTheme.of(context).largeSpacing),
                    ],
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
