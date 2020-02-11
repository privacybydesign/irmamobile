import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/screens/history/widgets/header.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';
import 'package:irmamobile/src/screens/history/widgets/subtitle.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class DetailScreen extends StatelessWidget {
  final String _lang = "nl";
  final LogEntry logEntry;

  const DetailScreen({this.logEntry});

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
        primaryButtonLabel: FlutterI18n.translate(context, "history.button_back"),
        onPrimaryPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Header(logEntry.serverName.translate(_lang), DateTime.now(), logEntry.type),
            SizedBox(
              height: IrmaTheme.of(context).largeSpacing,
            ),
            Padding(
              padding: EdgeInsets.only(left: IrmaTheme.of(context).defaultSpacing),
              child: Subtitle(logEntry.type),
            ),
            SizedBox(
              height: IrmaTheme.of(context).defaultSpacing,
            ),
            _buildDetailWidget(),
            SizedBox(
              height: IrmaTheme.of(context).defaultSpacing,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailWidget() {
    // TODO: Re-enable this
    switch (logEntry.type) {
      case LogEntryType.removal:
      // Removal not required for MVP
      case LogEntryType.disclosing:
        return const DisclosureCard(<List<VerifierCredential>>[]);
      case LogEntryType.issuing:
        return IssuingDetail(
          logEntry.issuedCredentials
              .map((rawCredential) => Credential.fromRaw(
                    irmaConfiguration: IrmaRepository.get().irmaConfigurationSubject.value,
                    rawCredential: rawCredential,
                  ))
              .toList(),
        );
      case LogEntryType.signing:
      // return SigningDetail(
      //   logEntry.signedMessage,
      //   const <List<VerifierCredential>>[],
      // );
    }
    return null;
  }
}
