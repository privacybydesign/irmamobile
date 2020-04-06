import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/screens/history/widgets/header.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';
import 'package:irmamobile/src/screens/history/widgets/removal_detail.dart';
import 'package:irmamobile/src/screens/history/widgets/subtitle.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';

class DetailScreen extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const DetailScreen({this.logEntry, this.irmaConfiguration});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          FlutterI18n.translate(context, 'history.title'),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'history.button_back',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Header(logEntry),
            SizedBox(
              height: IrmaTheme.of(context).largeSpacing,
            ),
            ..._buildDetailWidgets(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailWidgets(BuildContext context) {
    final widgets = <Widget>[];

    if (logEntry.type == LogEntryType.signing) {
      widgets.addAll(_detailWidgetLayout(
        context,
        LogEntryType.signing,
        IrmaQuote(
          quote: logEntry.signedMessage.message,
        ),
      ));
    }

    if (logEntry.type == LogEntryType.issuing) {
      widgets.addAll(_detailWidgetLayout(
        context,
        LogEntryType.issuing,
        IssuingDetail(
          logEntry.issuedCredentials
              .map((rawCredential) => Credential.fromRaw(
                    irmaConfiguration: IrmaRepository.get().irmaConfigurationSubject.value,
                    rawCredential: rawCredential,
                  ))
              .toList(),
        ),
      ));
    }

    if (logEntry.type == LogEntryType.removal) {
      widgets.addAll(_detailWidgetLayout(
        context,
        LogEntryType.removal,
        RemovalDetail(logEntry.removedCredentials.entries
            .map<RemovedCredential>((entry) => RemovedCredential.fromRaw(
                  irmaConfiguration: IrmaRepository.get().irmaConfigurationSubject.value,
                  credentialIdentifier: entry.key,
                  rawAttributes: entry.value,
                ))
            .toList()),
      ));
    }

    if (logEntry.disclosedAttributes.isNotEmpty) {
      widgets.addAll(_detailWidgetLayout(
        context,
        LogEntryType.disclosing,
        DisclosureCard(
            candidatesConDisCon: ConDisCon.fromConCon<Attribute>(
                ConCon.fromRaw<DisclosedAttribute, Attribute>(logEntry.disclosedAttributes, (disclosedAttribute) {
          return Attribute.fromDisclosedAttribute(irmaConfiguration, disclosedAttribute);
        }))),
      ));
    }

    return widgets;
  }

  List<Widget> _detailWidgetLayout(BuildContext context, LogEntryType widgetType, Widget detailWidget) {
    return <Widget>[
      Padding(
        padding: EdgeInsets.only(left: IrmaTheme.of(context).defaultSpacing),
        child: Subtitle(widgetType),
      ),
      Padding(
        padding: EdgeInsets.symmetric(
          vertical: IrmaTheme.of(context).defaultSpacing,
          horizontal: IrmaTheme.of(context).smallSpacing,
        ),
        child: detailWidget,
      ),
    ];
  }
}
