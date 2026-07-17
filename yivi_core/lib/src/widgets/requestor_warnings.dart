import "package:flutter/material.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "translated_text.dart";

/// Renders the non-blocking [SessionWarning]s reported for a requestor as
/// user-friendly warning boxes. Warnings without user-facing wording (an
/// [SessionWarning.unknown] value, or a code we deliberately don't surface) are
/// skipped, so the widget collapses to nothing when there is nothing to show.
class RequestorWarnings extends StatelessWidget {
  final List<SessionWarning> warnings;

  const RequestorWarnings({super.key, required this.warnings});

  // Translation key per warning we surface to the user. A warning missing from
  // this map is not shown. did_web_dnssec_missing is intentionally absent: it
  // fires for most verifier domains, so showing it on nearly every session
  // would be alarm fatigue rather than a useful signal.
  static const _translationKeys = <SessionWarning, String>{
    SessionWarning.didWebDnssecInvalid:
        "session.warning.did_web_dnssec_invalid",
  };

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final keys = warnings
        .map((w) => _translationKeys[w])
        .whereType<String>()
        .toSet();

    if (keys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in keys)
          Padding(
            padding: EdgeInsets.only(bottom: theme.defaultSpacing),
            child: _WarningBox(translationKey: key),
          ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  final String translationKey;

  const _WarningBox({required this.translationKey});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: theme.borderRadius,
        border: Border.all(color: theme.warning, width: 1),
      ),
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.warning),
          SizedBox(width: theme.smallSpacing),
          Expanded(child: TranslatedText(translationKey)),
        ],
      ),
    );
  }
}
