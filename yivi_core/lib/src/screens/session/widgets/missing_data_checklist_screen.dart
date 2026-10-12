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
import "../../../widgets/missing_data_bottom_bar.dart";
import "../../../widgets/missing_data_button.dart";
import "../../../widgets/missing_data_check.dart";
import "../../../widgets/missing_data_style.dart";
import "disclosure_permission_choice.dart";
import "disclosure_permission_wrong_credentials_obtained_dialog.dart";
import "missing_data_header.dart";

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

    ref.listen(
      issueDuringDisclosureProvider(widget.sessionId),
      _onWizardStateChanged,
    );

    final scaffold = Scaffold(
      backgroundColor: theme.backgroundTertiary,
      bottomNavigationBar: requestor == null
          ? null
          : _ShareDisabledBar(
              requestorName: requestor.name,
              missingCount: checklist.missingCount,
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (requestor != null)
              MissingDataHeader(
                requestor: requestor,
                phase: MissingDataPhase.collecting,
                total: checklist.total,
                onDismiss: widget.onDismiss,
              ),
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _listPadding,
                  vertical: _listVerticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.defaultSpacing,
                  children: [
                    _ProgressRow(
                      presentCount: checklist.presentCount,
                      total: checklist.total,
                    ),
                    if (checklist.missingCount > 0)
                      _Intro(missingCount: checklist.missingCount),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.smallSpacing,
                      children: [
                        for (final step in checklist.steps)
                          if (step.isChoice)
                            _ChoiceStepCard(
                              step: step,
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
                                state: _rowState(entry),
                                onObtain: () => _obtain(entry.credential),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Navigator(
      key: _navigatorKey,
      onDidRemovePage: (_) {},
      pages: [MaterialPage(child: scaffold)],
    );
  }

  _RowState _rowState(ChecklistEntry entry) {
    if (!entry.isPresent) return _RowState.missing;

    return entry.credential.credentialId == _justAddedCredentialId
        ? _RowState.justAdded
        : _RowState.present;
  }
}

enum _RowState { present, justAdded, missing }

const _flashDuration = Duration(milliseconds: 1600);
const _growDuration = Duration(milliseconds: 1000);
const _stackScale = 1.5;
const _listPadding = 16.0;
const _listVerticalPadding = 20.0;
const _progressBarHeight = 8.0;
const _rowAvatarSize = 40.0;
const _rowGap = 12.0;
const _rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
const _borderWidth = 2.0;
const _dashLength = 4.0;
const _dashGap = 2.0;

/// The bar and the count above the list.
class _ProgressRow extends StatelessWidget {
  final int presentCount;
  final int total;

  const _ProgressRow({required this.presentCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _growDuration;

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_progressBarHeight / 2),
              child: Container(
                height: _progressBarHeight,
                color: theme.neutralLight,
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: total == 0 ? 0 : presentCount / total),
                  duration: duration,
                  curve: Curves.easeOut,
                  builder: (context, fraction, _) => FractionallySizedBox(
                    widthFactor: fraction,
                    heightFactor: 1,
                    child: ColoredBox(color: theme.success),
                  ),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            FlutterI18n.translate(
              context,
              "missing_data.progress",
              translationParams: {"x": "$presentCount", "n": "$total"},
            ),
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              height: 19 / 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// What is still to do, in a sentence.
class _Intro extends StatelessWidget {
  final int missingCount;

  const _Intro({required this.missingCount});

  @override
  Widget build(BuildContext context) {
    final key = switch (missingCount) {
      1 => "missing_data.intro.one",
      2 => "missing_data.intro.two",
      _ => "missing_data.intro.other",
    };

    return Text(
      FlutterI18n.translate(
        context,
        key,
        translationParams: {"n": "$missingCount"},
      ),
      style: IrmaTheme.of(context).textTheme.bodyMedium,
    );
  }
}

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
    final obtain = !isPresent && credential.issueURL != null
        ? _ObtainButton(credential: credential, onPressed: widget.onObtain)
        : null;
    // At a large text size the button no longer fits beside the name.
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= _stackScale;

    // Hold the green for the first part of the animation, then fade out.
    final background = TweenSequence<Color?>([
      TweenSequenceItem(tween: ConstantTween(theme.successSurface), weight: 40),
      TweenSequenceItem(
        tween: ColorTween(begin: theme.successSurface, end: theme.light),
        weight: 60,
      ),
    ]).animate(_flash);

    // The check pops in while the row is still green.
    final pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.25), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1), weight: 45),
    ]).animate(CurvedAnimation(parent: _flash, curve: const Interval(0, 0.3)));

    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) => _RowBox(
        key: Key("missing_data_row_${credential.credentialId}"),
        state: widget.state,
        color: widget.state == _RowState.justAdded ? background.value : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.smallSpacing,
          children: [
            Row(
              spacing: _rowGap,
              children: [
                _CredentialLogo(credential: credential),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(credential.name, style: missingDataNameStyle(theme)),
                      _RowStatus(state: widget.state),
                    ],
                  ),
                ),
                if (isPresent)
                  ScaleTransition(scale: pop, child: const MissingDataCheck())
                else if (obtain != null && !stacked)
                  obtain,
              ],
            ),
            if (obtain != null && stacked)
              Align(alignment: Alignment.centerRight, child: obtain),
          ],
        ),
      ),
    );
  }
}

/// A row of the list: white with a shadow when the credential is in the app,
/// a dashed outline when it is not.
class _RowBox extends StatelessWidget {
  final _RowState state;

  /// The background of a row that is in the app, white when null.
  final Color? color;
  final Widget child;

  const _RowBox({
    super.key,
    required this.state,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (state != _RowState.missing) {
      return Container(
        padding: _rowPadding,
        decoration: BoxDecoration(
          color: color ?? IrmaTheme.of(context).light,
          borderRadius: missingDataRowRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 1),
              blurRadius: 6,
            ),
          ],
        ),
        child: child,
      );
    }

    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(),
      child: Container(
        padding: _rowPadding,
        decoration: BoxDecoration(
          color: missingDataMissingFill,
          borderRadius: missingDataRowRadius,
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // The outline sits inside the box, so the stroke is centred half its
    // width in.
    const inset = _borderWidth / 2;
    final outline = Path()
      ..addRRect(
        missingDataRowRadius.toRRect(Offset.zero & size).deflate(inset),
      );
    final paint = Paint()
      ..color = missingDataDashedBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;

    for (final metric in outline.computeMetrics()) {
      for (
        var start = 0.0;
        start < metric.length;
        start += _dashLength + _dashGap
      ) {
        canvas.drawPath(metric.extractPath(start, start + _dashLength), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

class _RowStatus extends StatelessWidget {
  final _RowState state;

  const _RowStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final key = switch (state) {
      _RowState.present => "missing_data.status.present",
      _RowState.justAdded => "missing_data.status.just_added",
      _RowState.missing => "missing_data.status.missing",
    };
    final style = missingDataCaptionStyle(theme);

    return Text(
      FlutterI18n.translate(context, key),
      style: switch (state) {
        _RowState.present => style.copyWith(
          color: missingDataSuccessText,
          fontWeight: FontWeight.w600,
        ),
        _RowState.justAdded => style.copyWith(
          color: missingDataSuccessText,
          fontWeight: FontWeight.w700,
        ),
        _RowState.missing => style,
      },
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
      child: MissingDataButton(
        label: "missing_data.obtain",
        style: MissingDataButtonStyle.compact,
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
        size: _rowAvatarSize,
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
  final ValueChanged<int> onChoiceUpdated;
  final ValueChanged<CredentialDescriptor> onObtain;

  const _ChoiceStepCard({
    required this.step,
    required this.onChoiceUpdated,
    required this.onObtain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final target = step.entries
        .where((e) => !e.isPresent && e.credential.issueURL != null)
        .firstOrNull;

    return _RowBox(
      key: Key("missing_data_choice_${step.index}"),
      state: _RowState.missing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.smallSpacing,
        children: [
          Text(
            FlutterI18n.translate(context, "disclosure_permission.choose"),
            style: missingDataNameStyle(theme),
          ),
          DisclosurePermissionChoice.fromIssuanceBundles(
            options: step.step.options,
            selectedIndex: step.shownOptionIndex,
            onChoiceUpdated: onChoiceUpdated,
          ),
          if (target != null)
            Align(
              alignment: Alignment.centerRight,
              child: _ObtainButton(
                credential: target.credential,
                onPressed: () => onObtain(target.credential),
              ),
            ),
        ],
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

    return MissingDataBottomBar(
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
          style: missingDataCaptionStyle(theme),
        ),
        MissingDataButton(
          key: const Key("missing_data_share_disabled"),
          label: "missing_data.share_with",
          labelParams: {"requestor": requestorName},
        ),
      ],
    );
  }
}
