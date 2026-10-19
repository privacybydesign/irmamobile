import "package:material_ui/material_ui.dart";

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
