import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/sheet/sheet_layout.dart";
import "../../../widgets/surfaces/surface_card.dart";
import "../../../widgets/text/translated_text.dart";

/// The page of a document screen, a step of adding a document in a sheet:
/// no bar of its own (the sheet's has the title, back and close) and the
/// sheet's glass behind it; [bottomBar] under [body]. With
/// [DocumentStepScaffold.split], the two columns of a sheet held sideways
/// ([useSheetColumns]).
class DocumentStepScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomBar;

  const DocumentStepScaffold({super.key, required this.body, this.bottomBar});

  /// In a sheet held sideways: the sheet's two columns.
  const DocumentStepScaffold.split(SheetSplit split, {super.key})
    : body = split,
      bottomBar = null;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    backgroundColor: Colors.transparent,
    body: body,
    bottomNavigationBar: bottomBar,
  );
}

/// [child] in a scroll view, as a document screen's body; as it is in a
/// sheet held sideways, where it lays itself out in columns
/// ([useSheetColumns]).
Widget documentScroll(BuildContext context, Widget child) =>
    useSheetColumns(context)
    ? child
    : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      );

/// A picture on a white card filling the right column of a sheet held
/// sideways (the chip, the face check): scaled down to fit when it is
/// larger than the card.
class SheetPictureCard extends StatelessWidget {
  final Widget child;

  const SheetPictureCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      key: const Key("sheet_picture_card"),
      padding: const EdgeInsets.all(YiviSpace.x16),
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}

/// The heading of a document step in a sheet held upright, centred above
/// what the step shows ("Scan passport", the face check).
class DocumentSheetHeading extends StatelessWidget {
  final String titleKey;

  /// The key of the heading's text.
  final Key? textKey;

  const DocumentSheetHeading(this.titleKey, {super.key, this.textKey});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x8,
        0,
        YiviSpace.x8,
        YiviSpace.x16,
      ),
      child: TranslatedText(
        titleKey,
        key: textKey,
        isHeader: true,
        textAlign: TextAlign.center,
        style: palette.titleStep.copyWith(color: palette.text),
      ),
    );
  }
}

/// The heading of a document step in the left column of a sheet held
/// sideways ([useSheetColumns]).
TextStyle documentSplitHeadingStyle(YiviPalette palette) =>
    palette.titleSmall.copyWith(height: 28 / 20);

/// The text under [documentSplitHeadingStyle].
TextStyle documentSplitBodyStyle(YiviPalette palette) =>
    palette.paragraph.copyWith(height: 22 / 15);
