import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";

/// Marks the document screens shown as a step in a sheet (`DocumentSheetStep`):
/// they leave out their own app bar and Cancel (the sheet's bar has the
/// title, back and close), and let the sheet's glass show behind them. The
/// same screens on their full-screen routes have no marker and keep both.
class DocumentStepInSheet extends InheritedWidget {
  const DocumentStepInSheet({super.key, required super.child});

  /// Whether the screen at [context] is a step in a sheet.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DocumentStepInSheet>() != null;

  @override
  bool updateShouldNotify(DocumentStepInSheet oldWidget) => false;
}

/// Whether the document screen at [context] is a step in a sheet on a phone
/// held sideways: it then lays itself out in the sheet's two columns
/// (`SheetSplit`), its buttons in the left one, without a bar.
bool documentStepSplit(BuildContext context) =>
    DocumentStepInSheet.of(context) && usePhoneLandscape(context);

/// [child] in a scroll view, as a document screen's body; as it is in a
/// sheet held sideways, where it lays itself out in columns
/// ([documentStepSplit]).
Widget documentScroll(BuildContext context, Widget child) =>
    documentStepSplit(context)
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
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("sheet_picture_card"),
      padding: const EdgeInsets.all(20),
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
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}
