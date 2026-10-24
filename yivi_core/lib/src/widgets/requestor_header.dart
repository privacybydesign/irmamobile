import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_corners.dart";
import "../theme/yivi_palette.dart";
import "irma_avatar.dart";

IrmaAvatar _buildRequestorAvatar({required String? title, Widget? image}) {
  return IrmaAvatar(
    size: 52,
    logoImage: image,
    logoSemanticsLabel: title,
    initials: title != "" ? title![0] : null,
  );
}

class IssueWizardRequestorHeader extends StatelessWidget {
  final String? title;
  final Widget? image;
  final Color? backgroundColor;
  final Color? textColor;

  const IssueWizardRequestorHeader({
    this.title,
    this.image,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return _RequestorHeaderBase(
      textColor: textColor,
      backgroundColor: backgroundColor,
      avatar: _buildRequestorAvatar(title: title, image: image),
      mainText: Text(
        title ?? "",
        style: IrmaTheme.of(context).themeData.textTheme.headlineMedium,
      ),
    );
  }
}

// Contains the default styling and behavior for the header of the issue wizard
class _RequestorHeaderBase extends StatelessWidget {
  final Widget avatar;
  final Widget mainText;
  final Color? backgroundColor;
  final Color? textColor;

  const _RequestorHeaderBase({
    required this.avatar,
    required this.mainText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final palette = YiviPalette.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.smallSpacing),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: backgroundColor ?? palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(YiviCorners.card),
          ),
          // The known-party box has a green edge, as in the design.
          side: backgroundColor == palette.successSurface
              ? BorderSide(color: palette.successOutline)
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [mainText],
            ),
          ),
        ],
      ),
    );
  }
}
