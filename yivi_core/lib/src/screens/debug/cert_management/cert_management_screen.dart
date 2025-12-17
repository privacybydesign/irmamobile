import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:rxdart/rxdart.dart";

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

class CertificateManagementScreen extends StatefulWidget {
  @override
  State<CertificateManagementScreen> createState() => _CertificateManagementScreenState();
}

class _CertificateManagementScreenState extends State<CertificateManagementScreen> {
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = IrmaRepositoryProvider.of(context);
      _errorSubscription = repo.getEvents().whereType<ErrorEvent>().listen(_onErrorEvent);
    });
  }

  Future<void> _onErrorEvent(ErrorEvent event) async {
    final navigator = Navigator.of(context);
    // ErrorEvents are automatically reported by the IrmaRepository if error reporting is enabled.
    final errorReported = await IrmaRepositoryProvider.of(context).preferences.getReportErrors().first;

    if (!mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (context) =>
            ErrorScreen.fromEvent(error: event, onTapClose: () => navigator.pop(), reportable: !errorReported),
      ),
    );
  }

  Future<void> _onInstallCertificate() async {
    final repo = IrmaRepositoryProvider.of(context);

    final newCert = await showDialog<NewCertificate>(context: context, builder: (context) => const ProvideCertDialog());

    if (newCert == null || newCert.pemContent.isEmpty || newCert.type.isEmpty) return;

    repo.bridgedDispatch(InstallCertificateEvent(type: newCert.type, pemContent: newCert.pemContent));

    // try {
    //   await repo.getEvents().whereType<EnrollmentStatusEvent>().first.timeout(
    //     const Duration(seconds: 5),
    //   );
    // } on TimeoutException {
    //   // Installing the scheme took too long. We therefore assume that it failed.
    //   // Error is sent as ErrorEvent and will be handled by a listener in initState.
    //   return;
    // }

    // if (mounted) {
    //   showSnackbar(
    //     context,
    //     FlutterI18n.translate(context, "debug.scheme_management.success"),
    //   );
    // }
  }

  void _onCertificateTileTap(String thumbprint) => log("Tapped certificate with thumbprint $thumbprint");
  //Navigator.of(context).push(MaterialPageRoute(builder: (context) => CertManagerDetailScreen(trustAnchorId)));

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: "debug.cert_management.title",
        actions: [IrmaIconButton(icon: Icons.add, onTap: () => _onInstallCertificate())],
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
                    CertManagerTile(cert: cert, onTap: () => _onCertificateTileTap(cert.thumbprint)),
                SizedBox(height: theme.defaultSpacing),
                const TranslatedText("debug.cert_management.verifier_certs"),
                if (configuration.verifierCertificates != null)
                  for (final cert in configuration.verifierCertificates!)
                    CertManagerTile(cert: cert, onTap: () => _onCertificateTileTap(cert.thumbprint)),
              ],
            );
          },
        ),
      ),
    );
  }
}
