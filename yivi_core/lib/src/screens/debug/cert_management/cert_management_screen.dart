import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";

import "../../../models/certificate_events.dart";
import "../../../models/error_event.dart";
import "../../../models/eudi_configuration.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/progress.dart";
import "../../../widgets/translated_text.dart";
import "../../error/error_screen.dart";
import "../cert_management/widgets/cert_manager_tile.dart";
import "../cert_management/widgets/provide_cert_dialog.dart";
import "../util/await_action_result.dart";

class CertificateManagementScreen extends StatefulWidget {
  @override
  State<CertificateManagementScreen> createState() =>
      _CertificateManagementScreenState();
}

class _CertificateManagementScreenState
    extends State<CertificateManagementScreen> {
  Future<void> _onErrorEvent(ErrorEvent event) async {
    final navigator = Navigator.of(context);
    // ErrorEvents are automatically reported by the IrmaRepository if error reporting is enabled.
    final errorReported = await IrmaRepositoryProvider.of(
      context,
    ).preferences.getReportErrors().first;

    if (!mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (context) => ErrorScreen.fromEvent(
          error: event,
          onTapClose: () => navigator.pop(),
          reportable: !errorReported,
        ),
      ),
    );
  }

  Future<void> _onInstallCertificate() async {
    final repo = IrmaRepositoryProvider.of(context);

    final newCert = await showDialog<NewCertificate>(
      context: context,
      builder: (context) => const ProvideCertDialog(),
    );

    if (newCert == null || newCert.pemContent.isEmpty || newCert.type.isEmpty) {
      return;
    }

    // Start listening for the result before dispatching, scoped to this action
    // so unrelated background errors are not mistaken for an install failure.
    // On success the handler re-dispatches the (EUDI) configuration, which also
    // refreshes the certificate list below.
    final resultFuture = awaitActionResult<EudiConfigurationEvent>(
      repo,
      timeout: const Duration(seconds: 5),
    );
    repo.bridgedDispatch(
      InstallCertificateEvent(
        type: newCert.type,
        pemContent: newCert.pemContent,
      ),
    );

    ErrorEvent? error;
    try {
      error = await resultFuture;
    } on TimeoutException {
      // Installing the certificate took too long. We assume that it failed.
      return;
    }

    if (mounted && error != null) {
      await _onErrorEvent(error);
    }
  }

  void _onCertificateTileTap(String thumbprint) =>
      log("Tapped certificate with thumbprint $thumbprint");
  //Navigator.of(context).push(MaterialPageRoute(builder: (context) => CertManagerDetailScreen(trustAnchorId)));

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: "debug.cert_management.title",
        actions: [
          IrmaIconButton(icon: Icons.add, onTap: () => _onInstallCertificate()),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<EudiConfiguration>(
          stream: repo.getEudiConfiguration(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: IrmaProgress());
            }
            final configuration = snapshot.data!;

            return ListView(
              padding: EdgeInsets.all(theme.defaultSpacing),
              children: [
                const TranslatedText("debug.cert_management.issuer_certs"),
                if (configuration.issuerCertificates != null)
                  for (final cert in configuration.issuerCertificates!)
                    CertManagerTile(
                      cert: cert,
                      onTap: () => _onCertificateTileTap(cert.thumbprint),
                    ),
                SizedBox(height: theme.defaultSpacing),
                const TranslatedText("debug.cert_management.verifier_certs"),
                if (configuration.verifierCertificates != null)
                  for (final cert in configuration.verifierCertificates!)
                    CertManagerTile(
                      cert: cert,
                      onTap: () => _onCertificateTileTap(cert.thumbprint),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
