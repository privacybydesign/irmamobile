import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../providers/issue_during_disclosure_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/session_progress_indicator.dart";
import "disclosure_discon_stepper.dart";
import "disclosure_permission_wrong_credentials_obtained_dialog.dart";
import "session_scaffold.dart";

/// Shows the issuance-during-disclosure steps that the user needs to complete
/// before they can proceed with the disclosure.
///
/// Uses [IrmaStepper] to display steps as a timeline, matching the visual
/// style from the old disclosure permission issue wizard.
class IssueDuringDisclosureScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final VoidCallback onDismiss;
  final VoidCallback onClose;
  final VoidCallback? onCompleted;

  const IssueDuringDisclosureScreen({
    super.key,
    required this.sessionId,
    required this.onDismiss,
    required this.onClose,
    this.onCompleted,
  });

  @override
  ConsumerState<IssueDuringDisclosureScreen> createState() =>
      _IssueDuringDisclosureScreenState();
}

class _IssueDuringDisclosureScreenState
    extends ConsumerState<IssueDuringDisclosureScreen>
    with RouteAware {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _onObtainData(BuildContext context, CredentialDescriptor credential) {
    context.pushSchemalessDataDetailsScreen(
      AddDataDetailsRouteParams(credential: credential),
    );
  }

  /// A single tap on a choice option picks it and starts obtaining its first
  /// credential that has not been issued yet.
  void _onObtainOption(
    IssueDuringDisclosureNotifier notifier,
    IssueDuringDisclosureState wizardState,
    Map<String, dynamic> issuedIds,
    ({int stepIndex, int optionIndex}) choice,
  ) {
    notifier.selectOption(choice.stepIndex, choice.optionIndex);

    final bundle =
        wizardState.steps[choice.stepIndex].options[choice.optionIndex];
    final next = bundle.credentials
        .where((d) => !issuedIds.containsKey(d.credentialId))
        .firstOrNull;
    if (next == null) return;

    _onObtainData(context, next);
  }

  void _showWrongCredentialDialog(IssueDuringDisclosureState wizardState) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !mounted) return;

    // Prevent dialogs from stacking when a state refreshes.
    if (navigator.canPop()) return;

    final notifier = ref.read(
      issueDuringDisclosureProvider(widget.sessionId).notifier,
    );

    showDialog(
      context: navigator.context,
      useRootNavigator: false,
      builder: (context) => DisclosurePermissionWrongCredentialsAddedDialog(
        wrongCredential: wizardState.wrongCredentialIssued!,
        template: wizardState.wrongCredentialTemplate!,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ).then((_) {
      notifier.dismissWrongCredentialDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final wizardState = ref.watch(
      issueDuringDisclosureProvider(widget.sessionId),
    );
    final notifier = ref.read(
      issueDuringDisclosureProvider(widget.sessionId).notifier,
    );

    final session = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final requestor = session?.requestor;

    final steps = wizardState.steps;
    final currentStepIndex = wizardState.currentStepIndex;
    final isCompleted = wizardState.isCompleted;

    // Determine the next credential the user must issue. For multi-credential
    // bundles, walk the bundle and pick the first descriptor whose credential
    // type isn't already issued during this session.
    final issuedIds =
        session?.disclosurePlan?.issueDuringDisclosure?.issuedCredentialIds ??
        const {};
    CredentialDescriptor? currentCredential;
    if (currentStepIndex != null) {
      final bundle = steps[currentStepIndex]
          .options[wizardState.selectedOptionPerStep[currentStepIndex]];
      for (final descriptor in bundle.credentials) {
        if (!issuedIds.containsKey(descriptor.credentialId)) {
          currentCredential = descriptor;
          break;
        }
      }
    }
    final currentIsObtainable = currentCredential?.issueURL != null;

    final singleTapChoice =
        ref.watch(featureFlagProvider(FeatureFlag.singleTapChoice)).value ??
        false;
    final currentIsChoice =
        currentStepIndex != null && steps[currentStepIndex].options.length > 1;

    ref.listen(issueDuringDisclosureProvider(widget.sessionId), (prev, next) {
      if (next.hasWrongCredential) {
        // Show the dialog after the current frame so the screen is visible.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWrongCredentialDialog(next);
        });
      }
    });

    // Determine button label and action based on state.
    final String? buttonLabel;
    final VoidCallback? buttonAction;
    if (isCompleted) {
      buttonLabel = "disclosure_permission.next_step";
      buttonAction = widget.onCompleted ?? widget.onDismiss;
    } else if (singleTapChoice && currentIsChoice) {
      // The options are tappable rows, so there is no separate button.
      buttonLabel = null;
      buttonAction = null;
    } else if (currentIsObtainable) {
      buttonLabel = "disclosure_permission.obtain_data";
      buttonAction = () {
        _onObtainData(context, currentCredential!);
      };
    } else {
      buttonLabel = "disclosure_permission.close";
      buttonAction = widget.onClose;
    }

    return Navigator(
      key: _navigatorKey,
      onDidRemovePage: (_) {},
      pages: [
        MaterialPage(
          child: SessionScaffold(
            appBarTitle: "disclosure_permission.issue_wizard.title",
            onDismiss: widget.onDismiss,
            bottomNavigationBar: IrmaBottomBar(
              primaryButtonLabel: buttonLabel,
              onPrimaryPressed: buttonAction,
              secondaryButtonLabel: "session.navigation_bar.cancel",
              onSecondaryPressed: widget.onDismiss,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (requestor != null)
                      RequestorHeader(
                        requestor: requestor,
                        isVerified: requestor.verified,
                      ),
                    SessionProgressIndicator(
                      step: 1,
                      stepCount: 2,
                      contentTranslationKey: wizardState.explanationKey,
                    ),
                    DisclosureDisconStepper.fromState(
                      wizardState: wizardState,
                      notifier: notifier,
                      onObtainOption: singleTapChoice
                          ? (choice) => _onObtainOption(
                              notifier,
                              wizardState,
                              issuedIds,
                              choice,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
