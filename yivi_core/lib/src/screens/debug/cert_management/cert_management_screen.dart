import "dart:async";
import "dart:developer";

import "package:material_ui/material_ui.dart";
import "package:rxdart/rxdart.dart";

import "../../../models/certificate_events.dart";
import "../../../models/error_event.dart";
import "../../../models/eudi_configuration.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/irma_app_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/feedback/yivi_spinner.dart";
import "../../../widgets/surfaces/glass_group.dart";
import "../../error/error_screen.dart";
import "../util/snackbar.dart";
import "widgets/cert_manager_tile.dart";
import "widgets/provide_cert_dialog.dart";

class CertificateManagementScreen extends StatefulWidget {
  @override
  State<CertificateManagementScreen> createState() =>
      _CertificateManagementScreenState();
}

class _CertificateManagementScreenState
    extends State<CertificateManagementScreen> {
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();

    afterFrame(() async {
      final repo = repositoryOf(context);
      _errorSubscription = repo.getEvents().whereType<ErrorEvent>().listen(
        _onErrorEvent,
      );
    });
  }

  Future<void> _onErrorEvent(ErrorEvent event) async {
    final navigator = Navigator.of(context);
    // ErrorEvents are automatically reported by the IrmaRepository if error reporting is enabled.
    final errorReported = await repositoryOf(
      context,
    ).preferences.reportErrors.stream.first;

    if (!mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (context) => ErrorScreen.fromEvent(
          error: event,
          onTapClose: navigator.pop,
          reportable: !errorReported,
        ),
      ),
    );
  }

  Future<void> _onInstallCertificate() async {
    final repo = repositoryOf(context);

    final newCert = await showDialog<NewCertificate>(
      context: context,
      builder: (context) => const ProvideCertDialog(),
    );

    if (newCert == null || newCert.pemContent.isEmpty || newCert.type.isEmpty) {
      return;
    }

    repo.bridgedDispatch(
      InstallCertificateEvent(
        type: newCert.type,
        pemContent: newCert.pemContent,
      ),
    );
  }

  void _onCertificateTileTap(String thumbprint) =>
      log("Tapped certificate with thumbprint $thumbprint");

  void _onRemoveCertificate(String type, Cert cert) {
    repositoryOf(context).bridgedDispatch(
      RemoveCertificateEvent(type: type, thumbprint: cert.thumbprint),
    );

    showSnackbar(context, context.tr("debug.cert_management.removed"));
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = repositoryOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(
        titleTranslationKey: "debug.cert_management.title",
        actions: [
          YiviIconButton(
            icon: Icons.add,
            label: "Add",
            onTap: _onInstallCertificate,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<EudiConfiguration>(
          stream: repo.getEudiConfiguration(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: YiviSpinner());
            }
            final configuration = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                YiviSpace.x16,
                0,
                YiviSpace.x16,
                YiviSpace.x16,
              ),
              children: [
                GlassGroup(
                  header: context.tr("debug.cert_management.issuer_certs"),
                  children: [
                    for (final cert
                        in configuration.issuerCertificates ?? const <Cert>[])
                      CertManagerTile(
                        cert: cert,
                        onTap: () => _onCertificateTileTap(cert.thumbprint),
                        onDelete: () => _onRemoveCertificate("issuer", cert),
                      ),
                  ],
                ),
                GlassGroup(
                  header: context.tr("debug.cert_management.verifier_certs"),
                  children: [
                    for (final cert
                        in configuration.verifierCertificates ?? const <Cert>[])
                      CertManagerTile(
                        cert: cert,
                        onTap: () => _onCertificateTileTap(cert.thumbprint),
                        onDelete: () => _onRemoveCertificate("verifier", cert),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
