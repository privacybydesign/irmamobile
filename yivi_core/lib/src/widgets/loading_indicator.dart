import "package:material_ui/material_ui.dart";

class LoadingIndicator extends StatelessWidget {
  // Deliberately no color: it comes from themeData.progressIndicatorTheme, so
  // this widget and a bare CircularProgressIndicator paint the same color.
  // Only the 3.5 stroke is local; a bare one gets Material's default 4.0.
  @override
  Widget build(BuildContext context) =>
      CircularProgressIndicator(strokeWidth: 3.5);
}
