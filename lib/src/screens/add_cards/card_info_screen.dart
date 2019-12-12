import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/card_info.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';

class CardInfoScreen extends StatefulWidget {
  static const String routeName = '/card_info';
  static Key myKey = const Key(routeName);

  CardInfoScreen({this.irmaConfiguration, this.credentialType, this.onStartIssuance}) : super(key: myKey);

  final IrmaConfiguration irmaConfiguration;
  final CredentialType credentialType;
  final VoidCallback onStartIssuance;

  @override
  _CardInfoScreenState createState() => _CardInfoScreenState();
}

class _CardInfoScreenState extends State<CardInfoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          FlutterI18n.translate(
            context,
            'card_store.card_info.app_bar',
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: _controller,
              key: _scrollviewKey,
              child: CardInfo(
                irmaConfiguration: widget.irmaConfiguration,
                credentialType: widget.credentialType,
                parentKey: _scrollviewKey,
                parentScrollController: _controller,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: IrmaTheme.of(context).backgroundBlue,
              border: Border(
                top: BorderSide(
                  color: IrmaTheme.of(context).primaryLight,
                  width: 2.0,
                ),
              ),
            ),
            // color: IrmaTheme.of(context).backgroundBlue,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).mediumSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: IrmaTextButton(
                        label: FlutterI18n.translate(context, 'card_store.card_info.back_button'),
                        textStyle: IrmaTheme.of(context).textButtonTextStyle,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
                      child: IrmaButton(
                        label: FlutterI18n.translate(context, 'card_store.card_info.get_button'),
                        textStyle: IrmaTheme.of(context).textTheme.button,
                        onPressed: widget.onStartIssuance,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
