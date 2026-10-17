import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/glass_surface.dart";
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
  heightFraction: 0.9,
  builder: (_) => ChangeChoiceSheet(
    key: const Key("disclosure_choice_sheet"),
    sessionId: sessionId,
    index: index,
    addNew: addNew,
  ),
);

/// The hero tag of [bundle] as the choice for pick-one [index]: the card on
/// the share screen and the same card in the sheet, so the chosen card flies
/// into the sheet and the picked one back.
Object choiceHeroTag(int sessionId, int index, DisclosureBundle bundle) => (
  "disclosure_choice",
  sessionId,
  index,
  bundle.credentials.map((c) => c.hash).join("+"),
);

/// A card flying between the share screen and the sheet: the destination
/// card without its "Change" pill or selection outline, which appear once it
/// has landed, on a transparent material so its text and ink have one.
///
/// The flight's box goes from the size of one card to the other; the card
/// keeps its own height in it, so two that differ a little (an
/// optional card has its leave-out button) do not overflow on the way.
Widget choiceHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) => Material(
  type: MaterialType.transparency,
  child: OverflowBox(
    alignment: Alignment.topCenter,
    minHeight: 0,
    maxHeight: double.infinity,
    child: SharedCardTileInFlight(child: (toContext.widget as Hero).child),
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

  void _openAdd(CredentialDescriptor d) => setState(() => _adding = d);

  void _back() => setState(() => _adding = null);

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
    // "Add …" is a subpage inside the sheet, as in a native iOS sheet.
    return GlassSheetPages(
      onBack: _back,
      pages: [
        KeyedSubtree(
          key: const ValueKey("choose"),
          child: _buildChoose(pickOne),
        ),
        if (adding != null)
          KeyedSubtree(
            key: ValueKey(("add", adding.credentialId)),
            child: _buildAdd(pickOne, adding),
          ),
      ],
    );
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

    return GlassSheetPage(
      title: title,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Room for the selection outline around a card.
        spacing: 12,
        children: [
          _Intro(
            owned.isEmpty
                ? t("share.sheet.subtitle_add")
                : t("share.sheet.subtitle"),
          ),
          if (owned.isNotEmpty) ...[
            _Label(t("share.in_your_app")),
            for (final (k, b) in owned.indexed)
              Hero(
                tag: choiceHeroTag(widget.sessionId, widget.index, b),
                flightShuttleBuilder: choiceHeroShuttle,
                // Also back into the overview when the sheet is dragged closed.
                transitionOnUserGestures: true,
                child: _OwnedCard(
                  key: Key("sheet_owned_${b.credentials.first.hash}"),
                  bundle: b,
                  selected: k == selected,
                  onTap: () => _pick(pickOne, b),
                ),
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
                    onTap: () => _openAdd(d),
                  ),
              ],
            ),
          ],
        ],
      ),
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

    return GlassSheetPage(
      title: t("share.sheet.add_title", {
        "name": inSentence(
          d.name,
          language: FlutterI18n.currentLocale(context)?.languageCode,
        ),
      }),
      onBack: _back,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // The way on, at the bottom of the sheet as on a full screen.
      bottom: KeyedSubtree(
        key: const Key("sheet_go_button"),
        child: FancyPillButton(
          label: t("share.sheet.go_to", {"host": host}),
          onPressed: () => _go(pickOne, d),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          _Intro(t("share.sheet.add_subtitle")),
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
        ],
      ),
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

/// The text under a sheet's title, at the top of its scrolling content.
class _Intro extends StatelessWidget {
  final String text;

  const _Intro(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: palette
            .body(15)
            .copyWith(height: 21 / 15, color: palette.secondaryText),
      ),
    );
  }
}

/// A card in the app, drawn as on the share screen with every value it
/// would share: tap to use it. The one in use has the outline of the current
/// card on the credential's page, drawn just outside the card so it keeps the
/// share screen's size (and hidden while the card flies).
class _OwnedCard extends StatelessWidget {
  final DisclosureBundle bundle;
  final bool selected;
  final VoidCallback onTap;

  const _OwnedCard({
    super.key,
    required this.bundle,
    required this.selected,
    required this.onTap,
  });

  /// The outline's 2 pt line, 3 pt from the card, as on the credential page.
  static const _ring = 2.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final outlined = selected && !SharedCardTileInFlight.of(context);
    const out = -(_ring + _gap);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: PressScale(
        scale: 0.98,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SharedCardTile(bundle: bundle),
              if (outlined)
                Positioned(
                  left: out,
                  top: out,
                  right: out,
                  bottom: out,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(24 + _ring + _gap),
                          ),
                          side: BorderSide(
                            color: palette.primary,
                            width: _ring,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
