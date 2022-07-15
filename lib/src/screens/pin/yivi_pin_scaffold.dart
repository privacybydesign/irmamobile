part of pin;

class YiviPinScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const YiviPinScaffold({Key? key, required this.body, this.appBar}) : super(key: key);

  Widget applyTabletSupport(context) {
    return LayoutBuilder(builder: (context, constraints) {
      final commonShortestPhoneEdge = 414.0;
      final commonLargestPhoneEdge = 736.0; // iPad mini shortest edge = 768 (1024 x 768)
      if (context.isTabletDevice) {
        return SizedBox(
          width: commonShortestPhoneEdge,
          height: min(constraints.maxHeight, commonLargestPhoneEdge),
          child: body,
        );
      } else {
        return body;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: appBar,
      backgroundColor: theme.background,
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.all(theme.screenPadding),
          child: applyTabletSupport(context),
        ),
      ),
    );
  }
}
