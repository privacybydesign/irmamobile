// This code is not null safe yet.
// @dart=2.11

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class CallInfoScreen extends StatelessWidget {
  final String otherParty;
  final Function() onContinue;
  final Function() onCancel;
  const CallInfoScreen({@required this.otherParty, this.onContinue, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onCancel();
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(context, 'disclosure.call_info.title'),
          ),
          leadingAction: () => onCancel(),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'disclosure.call_info.continue_button'),
          onPrimaryPressed: () => onContinue(),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
                child: Platform.isIOS ? _buildiOSInstructions(context) : _buildAndroidInstructions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildAndroidInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        IrmaMessage(
          'disclosure.call_info.success',
          'disclosure.call_info.success_message',
          type: IrmaMessageType.info,
          descriptionParams: {"otherParty": otherParty},
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        Text(
          FlutterI18n.translate(context, 'disclosure.call_info.continue'),
          style: Theme.of(context).textTheme.body2,
        ),
        SizedBox(height: IrmaTheme.of(context).tinySpacing),
        TranslatedText(
          'disclosure.call_info.continue_message',
          style: Theme.of(context).textTheme.body1,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        Center(
          child: SizedBox(
            height: 50.0,
            child: SvgPicture.asset(
              'assets/non-free/noun_number_pad_374833.svg',
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        Text(
          FlutterI18n.translate(context, 'disclosure.call_info.call'),
          style: Theme.of(context).textTheme.body2,
        ),
        SizedBox(height: IrmaTheme.of(context).tinySpacing),
        TranslatedText(
          'disclosure.call_info.call_message',
          style: Theme.of(context).textTheme.body1,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        Center(
          child: SizedBox(
            height: 50.0,
            child: SvgPicture.asset(
              'assets/non-free/noun_call_906214.svg',
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
      ],
    );
  }

  Column _buildiOSInstructions(BuildContext context) {
    {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
          IrmaMessage(
            'disclosure.call_info.success',
            'disclosure.call_info.success_message_ios',
            type: IrmaMessageType.info,
            descriptionParams: {"otherParty": otherParty},
          ),
          SizedBox(height: IrmaTheme.of(context).largeSpacing),
          Text(
            FlutterI18n.translate(context, 'disclosure.call_info.continue_ios'),
            style: Theme.of(context).textTheme.body2,
          ),
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TranslatedText(
                  'disclosure.call_info.continue_message_ios',
                  style: Theme.of(context).textTheme.body1,
                ),
              ),
            ],
          ),
          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Center(
                  child: SizedBox(
                    height: 70.0,
                    child: SvgPicture.asset(
                      'assets/non-free/noun_number_pad_374833.svg',
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
