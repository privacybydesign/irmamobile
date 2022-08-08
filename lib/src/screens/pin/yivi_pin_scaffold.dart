part of pin;

class YiviPinScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const YiviPinScaffold({Key? key, required this.body, this.appBar}) : super(key: key);

  Widget applyTabletSupport(bool isTabletDevice) {
    return LayoutBuilder(builder: (context, constraints) {
      const commonShortestPhoneEdge = 414.0;
      const commonLargestPhoneEdge = 736.0; // iPad mini shortest edge = 768 (1024 x 768)
      if (isTabletDevice) {
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
    final scalePaddingForSmallDevices = shortestSide(context) < 350 ? 0.5 : 1;
    final paddingSize = scalePaddingForSmallDevices * theme.screenPadding;

    return Scaffold(
      appBar: appBar,
      backgroundColor: theme.background,
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(left: paddingSize, right: paddingSize, bottom: paddingSize),
          child: applyTabletSupport(context.isTabletDevice),
        ),
      ),
    );
  }
}
