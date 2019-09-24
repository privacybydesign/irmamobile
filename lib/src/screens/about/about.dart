import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatelessWidget {
  static const double paragraphSpace = 10.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(FlutterI18n.translate(context, 'about.title'))),
      // drawer: NavigationDrawer(),
      body: Container(
        padding: const EdgeInsets.all(32.0),
        color: Theme.of(context).canvasColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: SizedBox(
                  width: 180.0,
                  height: 150.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    child: SvgPicture.asset('assets/non-free/irma_logo.svg'),
                  ),
                ),
              ),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.header'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 2 * paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.what_is_irma'),
              ),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.privacy_benefits'),
              ),
              SizedBox(
                height: paragraphSpace,
              ),
              InkWell(
                  child: Text(
                    FlutterI18n.translate(context, 'about.privacy_policy_link'),
                    style: TextStyle(color: IrmaTheme.linkColor),
                  ),
                  onTap: () {
                    try {
                      launch(
                        FlutterI18n.translate(context, 'about.privacy_policy_link'),
                      );
                    } on PlatformException catch (e) {
                      print(e.toString());
                      print("error on launch of url - probably bad certificate?");
                    }
                  }),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.processing_agreement'),
              ),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.signatures_information'),
              ),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.problems'),
              ),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.more_information'),
              ),
              InkWell(
                  child: Text(
                    FlutterI18n.translate(context, 'about.pbdf_website_link'),
                    style: TextStyle(color: IrmaTheme.linkColor),
                  ),
                  onTap: () {
                    try {
                      launch(
                        FlutterI18n.translate(context, 'about.pbdf_website_link'),
                      );
                    } on PlatformException catch (e) {
                      print(e.toString());
                      print("error on launch of url - probably bad certificate?");
                    }
                  }),
              SizedBox(
                height: paragraphSpace,
              ),
              Text(
                FlutterI18n.translate(context, 'about.source_code'),
              ),
              InkWell(
                child: Text(
                  FlutterI18n.translate(context, 'about.source_code_link'),
                  style: TextStyle(color: IrmaTheme.linkColor),
                ),
                onTap: () {
                  try {
                    launch(
                      FlutterI18n.translate(context, 'about.source_code_link'),
                    );
                  } on PlatformException catch (e) {
                    print(e.toString());
                    print("error on launch of url - probably bad certificate?");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
