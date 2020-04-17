import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/about/about_items.dart';
import 'package:irmamobile/src/screens/about/widgets/links.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../../sentry_dsn.dart';

class AboutScreen extends StatefulWidget {
  static const String routeName = '/about';
  static Key myKey = const Key(routeName);

  final CredentialType credentialType;

  AboutScreen({this.credentialType}) : super(key: myKey);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'about.title',
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(IrmaTheme.of(context).largeSpacing),
                              child: SizedBox(
                                  width: 98,
                                  child: SvgPicture.asset(
                                    'assets/non-free/irma_logo.svg',
                                    semanticsLabel: FlutterI18n.translate(context, 'accessibility.irma_logo'),
                                  )),
                            ),
                          ),
                          Text(
                            FlutterI18n.translate(context, 'about.header'),
                            style: Theme.of(context).textTheme.display2,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: IrmaTheme.of(context).smallSpacing),
                          Text(
                            FlutterI18n.translate(context, 'about.slogan'),
                            style: Theme.of(context).textTheme.body1,
                          ),
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                        ],
                      ),
                    ),
                    AboutItems(
                      credentialType: widget.credentialType,
                      parentKey: _scrollviewKey,
                      parentScrollController: _controller,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          Text(
                            FlutterI18n.translate(context, 'about.learn_more'),
                            style: Theme.of(context).textTheme.display2,
                          ),
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          const ExternalLink("about.irma_website_link", "about.more_information", Icon(IrmaIcons.info)),
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          const ContactLink(
                              "help.contact", "help.mail_subject", "about.contact", Icon(IrmaIcons.email)),
                          SizedBox(height: IrmaTheme.of(context).largeSpacing),
                          Text(
                            FlutterI18n.translate(context, 'about.get_involved'),
                            style: Theme.of(context).textTheme.display2,
                          ),
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          const ExternalLink("about.meetups_link", "about.meetups",
                              Icon(IrmaIcons.personal, size: 25.0)), // TODO replace icon with correct one
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          const ExternalLink("about.twitter_link", "about.twitter",
                              Icon(FontAwesomeIcons.twitter, size: 25.0)), // TODO fix icon and update this
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          const ExternalLink("about.github_link", "about.github",
                              Icon(FontAwesomeIcons.github, size: 25.0)), // TODO fix icon and update this
                          SizedBox(height: IrmaTheme.of(context).largeSpacing),
                          Text(
                            FlutterI18n.translate(context, 'about.share_slogan'),
                            style: Theme.of(context).textTheme.display2,
                          ),
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                          ShareLink(
                              FlutterI18n.translate(context, 'about.share_text'),
                              FlutterI18n.translate(context, 'about.share'),
                              Icon(FontAwesomeIcons.shareAlt, size: 25.0)), // TODO fix icon and update this
                          SizedBox(height: IrmaTheme.of(context).largeSpacing),
                          Text(
                            FlutterI18n.translate(context, 'about.version', translationParams: {
                              'version': version.substring(0, 8 < version.length ? 8 : version.length)
                            }),
                            style: Theme.of(context).textTheme.body1,
                          ),
                          SizedBox(height: IrmaTheme.of(context).tinySpacing),
                          Text(
                            FlutterI18n.translate(context, 'about.copyright'),
                            style: Theme.of(context).textTheme.body1,
                          ),
                          SizedBox(height: IrmaTheme.of(context).largeSpacing),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
