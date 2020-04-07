import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class CallInfoScreen extends StatelessWidget {
  const CallInfoScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          FlutterI18n.translate(context, 'Bellen'),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'Doorgaan',
        onPrimaryPressed: () {
          //
        },
      ),
      body: Column(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TranslatedText(
                          'Je postcode en woonplaats zijn doorgegegeven aan bellen.nijmegen.nl.',
                          style: Theme.of(context).textTheme.body1,
                        ),
                        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                        TranslatedText(
                          'Voer de volgende stappen uit om te bellen.',
                          style: Theme.of(context).textTheme.body1,
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
                                    backgroundColor: IrmaTheme.of(context).primaryLight),
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
                              TranslatedText(
                                'Kies doorgaan',
                                style: Theme.of(context).textTheme.body2,
                              ),
                              SizedBox(height: IrmaTheme.of(context).tinySpacing),
                              TranslatedText(
                                'Je belapplicatie opent nu vanzelf. Het telefoonnummer is al ingevuld, met een koppelcode. ',
                                style: Theme.of(context).textTheme.body1,
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
                                    backgroundColor: IrmaTheme.of(context).primaryLight),
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
                              TranslatedText(
                                'Klik de belknop in je belapplicatie',
                                style: Theme.of(context).textTheme.body2,
                              ),
                              SizedBox(height: IrmaTheme.of(context).tinySpacing),
                              TranslatedText(
                                'Je hoort en paar piepjes en wordt verbonden.',
                                style: Theme.of(context).textTheme.body1,
                              ),
                            ],
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
    );
  }
}
