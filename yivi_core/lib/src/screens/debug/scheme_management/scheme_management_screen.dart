import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:rxdart/rxdart.dart";

import "../../../models/enrollment_events.dart";
import "../../../models/error_event.dart";
import "../../../models/scheme_events.dart";
import "../../../models/scheme_rules.dart";
import "../../../models/update_schemes_event.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/feedback/glass_dialog.dart";
import "../../../widgets/feedback/yivi_spinner.dart";
import "../../../widgets/surfaces/glass_group.dart";
import "../../error/error_screen.dart";
import "../debug_schemes.dart";
import "../util/snackbar.dart";
import "requestor_scheme_detail_screen.dart";
import "scheme_manager_detail_screen.dart";
import "widgets/provide_scheme_url_dialog.dart";
import "widgets/scheme_manager_tile.dart";

class SchemeManagementScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SchemeManagementScreen> createState() =>
      _SchemeManagementScreenState();
}

class _SchemeManagementScreenState
    extends ConsumerState<SchemeManagementScreen> {
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

  Future<void> _onInstallScheme() async {
    final repo = repositoryOf(context);

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
    final publicKeyConfirmed = await showConfirmDialog(
      context,
      titleKey: "debug.confirm_scheme_public_key_dialog_title",
      // Not a key: shown as it is.
      messageKey: publicKey,
    );

    if (!publicKeyConfirmed) return;

    repo.bridgedDispatch(
      InstallSchemeEvent(url: schemeUrl, publicKey: publicKey),
    );

    try {
      await repo.getEvents().whereType<EnrollmentStatusEvent>().first.timeout(
        const Duration(seconds: 5),
      );
    } on TimeoutException {
      // Installing the scheme took too long. We therefore assume that it failed.
      // Error is sent as ErrorEvent and will be handled by a listener in initState.
      return;
    }

    if (mounted) {
      showSnackbar(context, context.tr("debug.scheme_management.success"));
    }
  }

  Future<void> _onUpdateSchemes() async {
    showSnackbar(context, context.tr("debug.scheme_management.updating"));

    final repo = repositoryOf(context);
    repo.bridgedDispatch(UpdateSchemesEvent());

    try {
      // Go sends new scheme rules after updating the schemes.
      await repo.getEvents().whereType<SchemeRulesEvent>().first.timeout(
        const Duration(minutes: 1),
      );
    } on TimeoutException {
      // Installing the scheme took too long. We therefore assume that it failed.
      // Error is sent as ErrorEvent and will be handled by a listener in initState.
      return;
    }

    if (mounted) {
      showSnackbar(
        context,
        context.tr("debug.scheme_management.update_success"),
      );
    }
  }

  void _onSchemeManagerTileTap(String schemeManagerId) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SchemeManagerDetailScreen(schemeManagerId),
        ),
      );

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
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: YiviAppBar(
        titleTranslationKey: "debug.scheme_management.title",
        actions: [
          YiviIconButton(
            icon: Icons.add,
            label: "Add",
            onTap: _onInstallScheme,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<EnrollmentStatusEvent>(
          stream: repo.getEnrollmentStatusEvent(),
          builder: (context, snapshot) {
            final schemes = ref.watch(debugSchemesProvider).value;
            if (!snapshot.hasData || schemes == null) {
              return Center(child: YiviSpinner());
            }
            final enrollmentStatus = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                YiviSpace.x16,
                0,
                YiviSpace.x16,
                YiviSpace.x16,
              ),
              children: [
                GlassGroup(
                  header: context.tr("debug.scheme_management.issuer_schemes"),
                  children: [
                    for (final schemeManager in schemes.schemeManagers)
                      SchemeManagerTile(
                        schemeManager: schemeManager,
                        isActive: schemeManager.keyshareServer.isNotEmpty
                            ? enrollmentStatus.enrolledSchemeManagerIds
                                  .contains(schemeManager.id)
                            : null,
                        onTap: () => _onSchemeManagerTileTap(schemeManager.id),
                      ),
                  ],
                ),
                GlassGroup(
                  header: context.tr(
                    "debug.scheme_management.requestor_schemes",
                  ),
                  children: [
                    for (final requestorScheme in schemes.requestorSchemes)
                      ListTile(
                        title: Text(requestorScheme.id),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RequestorSchemeDetailScreen(
                              requestorScheme: requestorScheme,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: ActionBar.single(
        label: context.tr("debug.scheme_management.update"),
        onTap: _onUpdateSchemes,
      ),
    );
  }
}
