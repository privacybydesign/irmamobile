import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/bold_markers_text.dart";
import "../../../widgets/link.dart";
import "../../../widgets/requestor_verification_explanation_bottom_sheet.dart";
import "requestor_host.dart";

const _barRadius = 12.0;

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

    return Container(
      width: double.infinity,
      padding: .all(theme.defaultSpacing),
      decoration: BoxDecoration(
        color: requestor.verified ? theme.successSurface : theme.errorSurface,
        borderRadius: BorderRadius.circular(_barRadius),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: theme.tinySpacing,
        children: [
          BoldMarkersText(
            requestor.verified
                ? "disclosure_permission.share_v2.trust_known"
                : "disclosure_permission.share_v2.trust_unknown",
            translationParams: {"requestorName": name},
            style: theme.textTheme.bodyMedium,
          ),
          Link(
            label:
                "disclosure_permission.overview.requestor_verification.explanation",
            onTap: () => showVerificationSheet(context),
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
