import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/issue_during_disclosure_provider.dart";
import "../../../providers/missing_data_flow_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../models/disclosure_view_model.dart";
import "change_choice_sheet.dart";
import "session_columns.dart";
import "session_requestor_header.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

/// "Add data first": what a request asks for that is not in the app yet,
/// as steps. The current step lists its options as radio rows (each saying
/// where it is added); one button at the bottom adds the selected one. Done
/// steps fold into a line, later steps wait below.
///
/// Built from `issue_during_disclosure` only: irmago sends just the missing
/// items here, the cards already in the app show on the share screen that
/// follows. Once nothing is missing, the session screen shows that share
/// screen (there is no "Next step").
class AddMissingDataScreen extends ConsumerWidget {
  final int sessionId;

  /// The close button: asks whether to stop without sharing.
  final VoidCallback onDismiss;

  /// Ends the session without asking, for "Close" when nothing in the
  /// current step can be added from Yivi.
  final VoidCallback onClose;

  const AddMissingDataScreen({
    super.key,
    required this.sessionId,
    required this.onDismiss,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider(sessionId)).value;
    final state = ref.watch(issueDuringDisclosureProvider(sessionId));
    if (session == null || state.steps.isEmpty) {
      return SessionScaffold(
        appBarTitle: "share.add_data.bar",
        onDismiss: onDismiss,
      );
    }
    final requestor = session.requestor.name;
    final steps = state.steps;
    final issued = state.issuedCredentialIds;
    final current = steps.indexWhere((s) => !isStepDone(s, issued));
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);

    final selected = current < 0
        ? 0
        : state.selectedOptionPerStep.length > current
        ? state.selectedOptionPerStep[current]
        : defaultStepOption(steps[current]);
    final action = current < 0
        ? null
        : addActionFor(
            steps[current],
            selected,
            issued,
            wrongCredentialIssued: state.wrongCredentialIssued,
          );

    final header = <Widget>[
      SessionRequestorHeader(
        requestor: session.requestor,
        description: t(
          steps.length > 1
              ? "share.add_data.intro_many"
              : "share.add_data.intro_one",
          {"requestor": requestor},
        ),
        progress: steps.length > 1
            ? StepProgress(
                total: steps.length,
                current: current < 0 ? steps.length - 1 : current,
              )
            : null,
      ),
    ];
    final stepCards = <Widget>[
      for (final (i, step) in steps.indexed)
        if (isStepDone(step, issued))
          _DoneStep(key: Key("add_step_$i"), step: step, issued: issued)
        else if (i == current)
          _CurrentStep(
            key: Key("add_step_$i"),
            sessionId: sessionId,
            index: i,
            step: step,
            selected: selected,
            issued: issued,
            requestor: requestor,
            wrong: state.wrongCredentialIssued,
          )
        else
          _LaterStep(key: Key("add_step_$i"), number: i + 1, step: step),
    ];
    final bar = action == null
        ? null
        : _AddBar(
            action: action,
            onAdd: (d) => _add(context, ref, d),
            onClose: onClose,
          );

    // Tablets: the question and who asks on the left, the steps and the
    // button on the right.
    if (useSessionColumns(context)) {
      return SessionScaffold(
        appBarTitle: "share.add_data.bar",
        onDismiss: onDismiss,
        wide: true,
        scrollsUnderBars: true,
        barTitleVisibility: hiddenBarTitle,
        body: SessionColumns(
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [SessionColumnsTitle(t("share.add_data.bar")), ...header],
          ),
          end: Column(
            key: const Key("add_missing_data_list"),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: stepCards,
          ),
          actions: bar,
        ),
      );
    }

    final children = [...header, ...stepCards];
    return SessionScaffold(
      appBarTitle: "share.add_data.bar",
      onDismiss: onDismiss,
      scrollsUnderBars: true,
      bottomNavigationBar: bar,
      body: Builder(
        builder: (context) => ListView(
          key: const Key("add_missing_data_list"),
          padding: BarInsets.of(
            context,
            const EdgeInsets.fromLTRB(16, 16, 16, 24),
          ),
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: 14),
              child,
            ],
          ],
        ),
      ),
    );
  }

  /// Sends the user to the issuer of [d]. The in-app flows (e-mail, phone,
  /// documents) show a band that leads back here while it is set.
  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    CredentialDescriptor d,
  ) async {
    ref
        .read(missingDataFlowProvider.notifier)
        .start(sessionId: sessionId, credentialId: d.credentialId);
    await ref.read(issuerOpenerProvider)(context, d, ref);
  }
}

String _bundleName(IssuanceBundle b) =>
    b.credentials.map((c) => c.name).join(" + ");

String _issuers(IssuanceBundle b) =>
    b.credentials.map((c) => c.issuer.name).toSet().join(", ");

class _CurrentStep extends ConsumerWidget {
  final int sessionId;
  final int index;
  final IssuanceStep step;
  final int selected;
  final Set<String> issued;
  final String requestor;
  final schemaless.Credential? wrong;

  const _CurrentStep({
    super.key,
    required this.sessionId,
    required this.index,
    required this.step,
    required this.selected,
    required this.issued,
    required this.requestor,
    required this.wrong,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final language = FlutterI18n.currentLocale(context)?.languageCode;
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    final multi = step.options.length > 1;
    final bundle = step.options[selected.clamp(0, step.options.length - 1)];

    final title = multi
        ? t("share.add_data.which")
        : t("share.add_data.title", {
            "name": inSentence(_bundleName(bundle), language: language),
          });
    final subtitle = multi
        ? t("share.add_data.accepts_any", {"requestor": requestor})
        : bundle.credentials.length > 1
        ? t("share.add_data.only_together")
        : t("share.add_data.from", {"issuer": _issuers(bundle)});

    // What the request needs exactly, from the requested values.
    final required = [
      for (final c in bundle.credentials)
        for (final a in c.attributes)
          if (a.requestedValue?.hasConcreteValue ?? false)
            (
              a.effectiveDisplayName,
              localizedAttributeText(context, a.requestedValue) ?? "",
            ),
    ];
    final mismatch = wrong == null
        ? null
        : issuanceMismatches(
            [wrong!],
            [
              IssuanceStep(options: [bundle]),
            ],
          ).firstOrNull;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: palette.display(17).copyWith(color: palette.text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                subtitle,
                style: palette
                    .body(13.5)
                    .copyWith(height: 20 / 13.5, color: palette.secondaryText),
              ),
            ),
            for (final (j, option) in step.options.indexed) ...[
              if (j > 0)
                Divider(height: 1, thickness: 1, color: palette.divider),
              _OptionRow(
                key: Key("add_option_${index}_$j"),
                bundle: option,
                radio: multi,
                selected: j == selected,
                onTap: multi && canBeAddedBundle(option)
                    ? () => ref
                          .read(
                            issueDuringDisclosureProvider(sessionId).notifier,
                          )
                          .selectOption(index, j)
                    : null,
              ),
            ],
            if (bundle.credentials.length > 1)
              _Checklist(bundle: bundle, issued: issued),
            for (final (label, value) in required)
              _RequiredRow(
                label: label,
                value: t("share.add_data.must_be", {"value": value}),
              ),
            if (mismatch != null) ...[
              const SizedBox(height: 8),
              _Note(
                text: t("share.add_data.wrong_note", {"requestor": requestor}),
                background: palette.errorSurface,
                foreground: palette.errorText,
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: _Compare(
                      label: t("share.add_data.you_added"),
                      value:
                          localizedAttributeText(context, mismatch.offered) ??
                          "–",
                      background: palette.background,
                      foreground: palette.errorText,
                    ),
                  ),
                  Expanded(
                    child: _Compare(
                      label: t("share.add_data.needed"),
                      value:
                          localizedAttributeText(context, mismatch.required) ??
                          "",
                      background: palette.successSurface,
                      foreground: palette.successText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One option of a step: its cards, name and where it is added. A radio
/// row when there is a choice.
class _OptionRow extends StatelessWidget {
  final IssuanceBundle bundle;
  final bool radio;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionRow({
    super.key,
    required this.bundle,
    required this.radio,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final addable = canBeAddedBundle(bundle);
    final subtitle = addable
        ? FlutterI18n.translate(
            context,
            "share.sheet.on_host",
            translationParams: {
              "issuer": _issuers(bundle),
              "host": hostOf(bundle.credentials.first.issueURL)!,
            },
          )
        : FlutterI18n.translate(context, "share.add_data.cant_be_added");

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          ExcludeSemantics(child: _MiniCards(bundle: bundle)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bundleName(bundle),
                  style: palette
                      .body(15, weight: FontWeight.w600)
                      .copyWith(
                        color: addable || !radio
                            ? palette.text
                            : palette.secondaryText,
                      ),
                ),
                Text(
                  subtitle,
                  style: palette
                      .body(12.5)
                      .copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
          if (radio) _Radio(selected: selected, enabled: addable),
        ],
      ),
    );

    if (!radio) return row;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: addable,
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _MiniCards extends StatelessWidget {
  final IssuanceBundle bundle;

  const _MiniCards({required this.bundle});

  @override
  Widget build(BuildContext context) {
    const w = SharedCardTile.miniWidth;
    final cards = bundle.credentials;
    return SizedBox(
      width: w + (cards.length - 1) * 20,
      height: w * 226 / 358 + (cards.length - 1) * 6,
      child: Stack(
        children: [
          for (final (i, d) in cards.indexed)
            Positioned(
              left: i * 20.0,
              top: i * 6.0,
              child: CredentialCardArt(credential: _exampleCard(d), width: w),
            ),
        ],
      ),
    );
  }

  static schemaless.Credential _exampleCard(CredentialDescriptor d) =>
      schemaless.Credential(
        credentialId: d.credentialId,
        hash: d.credentialId,
        name: d.name,
        issuer: d.issuer,
        image: d.image,
        credentialInstanceIds: const {},
        batchInstanceCountsRemaining: const {},
        attributes: const [],
        revoked: false,
        revocationSupported: false,
        issueUrl: d.issueURL,
      );
}

class _Radio extends StatelessWidget {
  final bool selected;
  final bool enabled;

  const _Radio({required this.selected, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? palette.primary : palette.outline,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: selected
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primary,
                ),
              )
            : null,
      ),
    );
  }
}

/// The cards of a set that are added one by one: which are in, which next.
class _Checklist extends StatelessWidget {
  final IssuanceBundle bundle;
  final Set<String> issued;

  const _Checklist({required this.bundle, required this.issued});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final next = bundle.credentials
        .where((c) => !issued.contains(c.credentialId))
        .firstOrNull;
    return Container(
      key: const Key("add_checklist"),
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: ShapeDecoration(
        color: palette.background,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              FlutterI18n.translate(context, "share.add_data.one_by_one"),
              style: palette
                  .body(12.5, weight: FontWeight.w700)
                  .copyWith(color: palette.secondaryText),
            ),
          ),
          for (final c in bundle.credentials)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                spacing: 10,
                children: [
                  Icon(
                    issued.contains(c.credentialId)
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: issued.contains(c.credentialId)
                        ? palette.successText
                        : palette.outline,
                  ),
                  Expanded(
                    child: Text(
                      c.name,
                      style: palette
                          .body(14, weight: FontWeight.w600)
                          .copyWith(color: palette.text),
                    ),
                  ),
                  Text(
                    FlutterI18n.translate(
                      context,
                      issued.contains(c.credentialId)
                          ? "share.add_data.state_added"
                          : c == next
                          ? "share.add_data.state_next"
                          : "share.add_data.state_to_add",
                    ),
                    style: palette
                        .body(13)
                        .copyWith(
                          color: issued.contains(c.credentialId)
                              ? palette.successText
                              : palette.secondaryText,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RequiredRow extends StatelessWidget {
  final String label;
  final String value;

  const _RequiredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: palette.body(14).copyWith(color: palette.secondaryText),
            ),
          ),
          Text(
            value,
            style: palette
                .body(14, weight: FontWeight.w600)
                .copyWith(color: palette.successText),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Note({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key("add_wrong_note"),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          color: background,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        child: Text(
          text,
          style: palette
              .body(13, weight: FontWeight.w600)
              .copyWith(height: 19 / 13, color: foreground),
        ),
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color foreground;

  const _Compare({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: ShapeDecoration(
        color: background,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: palette
                .body(12, weight: FontWeight.w700)
                .copyWith(color: foreground),
          ),
          Text(
            value,
            style: palette
                .body(15, weight: FontWeight.w700)
                .copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// A step that is in place: its card and "Added".
class _DoneStep extends StatelessWidget {
  final IssuanceStep step;
  final Set<String> issued;

  const _DoneStep({super.key, required this.step, required this.issued});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final done = step.options.firstWhere(
      (b) => b.credentials.every((c) => issued.contains(c.credentialId)),
    );
    return GlassSurface(
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        spacing: 12,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 26,
            color: palette.successText,
          ),
          Expanded(
            child: Text(
              _bundleName(done),
              style: palette
                  .body(14.5, weight: FontWeight.w600)
                  .copyWith(color: palette.text),
            ),
          ),
          Text(
            FlutterI18n.translate(context, "share.add_data.state_added"),
            style: palette
                .body(13, weight: FontWeight.w600)
                .copyWith(color: palette.successText),
          ),
        ],
      ),
    );
  }
}

/// A step after the current one: its number and what it asks for.
class _LaterStep extends StatelessWidget {
  final int number;
  final IssuanceStep step;

  const _LaterStep({super.key, required this.number, required this.step});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final or = FlutterI18n.translate(context, "share.or");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: palette.outline, width: 1.5),
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.outline, width: 2),
            ),
            child: Text(
              "$number",
              style: palette.display(13).copyWith(color: palette.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              step.options.map(_bundleName).join(or),
              style: palette
                  .body(14.5, weight: FontWeight.w600)
                  .copyWith(color: palette.secondaryText),
            ),
          ),
          Text(
            FlutterI18n.translate(context, "share.add_data.state_next"),
            style: palette.body(13).copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// The one button: add the selected card, or close when nothing can be
/// added, with why above it and where it goes below it.
class _AddBar extends StatelessWidget {
  final AddAction action;
  final ValueChanged<CredentialDescriptor> onAdd;
  final VoidCallback onClose;

  const _AddBar({
    required this.action,
    required this.onAdd,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final language = FlutterI18n.currentLocale(context)?.languageCode;
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);

    final (String? reason, Widget button, String? below) = switch (action) {
      AddCredential(:final descriptor, :final again, :final host) => (
        null,
        FancyPillButton(
          label: again
              ? t("share.add_data.button_add_again")
              : t("share.add_data.button_add", {
                  "name": inSentence(descriptor.name, language: language),
                }),
          onPressed: () => onAdd(descriptor),
        ),
        t("share.add_data.opens", {"host": host}),
      ),
      PickAddable() => (
        t("share.add_data.reason_pick"),
        FancyPillButton(
          label: t("share.add_data.button_add_plain"),
          onPressed: null,
        ),
        null,
      ),
      CloseCannotAdd(:final issuers, :final name) => (
        t("share.add_data.reason_cant", {
          "name": inSentence(name, language: language),
          "issuer": issuers.join(", "),
        }),
        PillButton(label: t("share.button.close"), onPressed: onClose),
        null,
      ),
    };

    return IrmaBottomBarBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (reason != null)
            Text(
              reason,
              key: const Key("add_reason"),
              textAlign: TextAlign.center,
              style: palette
                  .body(13.5)
                  .copyWith(height: 19 / 13.5, color: palette.heading),
            ),
          KeyedSubtree(key: const Key("add_button"), child: button),
          if (below != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: palette.secondaryText,
                ),
                Text(
                  below,
                  style: palette
                      .body(12.5)
                      .copyWith(color: palette.secondaryText),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
