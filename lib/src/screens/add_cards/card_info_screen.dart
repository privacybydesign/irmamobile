import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/card_info.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/link_button.dart';
import 'package:irmamobile/src/widgets/primary_button.dart';

class CardInfoScreen extends StatefulWidget {
  CardInfoScreen(this.name, this.issuer, this.logoPath, this.onStartIssuance) : super(key: myKey);

  static const String routeName = '/card_info';
  static Key myKey = const Key(routeName);
  final String name;
  final String issuer;
  final String logoPath;
  final VoidCallback onStartIssuance;

  @override
  _CardInfoScreenState createState() => _CardInfoScreenState();
}

class _CardInfoScreenState extends State<CardInfoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _scrollviewKey = GlobalKey();
  ScrollController _controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'card_store.card_info.app_bar',
            {'card_type': widget.name},
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                controller: _controller,
                key: _scrollviewKey,
                child: CardInfo(
                  widget.name,
                  widget.issuer,
                  widget.logoPath,
                  _scrollviewKey,
                  _controller,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).spacing / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  LinkButton(
                      label: FlutterI18n.translate(context, 'card_store.card_info.back_button'),
                      onPressed: () {
                        print('Clicked');
                      }),
                  PrimaryButton(
                    label: FlutterI18n.translate(
                        context, 'card_store.card_info.get_button', {"card_type": this.widget.name.toLowerCase()}),
                    onPressed: this.widget.onStartIssuance,
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
