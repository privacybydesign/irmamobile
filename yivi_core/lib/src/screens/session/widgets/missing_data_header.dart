import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_icon_indicator.dart";
import "../../../widgets/irma_linear_progresss_indicator.dart";

enum MissingDataPhase { collecting, ready }

const _toReadyDuration = Duration(milliseconds: 600);

/// Header of the missing data checklist. While [MissingDataPhase.collecting]
/// it is a white block with the progress; in [MissingDataPhase.ready] it fades
/// to blue and puts the requestor up front, because the same screen is where
/// the user shares.
class MissingDataHeader extends StatelessWidget {
  final TrustedParty requestor;
  final MissingDataPhase phase;
  final int total;
  final int presentCount;

  const MissingDataHeader({
    super.key,
    required this.requestor,
    required this.phase,
    required this.total,
    required this.presentCount,
  });

  String _plural(BuildContext context, String key) {
    return FlutterI18n.translate(
      context,
      total == 1 ? "$key.one" : "$key.other",
      translationParams: {"requestor": requestor.name, "n": "$total"},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final ready = phase == MissingDataPhase.ready;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _toReadyDuration;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ready ? 1 : 0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final background = Color.lerp(theme.light, theme.link, t)!;
        final foreground = Color.lerp(theme.neutralExtraDark, theme.light, t)!;

        return Container(
          key: const Key("missing_data_header"),
          width: double.infinity,
          padding: EdgeInsets.all(theme.defaultSpacing),
          decoration: BoxDecoration(
            color: background,
            borderRadius: theme.borderRadius,
          ),
          child: ready
              ? _buildReady(context, foreground)
              : _buildCollecting(context, foreground),
        );
      },
    );
  }

  Widget _buildCollecting(BuildContext context, Color foreground) {
    final theme = IrmaTheme.of(context);
    final textTheme = theme.themeData.textTheme;
    final progress = FlutterI18n.translate(
      context,
      "missing_data.progress",
      translationParams: {"x": "$presentCount", "n": "$total"},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestorAvatar(requestor: requestor, size: 48),
            SizedBox(width: theme.defaultSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      _plural(context, "missing_data.header"),
                      style: textTheme.headlineMedium!.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  SizedBox(height: theme.tinySpacing),
                  _RequestorTrust(requestor: requestor, color: foreground),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: theme.defaultSpacing),
        Text(progress, style: textTheme.bodySmall!.copyWith(color: foreground)),
        SizedBox(height: theme.tinySpacing),
        ExcludeSemantics(
          child: IrmaLinearProgressIndicator(
            filledPercentage: total == 0 ? 0 : presentCount / total * 100,
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, Color foreground) {
    final theme = IrmaTheme.of(context);
    final textTheme = theme.themeData.textTheme;

    return Column(
      children: [
        _RequestorAvatar(requestor: requestor, size: 64),
        SizedBox(height: theme.defaultSpacing),
        Semantics(
          header: true,
          child: Text(
            FlutterI18n.translate(context, "missing_data.ready_title"),
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(color: foreground),
          ),
        ),
        SizedBox(height: theme.smallSpacing),
        Text(
          _plural(context, "missing_data.share_question"),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium!.copyWith(color: foreground),
        ),
      ],
    );
  }
}

class _RequestorAvatar extends StatelessWidget {
  final TrustedParty requestor;
  final double size;

  const _RequestorAvatar({required this.requestor, required this.size});

  @override
  Widget build(BuildContext context) {
    final image = requestor.image;

    return IrmaAvatar(
      size: size,
      logoImage: image != null
          ? Base64Image(base64: image.base64, mimeType: image.mimeType)
          : null,
      logoPath: requestor.imagePath,
      logoSemanticsLabel: requestor.name,
      initials: requestor.name.isNotEmpty ? requestor.name[0] : "?",
    );
  }
}

class _RequestorTrust extends StatelessWidget {
  final TrustedParty requestor;
  final Color color;

  const _RequestorTrust({required this.requestor, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final key = requestor.verified
        ? "missing_data.known_party"
        : "missing_data.unknown_party";

    return Row(
      children: [
        ExcludeSemantics(
          child: IrmaStatusIndicator(success: requestor.verified, size: 18),
        ),
        SizedBox(width: theme.tinySpacing),
        Flexible(
          child: Text(
            FlutterI18n.translate(context, key),
            style: theme.themeData.textTheme.bodySmall!.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
