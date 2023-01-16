part of pin;

class YiviPinScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const YiviPinScaffold({Key? key, required this.body, this.appBar}) : super(key: key);

  Widget _applyTabletSupport(bool isTabletDevice) {
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
    final paddingSize = theme.screenPadding;

    return Scaffold(
      appBar: appBar,
      backgroundColor: theme.backgroundPrimary,
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            left: paddingSize,
            right: paddingSize,
            bottom: paddingSize,
            top: appBar != null ? 0 : paddingSize,
          ),
          child: _applyTabletSupport(context.isTabletDevice),
        ),
      ),
    );
  }
}
