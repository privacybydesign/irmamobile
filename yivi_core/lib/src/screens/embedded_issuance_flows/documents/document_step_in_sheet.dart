import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../util/adaptive_layout.dart";

/// Marks the document screens shown as a step in a sheet (`DocumentSheetStep`):
/// they leave out their own app bar and Cancel (the sheet's bar has the
/// title, back and close), and let the sheet's glass show behind them. The
/// same screens on their full-screen routes have no marker and keep both.
class DocumentStepInSheet extends InheritedWidget {
  /// Set by the chip screen while it waits for the issuer after the face
  /// check (a loading screen), so the sheet's bar can say so in its title.
  final ValueNotifier<bool>? preparing;

  const DocumentStepInSheet({super.key, this.preparing, required super.child});

  /// Whether the screen at [context] is a step in a sheet.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DocumentStepInSheet>() != null;

  /// See [preparing]; null outside a sheet.
  static ValueNotifier<bool>? preparingOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DocumentStepInSheet>()?.preparing;

  @override
  bool updateShouldNotify(DocumentStepInSheet oldWidget) => false;
}

/// Whether the document screen at [context] is a step in a sheet on a phone
/// held sideways: it then lays itself out in the sheet's two columns
/// (`SheetSplit`), its buttons in the left one, without a bar.
bool documentStepSplit(BuildContext context) =>
    DocumentStepInSheet.of(context) && useSheetColumns(context);

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
      decoration: YiviShadows.surfaceCard(palette),
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}
