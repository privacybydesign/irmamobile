import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/bold_markers_text.dart";
import "../../../widgets/link.dart";
import "../../../widgets/requestor_verification_explanation_bottom_sheet.dart";
import "requestor_host.dart";

const _barRadius = 12.0;
const _barGap = 12.0;
const _linkMaxShare = 0.5;
const _barTextSize = 16.0;
const _barTextHeight = 22 / _barTextSize;
const _stackFromTextScale = 1.3;

/// Says whether Yivi knows the requestor, above the share button.
class ShareTrustBar extends StatelessWidget {
  final TrustedParty requestor;

  const ShareTrustBar({super.key, required this.requestor});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final name = requestor.name.isNotEmpty
        ? requestor.name
        : requestorHost(requestor);

    final text = BoldMarkersText(
      requestor.verified
          ? "disclosure_permission.share_v2.trust_known"
          : "disclosure_permission.share_v2.trust_unknown",
      translationParams: {"requestorName": name},
      style: theme.textTheme.bodyMedium?.copyWith(height: _barTextHeight),
    );
    final link = Link(
      label:
          "disclosure_permission.overview.requestor_verification.explanation",
      onTap: () => showVerificationSheet(context),
      style: const TextStyle(
        fontWeight: FontWeight.w400,
        height: _barTextHeight,
      ),
    );

    return Container(
      width: double.infinity,
      padding: .all(theme.defaultSpacing),
      decoration: BoxDecoration(
        color: requestor.verified ? theme.successSurface : theme.errorSurface,
        borderRadius: BorderRadius.circular(_barRadius),
      ),
      child: _stacked(context)
          ? Column(
              crossAxisAlignment: .start,
              spacing: theme.tinySpacing,
              children: [text, link],
            )
          // The link keeps its width until it takes half the bar, then wraps.
          : LayoutBuilder(
              builder: (context, constraints) => Row(
                spacing: _barGap,
                children: [
                  Expanded(child: text),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _linkMaxShare,
                    ),
                    child: link,
                  ),
                ],
              ),
            ),
    );
  }

  // Beside large text the link gets a few characters per line, so it goes
  // under the text instead.
  bool _stacked(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_barTextSize) >
      _barTextSize * _stackFromTextScale;
}
