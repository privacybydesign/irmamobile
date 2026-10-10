import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/missing_data_checklist.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../providers/issue_during_disclosure_provider.dart";
import "../../../providers/missing_data_flow_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/yivi_themed_button.dart";
import "disclosure_permission_choice.dart";
import "disclosure_permission_wrong_credentials_obtained_dialog.dart";
import "missing_data_header.dart";
import "session_scaffold.dart";

/// The list a user sees when a request needs data they do not have yet: one
/// row per requested credential, with a button to obtain the missing ones.
/// Shown instead of [IssueDuringDisclosureScreen] when
/// `FeatureFlag.missingDataChecklist` is on.
class MissingDataChecklistScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final VoidCallback onDismiss;

  const MissingDataChecklistScreen({
    super.key,
    required this.sessionId,
    required this.onDismiss,
  });

  @override
  ConsumerState<MissingDataChecklistScreen> createState() =>
      _MissingDataChecklistScreenState();
}

class _MissingDataChecklistScreenState
    extends ConsumerState<MissingDataChecklistScreen> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _justAddedCredentialId;
  bool _wrongCredentialDialogOpen = false;

  void _obtain(CredentialDescriptor credential) {
    ref
        .read(missingDataFlowProvider.notifier)
        .start(
          sessionId: widget.sessionId,
          credentialId: credential.credentialId,
        );
    context.pushSchemalessDataDetailsScreen(
      AddDataDetailsRouteParams(credential: credential),
    );
  }

  void _onWizardStateChanged(
    IssueDuringDisclosureState? previous,
    IssueDuringDisclosureState next,
  ) {
    final before = previous == null
        ? <String>{}
        : _presentIds(MissingDataChecklist.fromWizardState(previous));
    final added = _presentIds(
      MissingDataChecklist.fromWizardState(next),
    ).difference(before);
    if (previous != null && added.isNotEmpty) {
      setState(() => _justAddedCredentialId = added.last);
    }

    if (next.hasWrongCredential && !_wrongCredentialDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWrongCredentialDialog(next);
      });
    }
  }

  Set<String> _presentIds(MissingDataChecklist checklist) => {
    for (final e in checklist.entries)
      if (e.isPresent) e.credential.credentialId,
  };

  // The dialog goes on a navigator of its own, so an issuance screen pushed
  // over the list covers it instead of being popped in its place.
  void _showWrongCredentialDialog(IssueDuringDisclosureState state) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || _wrongCredentialDialogOpen) return;
    _wrongCredentialDialogOpen = true;

    final notifier = ref.read(
      issueDuringDisclosureProvider(widget.sessionId).notifier,
    );
    showDialog(
      context: navigator.context,
      useRootNavigator: false,
      builder: (context) => DisclosurePermissionWrongCredentialsAddedDialog(
        wrongCredential: state.wrongCredentialIssued!,
        template: state.wrongCredentialTemplate!,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ).then((_) {
      _wrongCredentialDialogOpen = false;
      notifier.dismissWrongCredentialDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final wizardState = ref.watch(
      issueDuringDisclosureProvider(widget.sessionId),
    );
    final requestor = ref
        .watch(sessionStateProvider(widget.sessionId))
        .value
        ?.requestor;
    final checklist = MissingDataChecklist.fromWizardState(wizardState);
    final next = checklist.next;

    ref.listen(
      issueDuringDisclosureProvider(widget.sessionId),
      _onWizardStateChanged,
    );

    final scaffold = SessionScaffold(
      appBarTitle: "disclosure_permission.issue_wizard.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: requestor == null
          ? null
          : _ShareDisabledBar(
              requestorName: requestor.name,
              missingCount: checklist.missingCount,
            ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (requestor != null) ...[
                MissingDataHeader(
                  requestor: requestor,
                  phase: MissingDataPhase.collecting,
                  total: checklist.total,
                  presentCount: checklist.presentCount,
                ),
                SizedBox(height: theme.defaultSpacing),
              ],
              for (final step in checklist.steps)
                if (step.isChoice)
                  _ChoiceStepCard(
                    step: step,
                    state: next?.step.index == step.index
                        ? _RowState.next
                        : _RowState.missing,
                    onChoiceUpdated: (option) => ref
                        .read(
                          issueDuringDisclosureProvider(
                            widget.sessionId,
                          ).notifier,
                        )
                        .selectOption(step.index, option),
                    onObtain: _obtain,
                  )
                else
                  for (final entry in step.entries)
                    _ChecklistRow(
                      entry: entry,
                      state: _rowState(step, entry, next),
                      onObtain: () => _obtain(entry.credential),
                    ),
            ],
          ),
        ),
      ),
    );

    return Navigator(
      key: _navigatorKey,
      onDidRemovePage: (_) {},
      pages: [MaterialPage(child: scaffold)],
    );
  }

  _RowState _rowState(
    ChecklistStep step,
    ChecklistEntry entry,
    ({ChecklistStep step, ChecklistEntry entry})? next,
  ) {
    if (entry.isPresent) {
      return entry.credential.credentialId == _justAddedCredentialId
          ? _RowState.justAdded
          : _RowState.present;
    }
    final isNext =
        next?.step.index == step.index &&
        next?.entry.credential.credentialId == entry.credential.credentialId;
    return isNext ? _RowState.next : _RowState.missing;
  }
}

enum _RowState { present, justAdded, missing, next }

const _flashDuration = Duration(milliseconds: 1600);
const _ringWidth = 2.0;

class _ChecklistRow extends StatefulWidget {
  final ChecklistEntry entry;
  final _RowState state;
  final VoidCallback onObtain;

  const _ChecklistRow({
    required this.entry,
    required this.state,
    required this.onObtain,
  });

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow>
    with SingleTickerProviderStateMixin {
  // 1.0 is the resting (white) state; the flash plays from 0.0 to 1.0.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _flashDuration,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == _RowState.justAdded) _playFlash();
  }

  @override
  void didUpdateWidget(_ChecklistRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != _RowState.justAdded &&
        widget.state == _RowState.justAdded) {
      _playFlash();
    }
  }

  void _playFlash() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _flash.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final credential = widget.entry.credential;
    final isPresent = widget.entry.isPresent;
    final isNext = widget.state == _RowState.next;

    // Hold the green for the first part of the animation, then fade out.
    final background = TweenSequence<Color?>([
      TweenSequenceItem(tween: ConstantTween(theme.successSurface), weight: 40),
      TweenSequenceItem(
        tween: ColorTween(begin: theme.successSurface, end: theme.light),
        weight: 60,
      ),
    ]).animate(_flash);

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: AnimatedBuilder(
        animation: background,
        builder: (context, child) => Container(
          key: Key("missing_data_row_${credential.credentialId}"),
          foregroundDecoration: isNext
              ? BoxDecoration(
                  borderRadius: theme.borderRadius,
                  border: Border.all(color: theme.primary, width: _ringWidth),
                )
              : null,
          child: IrmaCard(
            color: widget.state == _RowState.justAdded
                ? background.value
                : theme.light,
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _CredentialLogo(credential: credential),
                SizedBox(width: theme.defaultSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.name,
                        style: theme.themeData.textTheme.headlineMedium,
                      ),
                      _RowStatus(state: widget.state),
                    ],
                  ),
                ),
              ],
            ),
            if (!isPresent && credential.issueURL != null)
              Padding(
                padding: EdgeInsets.only(top: theme.smallSpacing),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ObtainButton(
                    credential: credential,
                    onPressed: widget.onObtain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowStatus extends StatelessWidget {
  final _RowState state;

  const _RowStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isPresent =
        state == _RowState.present || state == _RowState.justAdded;
    final key = switch (state) {
      _RowState.present => "missing_data.status.present",
      _RowState.justAdded => "missing_data.status.just_added",
      _RowState.missing || _RowState.next => "missing_data.status.missing",
    };

    return Row(
      children: [
        if (isPresent) ...[
          ExcludeSemantics(
            child: Icon(Icons.check_circle, color: theme.success, size: 18),
          ),
          SizedBox(width: theme.tinySpacing),
        ],
        Flexible(
          child: Text(
            FlutterI18n.translate(context, key),
            style: theme.themeData.textTheme.bodySmall!.copyWith(
              color: theme.neutralExtraDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ObtainButton extends StatelessWidget {
  final CredentialDescriptor credential;
  final VoidCallback onPressed;

  const _ObtainButton({required this.credential, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Name the credential, so the buttons of different rows can be told apart.
    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      label: FlutterI18n.translate(
        context,
        "missing_data.obtain_named",
        translationParams: {"credential": credential.name},
      ),
      child: YiviThemedButton(
        label: "missing_data.obtain",
        style: YiviButtonStyle.outlined,
        size: YiviButtonSize.small,
        onPressed: onPressed,
      ),
    );
  }
}

class _CredentialLogo extends StatelessWidget {
  final CredentialDescriptor credential;

  const _CredentialLogo({required this.credential});

  @override
  Widget build(BuildContext context) {
    final image = credential.image;

    return ExcludeSemantics(
      child: IrmaAvatar(
        size: 40,
        logoImage: image != null
            ? Base64Image(base64: image.base64, mimeType: image.mimeType)
            : null,
        initials: credential.name.isNotEmpty ? credential.name[0] : "?",
      ),
    );
  }
}

/// A step the user can satisfy with more than one credential, shown with the
/// existing radio choice.
class _ChoiceStepCard extends StatelessWidget {
  final ChecklistStep step;
  final _RowState state;
  final ValueChanged<int> onChoiceUpdated;
  final ValueChanged<CredentialDescriptor> onObtain;

  const _ChoiceStepCard({
    required this.step,
    required this.state,
    required this.onChoiceUpdated,
    required this.onObtain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final target = step.entries
        .where((e) => !e.isPresent && e.credential.issueURL != null)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Container(
        key: Key("missing_data_choice_${step.index}"),
        padding: EdgeInsets.all(theme.smallSpacing),
        foregroundDecoration: state == _RowState.next
            ? BoxDecoration(
                borderRadius: theme.borderRadius,
                border: Border.all(color: theme.primary, width: _ringWidth),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(theme.smallSpacing),
              child: Text(
                FlutterI18n.translate(context, "disclosure_permission.choose"),
                style: theme.themeData.textTheme.headlineMedium,
              ),
            ),
            DisclosurePermissionChoice.fromIssuanceBundles(
              options: step.step.options,
              selectedIndex: step.shownOptionIndex,
              onChoiceUpdated: onChoiceUpdated,
            ),
            if (target != null)
              Padding(
                padding: EdgeInsets.only(top: theme.smallSpacing),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ObtainButton(
                    credential: target.credential,
                    onPressed: () => onObtain(target.credential),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The share button stays disabled until everything is in the app; the hint
/// says what is still missing.
class _ShareDisabledBar extends StatelessWidget {
  final String requestorName;
  final int missingCount;

  const _ShareDisabledBar({
    required this.requestorName,
    required this.missingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaBottomBarBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            FlutterI18n.translate(
              context,
              missingCount == 1
                  ? "missing_data.hint.one"
                  : "missing_data.hint.other",
              translationParams: {"n": "$missingCount"},
            ),
            textAlign: TextAlign.center,
            style: theme.themeData.textTheme.bodySmall!.copyWith(
              color: theme.neutralExtraDark,
            ),
          ),
          SizedBox(height: theme.smallSpacing),
          YiviThemedButton(
            key: const Key("missing_data_share_disabled"),
            label: "missing_data.share_with",
            labelParams: {"requestor": requestorName},
          ),
        ],
      ),
    );
  }
}
