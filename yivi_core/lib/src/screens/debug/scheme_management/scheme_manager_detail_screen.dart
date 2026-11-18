import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:rxdart/rxdart.dart";

import "../../../models/authentication_events.dart";
import "../../../models/enrollment_events.dart";
import "../../../models/scheme_events.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/action_bar.dart";
import "../../../widgets/active_indicator.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/yivi_spinner.dart";
import "../../error/error_screen.dart";
import "../../pin/yivi_pin_screen.dart";
import "../debug_schemes.dart";
import "../util/snackbar.dart";

class SchemeManagerDetailScreen extends ConsumerWidget {
  final String schemeManagerId;

  const SchemeManagerDetailScreen(this.schemeManagerId);

  Future<String?> _requestPin(
    BuildContext context,
    String title,
    String instruction,
  ) async {
    final repo = repositoryOf(context);
    final navigator = Navigator.of(context);

    final hasLongPin = await repo.preferences.longPin.stream.first;
    final maxPinSize = hasLongPin ? longPinSize : shortPinSize;

    return navigator.push(
      MaterialPageRoute(
        builder: (context) => YiviPinScaffold(
          appBar: IrmaAppBar(titleString: title),
          body: YiviPinScreen(
            instruction: instruction,
            maxPinSize: maxPinSize,
            onSubmit: (pin) => navigator.pop(pin),
            listener: submitWhenFull(maxPinSize, navigator.pop),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPin(BuildContext context, String schemeId) async {
    final repo = repositoryOf(context);
    final navigator = Navigator.of(context);

    final pin = await _requestPin(
      context,
      context.tr("debug.scheme_management.verify_pin.title"),
      context.tr("debug.scheme_management.verify_pin.content", {
        "scheme": schemeManagerId,
      }),
    );
    if (pin == null) return;

    repo.bridgedDispatch(AuthenticateEvent(pin: pin, schemeId: schemeId));

    final event = await repo.getEvents().whereType<AuthenticationEvent>().first;

    if (event is AuthenticationErrorEvent) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ErrorScreen(
            details: event.error.toString(),
            onTapClose: () => navigator.pop(),
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      showSnackbar(
        context,
        event is AuthenticationFailedEvent
            ? context.tr("debug.scheme_management.verify_pin.failed", {
                "remainingAttempts": event.remainingAttempts.toString(),
                "blockedDuration": event.blockedDuration.toString(),
              })
            : context.tr("debug.scheme_management.verify_pin.success"),
      );
    }
  }

  Future<void> _onActivateScheme(BuildContext context) async {
    final language = context.lang;

    final pin = await _requestPin(
      context,
      context.tr("debug.scheme_management.request_pin.title"),
      context.tr("debug.scheme_management.request_pin.content", {
        "scheme": schemeManagerId,
      }),
    );
    if (pin == null) return;
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    showSnackbar(
      context,
      context.tr("debug.scheme_management.activating", {
        "scheme": schemeManagerId,
      }),
    );

    final repo = repositoryOf(context);
    repo.bridgedDispatch(
      EnrollEvent(
        email: "",
        pin: pin,
        language: language,
        schemeId: schemeManagerId,
      ),
    );

    final event = await repo.getEvents().whereType<EnrollmentEvent>().first;
    if (event is EnrollmentFailureEvent) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ErrorScreen(
            details: event.error.toString(),
            onTapClose: () => navigator.pop(),
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      showSnackbar(
        context,
        context.tr("debug.scheme_management.activate_success", {
          "scheme": schemeManagerId,
        }),
      );
    }
  }

  void _onDeleteScheme(BuildContext context) {
    repositoryOf(
      context,
    ).bridgedDispatch(RemoveSchemeEvent(schemeId: schemeManagerId));
    Navigator.of(context).pop();

    if (!context.mounted) return;
    showSnackbar(
      context,
      context.tr("debug.scheme_management.remove", {"scheme": schemeManagerId}),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = repositoryOf(context);

    return StreamBuilder<EnrollmentStatusEvent>(
      stream: repo.getEnrollmentStatusEvent(),
      builder: (context, snapshot) {
        final schemes = ref.watch(debugSchemesProvider).value;
        if (!snapshot.hasData || schemes == null) {
          return Scaffold(body: Center(child: YiviSpinner()));
        }

        final enrollmentStatus = snapshot.data!;

        final schemeManager = schemes.schemeManagers
            .where((scheme) => scheme.id == schemeManagerId)
            .firstOrNull;
        if (schemeManager == null) {
          throw Exception("Scheme manager $schemeManagerId not found");
        }

        final schemeIsActive = enrollmentStatus.enrolledSchemeManagerIds
            .contains(schemeManager.id);

        Widget? bottomBar;
        if (schemeManager.keyshareServer.isNotEmpty) {
          if (schemeIsActive) {
            bottomBar = ActionBar.single(
              label: context.tr("debug.scheme_management.verify_pin.title"),
              onTap: () => _verifyPin(context, schemeManager.id),
            );
          } else {
            bottomBar = ActionBar.single(
              label: context.tr("ui.activate"),
              onTap: () => _onActivateScheme(context),
            );
          }
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          backgroundColor: YiviPalette.of(context).background,
          appBar: IrmaAppBar(
            titleString: schemeManager.id,
            actions: [
              YiviIconButton(
                icon: Icons.delete_outline_rounded,
                danger: true,
                label: "Delete",
                onTap: () => _onDeleteScheme(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(YiviSpace.pageSide),
            child: SafeArea(
              child: GlassGroup(
                children: [
                  // These values are not translated because they are the same in English and Dutch.
                  if (!schemeManager.demo)
                    ListTile(
                      title: const Text("Status"),
                      trailing: ActiveIndicator(schemeIsActive),
                    ),

                  ListTile(
                    title: const Text("Type"),
                    subtitle: Text(
                      schemeManager.demo ? "Demo scheme" : "Production scheme",
                    ),
                  ),

                  ListTile(
                    title: const Text("Latest scheme update"),
                    subtitle: Text(
                      "${DateTime.fromMillisecondsSinceEpoch(schemeManager.timestamp * 1000)}\nTimestamp ${schemeManager.timestamp}",
                    ),
                  ),

                  ListTile(
                    title: const Text("Keyshare server"),
                    subtitle: Text(
                      schemeManager.keyshareServer.isNotEmpty
                          ? schemeManager.keyshareServer
                          : "(none)",
                    ),
                  ),

                  ListTile(
                    title: const Text("Timestamp server"),
                    subtitle: Text(
                      schemeManager.timestampServer.isNotEmpty
                          ? schemeManager.timestampServer
                          : "(none)",
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: bottomBar,
        );
      },
    );
  }
}
