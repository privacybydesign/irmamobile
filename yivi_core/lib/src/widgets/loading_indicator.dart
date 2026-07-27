import "package:flutter/material.dart";

class LoadingIndicator extends StatelessWidget {
  // Deliberately no color: the spinner color comes from
  // themeData.progressIndicatorTheme, so this widget and a bare
  // CircularProgressIndicator elsewhere in the app always match.
  @override
  Widget build(BuildContext context) =>
      CircularProgressIndicator(strokeWidth: 3.5);
}
