import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/irma_avatar.dart";

/// Who is asking, at the top of the session screens: the party's logo (or
/// initial), its name, and whether it is registered with Yivi. An unknown
/// party gets an amber warning under it.
///
/// [progress] (e.g. "Step 1 of 2" with its bar) goes at the bottom, inside
/// the same glass.
class SessionRequestorHeader extends StatelessWidget {
  final TrustedParty requestor;

  /// A line under the name and status, e.g. what the screen is for.
  final String? description;
  final Widget? progress;

  const SessionRequestorHeader({
    super.key,
    required this.requestor,
    this.description,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final verified = requestor.verified;
    final image = requestor.image;

    final avatar = IrmaAvatar(
      size: 46,
      logoImage: image == null
          ? null
          : Base64Image(base64: image.base64, mimeType: image.mimeType),
      logoPath: image == null ? requestor.imagePath : null,
      logoSemanticsLabel: requestor.name,
      initials: requestor.name.isEmpty ? "?" : requestor.name.characters.first,
    );

    return GlassSurface(
      key: const Key("session_requestor_header"),
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  avatar,
                  if (verified)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: ExcludeSemantics(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: palette.successText,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: palette.surface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestor.name,
                      key: const Key("session_requestor_name"),
                      style: palette.display(17).copyWith(color: palette.text),
                    ),
                    Text(
                      FlutterI18n.translate(
                        context,
                        verified
                            ? "share.requestor.registered"
                            : "share.requestor.not_registered",
                      ),
                      style: palette
                          .body(13, weight: FontWeight.w600)
                          .copyWith(
                            color: verified
                                ? palette.successText
                                : palette.warningText,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!verified)
            Container(
              key: const Key("session_requestor_warning"),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: ShapeDecoration(
                color: palette.warningSurface,
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
              child: Text(
                FlutterI18n.translate(context, "share.requestor.unknown_note"),
                style: palette
                    .body(13)
                    .copyWith(height: 19 / 13, color: palette.warningText),
              ),
            ),
          if (description != null)
            Text(
              description!,
              style: palette
                  .body(14)
                  .copyWith(height: 21 / 14, color: palette.heading),
            ),
          ?progress,
        ],
      ),
    );
  }
}

/// Dots for the steps of adding missing data, with "Step 1 of 2" next to
/// them: done steps green, the current one blue, later ones faint.
class StepProgress extends StatelessWidget {
  final int total;

  /// 0-based; the steps before it are done.
  final int current;

  const StepProgress({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final label = FlutterI18n.translate(
      context,
      "share.step_count",
      translationParams: {"step": "${current + 1}", "total": "$total"},
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        spacing: 6,
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i < current
                      ? palette.successText
                      : i == current
                      ? palette.link
                      : palette.link.withValues(alpha: 0.15),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              label,
              style: palette.body(12.5).copyWith(color: palette.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
