import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "session_requestor_header.dart";

const _portalOrganisations = "https://portal.yivi.app/organizations";
const _portal = "https://portal.yivi.app";
const _euTrustedList =
    "https://eidas.ec.europa.eu/efda/trust-services/browse/eidas/tls";

/// What it means that [requestor] is (or is not) vouched for: the trust
/// sheet, opened from the requestor card and from the warning banner.
///
/// [onDontShare] is "Don't share" for a party nobody vouches for: it closes
/// the request.
Future<void> showRequestorTrustSheet({
  required BuildContext context,
  required TrustedParty requestor,
  VoidCallback? onDontShare,
}) => showGlassSheet<void>(
  context: context,
  heightFraction: 0.85,
  builder: (_) => RequestorTrustSheet(
    key: const Key("requestor_trust_sheet"),
    requestor: requestor,
    onDontShare: onDontShare,
  ),
);

/// The trust sheet, made to be read at a glance: no title text, the party's
/// logo with its badge, a verdict and one sentence, three facts (✓ in the
/// tier's colour, ✗ red, ⓘ neutral), then what is good to know or what you
/// can do.
class RequestorTrustSheet extends StatelessWidget {
  final TrustedParty requestor;
  final VoidCallback? onDontShare;

  const RequestorTrustSheet({
    super.key,
    required this.requestor,
    this.onDontShare,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = RequestorTrustStyle.of(context, requestor);
    final name = requestor.name;
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    void open(String url) => IrmaRepositoryProvider.of(context).openURL(url);

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
        t("share.trust.sheet.yivi.head"),
        t("share.trust.sheet.yivi.body", params),
        [
          _Fact.yes(t("share.trust.sheet.yivi.fact_checked")),
          _Fact.yes(t("share.trust.sheet.yivi.fact_verified")),
          _Fact.yes(t("share.trust.sheet.yivi.fact_listed")),
        ],
      ),
      RequestorTrust.elsewhere => (
        t("share.trust.sheet.elsewhere.head_$elsewhereKey", params),
        t("share.trust.sheet.elsewhere.body_$elsewhereKey", params),
        [
          _Fact.yes(
            t("share.trust.sheet.elsewhere.fact_checked_$elsewhereKey", params),
          ),
          _Fact.yes(t("share.trust.sheet.elsewhere.fact_name")),
          _Fact.info(t("share.trust.sheet.elsewhere.fact_not_yivi")),
        ],
      ),
      _ => (
        t("share.trust.sheet.unknown.head"),
        t("share.trust.sheet.unknown.body", params),
        [
          _Fact.no(t("share.trust.sheet.unknown.fact_unchecked")),
          _Fact.no(t("share.trust.sheet.unknown.fact_self")),
          _Fact.no(t("share.trust.sheet.unknown.fact_responsibility")),
        ],
      ),
    };

    final decide = _Do(
      icon: Icons.shield_outlined,
      title: t("share.trust.sheet.do.decide"),
      subtitle: t("share.trust.sheet.do.decide_text"),
    );
    final (String doLabel, List<_Do> dos) = switch (style.trust) {
      RequestorTrust.yivi => (
        t("share.trust.sheet.do.good_to_know"),
        [
          decide,
          _Do(
            key: const Key("trust_sheet_portal"),
            icon: Icons.open_in_new_rounded,
            title: t("share.trust.sheet.do.portal"),
            subtitle: t("share.trust.sheet.do.portal_text"),
            onTap: () => open(_portalOrganisations),
          ),
        ],
      ),
      RequestorTrust.elsewhere => (
        t("share.trust.sheet.do.good_to_know"),
        [
          decide,
          if (source == ElsewhereSource.euTrustedList)
            _Do(
              key: const Key("trust_sheet_eu_list"),
              icon: Icons.open_in_new_rounded,
              title: t("share.trust.sheet.do.eu_list"),
              subtitle: t("share.trust.sheet.do.eu_list_text"),
              onTap: () => open(_euTrustedList),
            ),
        ],
      ),
      _ => (
        t("share.trust.sheet.do.unsure"),
        [
          _Do(
            key: const Key("trust_sheet_dont_share"),
            icon: Icons.shield_outlined,
            title: t("share.trust.sheet.do.dont_share"),
            subtitle: t("share.trust.sheet.do.dont_share_text"),
            onTap: onDontShare == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onDontShare!();
                  },
          ),
          _Do(
            icon: Icons.call_outlined,
            title: t("share.trust.sheet.do.contact", params),
            subtitle: t("share.trust.sheet.do.contact_text"),
          ),
          _Do(
            key: const Key("trust_sheet_register"),
            icon: Icons.open_in_new_rounded,
            title: t("share.trust.sheet.do.register"),
            subtitle: t("share.trust.sheet.do.register_text"),
            onTap: () => open(_portal),
          ),
        ],
      ),
    };

    return Semantics(
      // The bar has no title: the verdict is the heading. Screen readers
      // still hear what the sheet is.
      label: t("share.trust.sheet.name"),
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: GlassSheetPage(
        title: "",
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ExcludeSemantics(
                    child: SessionRequestorHeader.avatarOf(requestor, size: 84),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: RequestorTrustBadge(style: style, size: 36),
                  ),
                ],
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
                    .copyWith(height: 30 / 22, color: palette.heading),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: palette
                  .body(15)
                  .copyWith(height: 22 / 15, color: palette.secondaryText),
            ),
            const SizedBox(height: 18),
            _Group(
              children: [
                for (final f in facts) _FactRow(fact: f, style: style),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 22, 6, 8),
              child: Semantics(
                header: true,
                child: Text(
                  doLabel.toUpperCase(),
                  style: palette
                      .body(12.5, weight: FontWeight.w700)
                      .copyWith(
                        letterSpacing: 0.6,
                        color: palette.secondaryText,
                      ),
                ),
              ),
            ),
            _Group(children: [for (final d in dos) _DoRow(item: d)]),
          ],
        ),
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
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: tile,
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              child: Icon(icon, size: 20, color: ink),
            ),
          ),
          Expanded(
            child: Text(
              fact.text,
              style: palette
                  .body(15, weight: FontWeight.w600)
                  .copyWith(height: 21 / 15, color: palette.heading),
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
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: palette.tint,
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              child: Icon(item.icon, size: 20, color: palette.link),
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
                      .copyWith(height: 21 / 15, color: palette.heading),
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
