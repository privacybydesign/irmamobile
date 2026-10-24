import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/surface_card.dart";

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

/// The page of a document screen. On its full-screen route: the page colour
/// and an [IrmaAppBar] with [titleKey] (and [leading], a back button unless
/// given), the [body] scrolling under it. As a step in a sheet: no bar of
/// its own (the sheet's has the title, back and close) and the sheet's
/// glass behind it. With [DocumentStepScaffold.split], the two columns of a
/// sheet held sideways ([documentStepSplit]).
class DocumentStepScaffold extends StatelessWidget {
  final String? titleKey;
  final Widget? leading;
  final Widget body;
  final Widget? bottomBar;

  const DocumentStepScaffold({
    super.key,
    required String this.titleKey,
    this.leading = const YiviBackButton(),
    required this.body,
    this.bottomBar,
  });

  /// In a sheet held sideways: the sheet's two columns, without a bar.
  const DocumentStepScaffold.split(SheetSplit split, {super.key})
    : titleKey = null,
      leading = null,
      body = split,
      bottomBar = null;

  @override
  Widget build(BuildContext context) {
    final titleKey = this.titleKey;
    if (titleKey == null) {
      return Scaffold(backgroundColor: Colors.transparent, body: body);
    }
    final inSheet = DocumentStepInSheet.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: inSheet
          ? Colors.transparent
          : YiviPalette.of(context).background,
      appBar: inSheet
          ? null
          : IrmaAppBar(titleTranslationKey: titleKey, leading: leading),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}

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
    return SurfaceCard(
      key: const Key("sheet_picture_card"),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}
