import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/icon_square.dart";
import "../models/technical_details.dart";
import "session_requestor_header.dart";
import "technical_details_sheet.dart";

const _portalOrganisations = "https://portal.yivi.app/organizations";
const _portal = "https://portal.yivi.app";
const _euTrustedList =
    "https://eidas.ec.europa.eu/efda/trust-services/browse/eidas/tls";

/// What it means that [requestor] is (or is not) vouched for: the trust
/// sheet, opened from the requestor card and from the warning banner.
///
/// [onDontShare] is "Don't share" for a party nobody vouches for: it closes
/// the request. With [technicalDetails] the sheet ends with a row that opens
/// them, as a subpage of the sheet.
Future<void> showRequestorTrustSheet({
  required BuildContext context,
  required TrustedParty requestor,
  VoidCallback? onDontShare,
  List<TechGroup>? technicalDetails,
}) => showGlassSheet<void>(
  context: context,
  builder: (_) => _TrustSheetPages(
    requestor: requestor,
    onDontShare: onDontShare,
    technicalDetails: technicalDetails,
  ),
);

/// The trust sheet and, when there are technical details, their subpage,
/// which slides in over it.
class _TrustSheetPages extends StatefulWidget {
  final TrustedParty requestor;
  final VoidCallback? onDontShare;
  final List<TechGroup>? technicalDetails;

  const _TrustSheetPages({
    required this.requestor,
    this.onDontShare,
    this.technicalDetails,
  });

  @override
  State<_TrustSheetPages> createState() => _TrustSheetPagesState();
}

class _TrustSheetPagesState extends State<_TrustSheetPages> {
  var _tech = false;

  @override
  Widget build(BuildContext context) {
    final groups = widget.technicalDetails;
    return GlassSheetPages(
      onBack: () => setState(() => _tech = false),
      pages: [
        RequestorTrustSheet(
          key: const Key("requestor_trust_sheet"),
          requestor: widget.requestor,
          onDontShare: widget.onDontShare,
          onTechnicalDetails: groups == null
              ? null
              : () => setState(() => _tech = true),
        ),
        if (_tech && groups != null)
          TechnicalDetailsSheet(
            key: const Key("technical_details_sheet"),
            groups: groups,
            onBack: () => setState(() => _tech = false),
          ),
      ],
    );
  }
}

/// The trust sheet, made to be read at a glance: no title text, the party's
/// logo with its badge, a verdict and one sentence, three facts (✓ in the
/// tier's colour, ✗ red, ⓘ neutral), then what is good to know or what you
/// can do.
class RequestorTrustSheet extends StatelessWidget {
  final TrustedParty requestor;
  final VoidCallback? onDontShare;

  /// Opens the technical details of the request (a subpage); no row for
  /// them when null.
  final VoidCallback? onTechnicalDetails;

  const RequestorTrustSheet({
    super.key,
    required this.requestor,
    this.onDontShare,
    this.onTechnicalDetails,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = RequestorTrustStyle.of(context, requestor);
    final name = requestor.name;
    void open(String url) => IrmaRepositoryProvider.of(context).openURL(url);
    final sideways = useSheetColumns(context);

    final anchor = requestor.trustAnchor ?? "";
    final source = elsewhereSourceOf(requestor);
    final elsewhereKey = switch (source) {
      ElsewhereSource.euTrustedList => "eu",
      ElsewhereSource.namedAnchor => "anchor",
      ElsewhereSource.unspecified => "confirmed",
    };
    final params = {"requestor": name, "anchor": anchor};

    final (String head, String body, List<_Fact> facts) = switch (style.trust) {
      RequestorTrust.yivi => (
        context.tr("share.trust.sheet.yivi.head"),
        context.tr("share.trust.sheet.yivi.body", params),
        [
          _Fact.yes(context.tr("share.trust.sheet.yivi.fact_checked")),
          _Fact.yes(context.tr("share.trust.sheet.yivi.fact_verified")),
          _Fact.yes(context.tr("share.trust.sheet.yivi.fact_listed")),
        ],
      ),
      RequestorTrust.elsewhere => (
        context.tr("share.trust.sheet.elsewhere.head_$elsewhereKey", params),
        context.tr("share.trust.sheet.elsewhere.body_$elsewhereKey", params),
        [
          _Fact.yes(
            context.tr(
              "share.trust.sheet.elsewhere.fact_checked_$elsewhereKey",
              params,
            ),
          ),
          _Fact.yes(context.tr("share.trust.sheet.elsewhere.fact_name")),
          _Fact.info(context.tr("share.trust.sheet.elsewhere.fact_not_yivi")),
        ],
      ),
      _ => (
        context.tr("share.trust.sheet.unknown.head"),
        context.tr("share.trust.sheet.unknown.body", params),
        [
          _Fact.no(context.tr("share.trust.sheet.unknown.fact_unchecked")),
          _Fact.no(context.tr("share.trust.sheet.unknown.fact_self")),
          _Fact.no(context.tr("share.trust.sheet.unknown.fact_responsibility")),
        ],
      ),
    };

    final decide = _Do(
      icon: Icons.shield_outlined,
      title: context.tr("share.trust.sheet.do.decide"),
      subtitle: context.tr("share.trust.sheet.do.decide_text"),
    );
    final (String doLabel, List<_Do> dos) = switch (style.trust) {
      RequestorTrust.yivi => (
        context.tr("share.trust.sheet.do.good_to_know"),
        [
          decide,
          _Do(
            key: const Key("trust_sheet_portal"),
            icon: Icons.open_in_new_rounded,
            title: context.tr("share.trust.sheet.do.portal"),
            subtitle: context.tr("share.trust.sheet.do.portal_text"),
            onTap: () => open(_portalOrganisations),
          ),
        ],
      ),
      RequestorTrust.elsewhere => (
        context.tr("share.trust.sheet.do.good_to_know"),
        [
          decide,
          if (source == ElsewhereSource.euTrustedList)
            _Do(
              key: const Key("trust_sheet_eu_list"),
              icon: Icons.open_in_new_rounded,
              title: context.tr("share.trust.sheet.do.eu_list"),
              subtitle: context.tr("share.trust.sheet.do.eu_list_text"),
              onTap: () => open(_euTrustedList),
            ),
        ],
      ),
      _ => (
        context.tr("share.trust.sheet.do.unsure"),
        [
          _Do(
            key: const Key("trust_sheet_dont_share"),
            icon: Icons.shield_outlined,
            title: context.tr("share.trust.sheet.do.dont_share"),
            subtitle: context.tr("share.trust.sheet.do.dont_share_text"),
            onTap: onDontShare == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onDontShare!();
                  },
          ),
          _Do(
            icon: Icons.call_outlined,
            title: context.tr("share.trust.sheet.do.contact", params),
            subtitle: context.tr("share.trust.sheet.do.contact_text"),
          ),
          _Do(
            key: const Key("trust_sheet_register"),
            icon: Icons.open_in_new_rounded,
            title: context.tr("share.trust.sheet.do.register"),
            subtitle: context.tr("share.trust.sheet.do.register_text"),
            onTap: () => open(_portal),
          ),
        ],
      ),
    };

    return Semantics(
      // The bar has no title: the verdict is the heading. Screen readers
      // still hear what the sheet is.
      label: context.tr("share.trust.sheet.name"),
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: GlassSheetPage(
        title: "",
        // No bar once scrolled either: only the close button floats.
        edge: false,
        // Held sideways the columns scroll each on their own.
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        split: sideways,
        child: _columns(
          context,
          [
            // The card's logo flies in here.
            Center(
              child: RequestorLogo(
                requestor: requestor,
                style: style,
                size: 84,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                head,
                key: const Key("trust_sheet_head"),
                textAlign: TextAlign.center,
                style: palette
                    .display(22, weight: FontWeight.w700)
                    .copyWith(height: 30 / 22, color: palette.text),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: palette
                  .body(15)
                  .copyWith(height: 22 / 15, color: palette.heading),
            ),
          ],
          [
            _Group(
              children: [
                for (final f in facts) _FactRow(fact: f, style: style),
              ],
            ),
            CapsLabel(doLabel, padding: const EdgeInsets.fromLTRB(6, 22, 6, 8)),
            _Group(children: [for (final d in dos) _DoRow(item: d)]),
            // For the curious, last and out of the way.
            if (onTechnicalDetails case final open?) ...[
              const SizedBox(height: 22),
              _Group(
                children: [
                  _DoRow(
                    item: _Do(
                      key: const Key("trust_sheet_technical_details"),
                      icon: Icons.code_rounded,
                      title: context.tr("share.tech.link"),
                      subtitle: context.tr("share.tech.link_text"),
                      onTap: open,
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

  /// Who it is ([who]: logo, verdict, sentence) above the facts and what to
  /// do ([facts]); on a phone held sideways who it is at the left and the
  /// rest at the right, each column scrolling on its own.
  static Widget _columns(
    BuildContext context,
    List<Widget> who,
    List<Widget> facts,
  ) {
    if (!useSheetColumns(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...who, const SizedBox(height: 18), ...facts],
      );
    }
    return SheetSplit(
      startWidth: 260,
      start: who,
      end: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: facts,
      ),
    );
  }
}

enum _FactKind { yes, no, info }

class _Fact {
  final String text;
  final _FactKind kind;

  const _Fact.yes(this.text) : kind = _FactKind.yes;
  const _Fact.no(this.text) : kind = _FactKind.no;
  const _Fact.info(this.text) : kind = _FactKind.info;
}

class _Do {
  final Key? key;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Do({
    this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

/// White rounded group of rows, with lines between them.
class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: YiviShadows.surfaceCard(palette),
      // A row's press highlight paints here, over the white card and within
      // its corners.
      child: Material(
        type: MaterialType.transparency,
        shape: const RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 66,
                  color: palette.divider,
                ),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final _Fact fact;
  final RequestorTrustStyle style;

  const _FactRow({required this.fact, required this.style});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (IconData icon, Color ink, Color tile) = switch (fact.kind) {
      _FactKind.yes => (
        Icons.check_rounded,
        style.badge ?? palette.successText,
        style.pillFill,
      ),
      _FactKind.no => (
        Icons.close_rounded,
        palette.danger,
        palette.errorSurface,
      ),
      _FactKind.info => (
        Icons.info_outline_rounded,
        palette.secondaryText,
        palette.tint,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 14,
        children: [
          ExcludeSemantics(
            child: IconSquare(icon: icon, fill: tile, ink: ink),
          ),
          Expanded(
            child: Text(
              fact.text,
              style: palette
                  .body(15, weight: FontWeight.w600)
                  .copyWith(height: 21 / 15, color: palette.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoRow extends StatelessWidget {
  final _Do item;

  const _DoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tap = item.onTap;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 14,
        children: [
          ExcludeSemantics(
            child: IconSquare(
              icon: item.icon,
              fill: palette.tint,
              ink: palette.link,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: palette
                      .body(15, weight: FontWeight.w600)
                      .copyWith(height: 21 / 15, color: palette.text),
                ),
                Text(
                  item.subtitle,
                  style: palette
                      .body(13)
                      .copyWith(height: 18 / 13, color: palette.secondaryText),
                ),
              ],
            ),
          ),
          if (tap != null)
            Icon(Icons.chevron_right_rounded, size: 22, color: palette.faint),
        ],
      ),
    );
    if (tap == null) return KeyedSubtree(key: item.key, child: row);
    return Semantics(
      button: true,
      child: InkWell(key: item.key, onTap: tap, child: row),
    );
  }
}
