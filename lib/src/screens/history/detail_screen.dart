import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_client_mock.dart';
import 'package:irmamobile/src/models/log.dart' as log_model;
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/screens/history/widgets/header.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';
import 'package:irmamobile/src/screens/history/widgets/log.dart';
import 'package:irmamobile/src/screens/history/widgets/signing_detail.dart';
import 'package:irmamobile/src/screens/history/widgets/subtitle.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class DetailScreen extends StatelessWidget {
  final log_model.Log log;
  final LogType logType;

  const DetailScreen(this.log, this.logType);

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
            Header(log.serverName, DateTime.now(), logType),
            SizedBox(
              height: IrmaTheme.of(context).largeSpacing,
            ),
            Padding(
              padding: EdgeInsets.only(left: IrmaTheme.of(context).defaultSpacing),
              child: Subtitle(logType),
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
    switch (logType) {
      case LogType.removal:
      // Removal not required for MVP
      case LogType.disclosing:
        // Because it is unknown how the data eventually will look like.
        // Data of the mock is manipulated to make it useable in the DisclosureCard
        // TODO: get the data from the IrmaClient as soon as the correct datamodel is implemented
        final attributes = IrmaClientMock().getVerify();
        return DisclosureCard(
          <List<VerifierCredential>>[
            attributes[0],
            <VerifierCredential>[attributes[1][0]],
          ],
        );
      case LogType.issuing:
        return IssuingDetail(log.issuedCredentials.values.toList());
      case LogType.signing:
        // TODO: get the data from the IrmaClient as soon as the correct datamodel is implemented
        final attributes = IrmaClientMock().getVerify();
        return SigningDetail(
          log.signedMessage,
          <List<VerifierCredential>>[
            attributes[0],
          ],
        );
    }
    return null;
  }
}
