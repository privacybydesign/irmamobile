import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../models/missing_data_checklist.dart";
import "../providers/missing_data_flow_provider.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "irma_avatar.dart";
import "irma_linear_progresss_indicator.dart";

const _iconSize = 28.0;
const _ringWidth = 2.0;
const _iconBoxSize = _iconSize + 2 * 2 * _ringWidth;
const _dimmedOpacity = 0.4;
const _badgeSize = 14.0;
const _progressBarHeight = 4.0;
const _labelLineHeight = 24.0;

/// Shows which request the user is collecting data for, and how far along
/// they are, as the bottom of the app bar of an issuance screen. Blank unless
/// the user came from the missing data checklist.
///
/// An app bar needs to know the height of its bottom up front, so the band
/// has a fixed [height]. Get one with [MissingDataFlowNavigation.missingDataBand]
/// rather than building it.
class MissingDataBand extends ConsumerWidget implements PreferredSizeWidget {
  final double height;

  const MissingDataBand({super.key, required this.height});

  /// The height of the band for the current theme and text scale.
  static double heightFor(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final label = MediaQuery.textScalerOf(context).scale(_labelLineHeight);

    return theme.smallSpacing +
        label +
        theme.tinySpacing +
        _progressBarHeight +
        theme.smallSpacing +
        _iconBoxSize +
        theme.smallSpacing;
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = ref.watch(missingDataBandProvider);
    if (band == null) return SizedBox(height: height);

    final theme = IrmaTheme.of(context);
    final checklist = band.checklist;
    final label = FlutterI18n.translate(
      context,
      "missing_data.band",
      translationParams: {
        "requestor": band.requestorName,
        "x": "${checklist.presentCount}",
        "n": "${checklist.total}",
      },
    );

    return SizedBox(
      key: const Key("missing_data_band"),
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
          vertical: theme.smallSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.themeData.textTheme.bodySmall,
            ),
            SizedBox(height: theme.tinySpacing),
            ExcludeSemantics(
              child: SizedBox(
                height: _progressBarHeight,
                child: IrmaLinearProgressIndicator(
                  filledPercentage:
                      checklist.presentCount / checklist.total * 100,
                ),
              ),
            ),
            SizedBox(height: theme.smallSpacing),
            ExcludeSemantics(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in checklist.entries) ...[
                      _BandCredential(
                        entry: entry,
                        isCurrent:
                            !entry.isPresent &&
                            entry.credential.credentialId ==
                                band.currentCredentialId,
                      ),
                      SizedBox(width: theme.tinySpacing),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandCredential extends StatelessWidget {
  final ChecklistEntry entry;
  final bool isCurrent;

  const _BandCredential({required this.entry, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final credential = entry.credential;
    final image = credential.image;

    return Opacity(
      opacity: entry.isPresent || isCurrent ? 1 : _dimmedOpacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The ring is always laid out, so the icons do not shift when the
          // current one changes.
          Container(
            padding: const EdgeInsets.all(_ringWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent ? theme.primary : Colors.transparent,
                width: _ringWidth,
              ),
            ),
            child: IrmaAvatar(
              size: _iconSize,
              logoImage: image != null
                  ? Base64Image(base64: image.base64, mimeType: image.mimeType)
                  : null,
              initials: credential.name.isNotEmpty ? credential.name[0] : "?",
            ),
          ),
          if (entry.isPresent)
            Positioned(
              right: -_ringWidth,
              bottom: -_ringWidth,
              child: Container(
                key: Key("missing_data_band_done_${credential.credentialId}"),
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: theme.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.light),
                ),
                child: Icon(Icons.check, size: 10, color: theme.light),
              ),
            ),
        ],
      ),
    );
  }
}
