import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/disclosed_card_tile.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../models/disclosure_view_model.dart";
import "shared_card_tile.dart";

/// Sends the user to the issuer of a credential type: its website, or the
/// app's own flow for the types Yivi issues itself (e-mail, phone,
/// documents). A provider, so tests can see where the sheet sends the user.
final issuerOpenerProvider =
    Provider<
      Future<void> Function(
        BuildContext context,
        CredentialDescriptor descriptor,
        WidgetRef ref,
      )
    >(
      (ref) =>
          (context, d, widgetRef) => ref
              .read(irmaRepositoryProvider)
              .openIssueURL(context, d.credentialId, d.issueURL, widgetRef),
    );

/// The "Change" sheet of the share screen, for pick-one [index]: the cards
/// in the app (one tap picks one and closes the sheet) and, clearly apart,
/// the types that are not in the app yet. Tapping one of those first says
/// where the user goes and that the card is selected when they come back,
/// then sends them to the issuer.
///
/// [addNew] opens it straight on that last step, for the "Add a new …"
/// button of a card that cannot be shared.
Future<void> showChangeChoiceSheet({
  required BuildContext context,
  required int sessionId,
  required int index,
  CredentialDescriptor? addNew,
}) => showGlassSheet<void>(
  context: context,
  builder: (_) => ChangeChoiceSheet(
    key: const Key("disclosure_choice_sheet"),
    sessionId: sessionId,
    index: index,
    addNew: addNew,
  ),
);

class ChangeChoiceSheet extends ConsumerStatefulWidget {
  final int sessionId;
  final int index;
  final CredentialDescriptor? addNew;

  const ChangeChoiceSheet({
    super.key,
    required this.sessionId,
    required this.index,
    this.addNew,
  });

  @override
  ConsumerState<ChangeChoiceSheet> createState() => _ChangeChoiceSheetState();
}

class _ChangeChoiceSheetState extends ConsumerState<ChangeChoiceSheet> {
  /// The type the user is about to add; null while choosing.
  late CredentialDescriptor? _adding = widget.addNew;

  SessionUserChoicesNotifier get _choices =>
      ref.read(sessionUserChoicesProvider(widget.sessionId).notifier);

  void _pick(DisclosurePickOne pickOne, DisclosureBundle bundle) {
    if (pickOne.optional) _choices.addOptional(widget.index);
    _choices.setBundle(widget.index, bundle);
    Navigator.of(context).pop();
  }

  Future<void> _go(DisclosurePickOne pickOne, CredentialDescriptor d) async {
    if (pickOne.optional) _choices.includeOptionalWhenAdded(widget.index);
    final open = ref.read(issuerOpenerProvider);
    final navigator = Navigator.of(context);
    // Opened from the page behind the sheet, which stays.
    final pageContext = navigator.context;
    navigator.pop();
    await open(pageContext, d, ref);
  }

  @override
  Widget build(BuildContext context) {
    // The plan changes while the sheet is open when a card is added.
    final session = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final pickOnes =
        session?.disclosurePlan?.disclosureChoicesOverview ?? const [];
    if (widget.index >= pickOnes.length) return const SizedBox.shrink();
    final pickOne = pickOnes[widget.index];
    final adding = _adding;
    return adding == null ? _buildChoose(pickOne) : _buildAdd(pickOne, adding);
  }

  Widget _buildChoose(DisclosurePickOne pickOne) {
    final choices = ref.watch(sessionUserChoicesProvider(widget.sessionId));
    final owned = pickOne.ownedOptions ?? const [];
    final addable = addableOptions(pickOne);
    final selections = selectionsFrom(
      [pickOne],
      {0: ?choices.disclosureChoices[widget.index]},
      {if (choices.addedOptionalIndices.contains(widget.index)) 0},
    );
    final selected =
        pickOne.optional && !choices.addedOptionalIndices.contains(widget.index)
        ? -1
        : selectionOf(pickOne, selections[0]);

    final names = {
      for (final b in owned) _nameOf(b),
      for (final d in addable) d.name,
    };
    final sameType = names.length == 1;
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);

    final title = pickOne.optional
        ? t("share.sheet.add_optional")
        : sameType
        ? t("share.sheet.which", {
            "name": inSentence(
              names.single,
              language: FlutterI18n.currentLocale(context)?.languageCode,
            ),
          })
        : t("share.sheet.what");

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSheetHeader(
          title: title,
          subtitle: owned.isEmpty
              ? t("share.sheet.subtitle_add")
              : t("share.sheet.subtitle"),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                if (owned.isNotEmpty) ...[
                  _Label(t("share.in_your_app")),
                  _Group(
                    children: [
                      for (final (k, b) in owned.indexed)
                        _OwnedRow(
                          key: Key("sheet_owned_${b.credentials.first.hash}"),
                          bundle: b,
                          sameType: sameType,
                          selected: k == selected,
                          onTap: () => _pick(pickOne, b),
                        ),
                    ],
                  ),
                ],
                if (addable.isNotEmpty) ...[
                  _Label(t("share.not_in_app_yet")),
                  _Group(
                    children: [
                      for (final d in addable)
                        _AddRow(
                          key: Key("sheet_add_${d.credentialId}"),
                          name: owned.any((b) => _nameOf(b) == d.name)
                              ? t("share.sheet.another", {
                                  "name": inSentence(
                                    d.name,
                                    language: FlutterI18n.currentLocale(
                                      context,
                                    )?.languageCode,
                                  ),
                                })
                              : d.name,
                          subtitle: t("share.sheet.on_host", {
                            "issuer": d.issuer.name,
                            "host": hostOf(d.issueURL)!,
                          }),
                          onTap: () => setState(() => _adding = d),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdd(DisclosurePickOne pickOne, CredentialDescriptor d) {
    final palette = YiviPalette.of(context);
    final host = hostOf(d.issueURL)!;
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            label,
            style: palette.body(14).copyWith(color: palette.secondaryText),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: palette
                  .body(14, weight: FontWeight.w600)
                  .copyWith(color: palette.text),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        GlassSheetHeader(
          title: t("share.sheet.add_title", {
            "name": inSentence(
              d.name,
              language: FlutterI18n.currentLocale(context)?.languageCode,
            ),
          }),
          subtitle: t("share.sheet.add_subtitle"),
          onBack: () => setState(() => _adding = null),
        ),
        Center(
          child: ExcludeSemantics(
            child: CredentialCardArt(credential: _exampleCard(d), width: 200),
          ),
        ),
        _Group(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          children: [
            row(t("share.sheet.from"), d.issuer.name),
            row(t("share.sheet.where"), host),
            row(t("share.sheet.afterwards"), t("share.sheet.selected_back")),
          ],
        ),
        KeyedSubtree(
          key: const Key("sheet_go_button"),
          child: FancyPillButton(
            label: t("share.sheet.go_to", {"host": host}),
            onPressed: () => _go(pickOne, d),
          ),
        ),
      ],
    );
  }

  static String _nameOf(DisclosureBundle b) =>
      b.credentials.map((c) => c.name).join(" + ");

  /// The card of type [d], drawn from the type alone.
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

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: palette
              .body(12.5, weight: FontWeight.w700)
              .copyWith(letterSpacing: 0.6, color: palette.secondaryText),
        ),
      ),
    );
  }
}

/// White rounded group of rows, with lines between them.
class _Group extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const _Group({
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: palette.divider),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A card in the app: tap to use it. Shown as a radio row.
class _OwnedRow extends ConsumerWidget {
  final DisclosureBundle bundle;
  final bool sameType;
  final bool selected;
  final VoidCallback onTap;

  const _OwnedRow({
    super.key,
    required this.bundle,
    required this.sameType,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final cards = bundle.credentials;
    final name = cards.map((c) => c.name).join(" + ");
    final issuers = cards.map((c) => c.issuer.name).toSet().join(", ");
    final value = _firstValue(bundle);
    final problem = problemOfBundle(bundle);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: SharedCardTile.miniWidth + (cards.length - 1) * 20,
                  height:
                      SharedCardTile.miniWidth * 226 / 358 +
                      (cards.length - 1) * 6,
                  child: Stack(
                    children: [
                      for (final (i, c) in cards.indexed)
                        Positioned(
                          left: i * 20.0,
                          top: i * 6.0,
                          child: CredentialCardArt(
                            credential: DisclosedCardTile.cardFor(c, wallet),
                            width: SharedCardTile.miniWidth,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sameType ? (value ?? name) : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette
                          .body(15, weight: FontWeight.w600)
                          .copyWith(color: palette.text),
                    ),
                    Text(
                      sameType || value == null ? issuers : "$value · $issuers",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette
                          .body(12.5)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
              if (problem != null)
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: palette.errorSurface,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      "share.problem.${switch (problem) {
                        CardProblem.revoked => "revoked",
                        CardProblem.usedUp => "used_up",
                        CardProblem.expired => "expired",
                      }}",
                    ),
                    style: palette
                        .body(12, weight: FontWeight.w700)
                        .copyWith(color: palette.errorText),
                  ),
                ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }

  /// The first shown value of the bundle, to tell instances of one type
  /// apart ("s.devries@werk.example").
  static String? _firstValue(DisclosureBundle bundle) {
    for (final c in bundle.credentials) {
      for (final a in c.attributes) {
        final v = a.value;
        if (v == null) continue;
        final text =
            v.string ?? v.intValue?.toString() ?? v.boolValue?.toString();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }
}

class _Radio extends StatelessWidget {
  final bool selected;

  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
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
    );
  }
}

/// A type that is not in the app yet: tap to see where it is added.
class _AddRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _AddRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: SharedCardTile.miniWidth,
                  height: SharedCardTile.miniWidth * 226 / 358,
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(9)),
                      side: BorderSide(color: palette.outline, width: 1.5),
                    ),
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: palette.link),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: palette
                          .body(15, weight: FontWeight.w600)
                          .copyWith(color: palette.text),
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
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
