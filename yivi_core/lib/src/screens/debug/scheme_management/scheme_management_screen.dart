import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/enrollment_events.dart";
import "../../../models/error_event.dart";
import "../../../models/irma_configuration.dart";
import "../../../models/scheme_events.dart";
import "../../../models/update_schemes_event.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/combine.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/progress.dart";
import "../../../widgets/translated_text.dart";
import "../../error/error_screen.dart";
import "../util/await_action_result.dart";
import "../util/snackbar.dart";
import "requestor_scheme_detail_screen.dart";
import "scheme_manager_detail_screen.dart";
import "widgets/confirm_scheme_public_key_dialog.dart";
import "widgets/provide_scheme_url_dialog.dart";
import "widgets/scheme_manager_tile.dart";

class SchemeManagementScreen extends StatefulWidget {
  @override
  State<SchemeManagementScreen> createState() => _SchemeManagementScreenState();
}

class _SchemeManagementScreenState extends State<SchemeManagementScreen> {
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

  Future<void> _onInstallScheme() async {
    final repo = IrmaRepositoryProvider.of(context);

    final schemeUrl = await showDialog<String>(
      context: context,
      builder: (context) => const ProvideSchemeUrlDialog(),
    );

    if (schemeUrl == null) return;

    String publicKey;
    try {
      final Uri uri = Uri.parse("$schemeUrl/pk.pem");
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      publicKey = await response.transform(utf8.decoder).first;
      if (response.statusCode != 200) {
        throw "HTTP status code ${response.statusCode} received";
      }
    } catch (e) {
      if (mounted) {
        showSnackbar(context, "Error while fetching scheme: ${e.toString()}.");
      }
      return;
    }

    // Before showing the second dialog, we have to check whether the widget is still mounted.
    if (!mounted) {
      return;
    }

    // Show the second dialog to confirm the public key.
    final publicKeyConfirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) =>
              ConfirmSchemePublicKeyDialog(publicKey: publicKey),
        ) ??
        false;

    if (!publicKeyConfirmed) return;

    // Start listening for the result before dispatching, scoped to this action
    // so unrelated background errors are not mistaken for an install failure.
    final resultFuture = awaitActionResult<EnrollmentStatusEvent>(
      repo,
      timeout: const Duration(seconds: 5),
    );
    repo.bridgedDispatch(
      InstallSchemeEvent(url: schemeUrl, publicKey: publicKey),
    );

    ErrorEvent? error;
    try {
      error = await resultFuture;
    } on TimeoutException {
      // Installing the scheme took too long. We therefore assume that it failed.
      return;
    }

    if (!mounted) return;

    if (error != null) {
      await _onErrorEvent(error);
      return;
    }

    showSnackbar(
      context,
      FlutterI18n.translate(context, "debug.scheme_management.success"),
    );
  }

  Future<void> _onUpdateSchemes() async {
    showSnackbar(
      context,
      FlutterI18n.translate(context, "debug.scheme_management.updating"),
    );

    final repo = IrmaRepositoryProvider.of(context);

    final resultFuture = awaitActionResult<IrmaConfigurationEvent>(
      repo,
      timeout: const Duration(minutes: 1),
    );
    repo.bridgedDispatch(UpdateSchemesEvent());

    ErrorEvent? error;
    try {
      error = await resultFuture;
    } on TimeoutException {
      // Updating the schemes took too long. We therefore assume that it failed.
      return;
    }

    if (!mounted) return;

    if (error != null) {
      await _onErrorEvent(error);
      return;
    }

    showSnackbar(
      context,
      FlutterI18n.translate(context, "debug.scheme_management.update_success"),
    );
  }

  void _onSchemeManagerTileTap(String schemeManagerId) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SchemeManagerDetailScreen(schemeManagerId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: "debug.scheme_management.title",
        actions: [
          IrmaIconButton(icon: Icons.add, onTap: () => _onInstallScheme()),
        ],
      ),
      body: SafeArea(
        child:
            StreamBuilder<
              CombinedState2<EnrollmentStatusEvent, IrmaConfiguration>
            >(
              stream: combine2(
                repo.getEnrollmentStatusEvent(),
                repo.getIrmaConfiguration(),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: IrmaProgress());
                }
                final enrollmentStatus = snapshot.data!.a;
                final irmaConfiguration = snapshot.data!.b;

                return ListView(
                  padding: EdgeInsets.all(theme.defaultSpacing),
                  children: [
                    const TranslatedText(
                      "debug.scheme_management.issuer_schemes",
                    ),
                    for (final schemeManager
                        in irmaConfiguration.schemeManagers.values)
                      SchemeManagerTile(
                        schemeManager: schemeManager,
                        isActive: schemeManager.keyshareServer.isNotEmpty
                            ? enrollmentStatus.enrolledSchemeManagerIds
                                  .contains(schemeManager.id)
                            : null,
                        onTap: () => _onSchemeManagerTileTap(schemeManager.id),
                      ),
                    SizedBox(height: theme.defaultSpacing),
                    const TranslatedText(
                      "debug.scheme_management.requestor_schemes",
                    ),
                    for (final schemeId
                        in irmaConfiguration.requestorSchemes.keys)
                      ListTile(
                        title: Text(schemeId),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RequestorSchemeDetailScreen(
                              requestorScheme:
                                  irmaConfiguration.requestorSchemes[schemeId]!,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "debug.scheme_management.update",
        onPrimaryPressed: () => _onUpdateSchemes(),
      ),
    );
  }
}
