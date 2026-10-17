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
class SessionRequestorHeader extends StatelessWidget {
  final TrustedParty requestor;

  /// A line under the name and status, e.g. what the screen is for.
  final String? description;

  const SessionRequestorHeader({
    super.key,
    required this.requestor,
    this.description,
  });

  /// [requestor]'s logo, or its initial when it has none.
  static Widget avatarOf(TrustedParty requestor, {double size = 46}) {
    final image = requestor.image;
    return IrmaAvatar(
      size: size,
      logoImage: image == null
          ? null
          : Base64Image(base64: image.base64, mimeType: image.mimeType),
      logoPath: image == null ? requestor.imagePath : null,
      logoSemanticsLabel: requestor.name,
      initials: requestor.name.isEmpty ? "?" : requestor.name.characters.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final verified = requestor.verified;
    final avatar = avatarOf(requestor);

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
        ],
      ),
    );
  }
}
