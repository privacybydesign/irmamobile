import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_close_button.dart';

class IrmaBottomSheet extends StatefulWidget {
  final Widget child;
  final Widget? title;

  const IrmaBottomSheet({
    this.title,
    required this.child,
  });

  @override
  State<IrmaBottomSheet> createState() => _IrmaBottomSheetState();
}

class _IrmaBottomSheetState extends State<IrmaBottomSheet> {
  final _controller = ScrollController();
  bool _scrolledDown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollPositionChanged);
  }

  _scrollPositionChanged() {
    if (_controller.offset > 0 && !_scrolledDown) {
      setState(() {
        _scrolledDown = true;
      });
    } else if (_controller.offset <= 0 && _scrolledDown) {
      setState(() {
        _scrolledDown = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _scrolledDown ? theme.backgroundSecondary : theme.backgroundPrimary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                    child: widget.title ?? Container(),
                  ),
                ),
                IrmaCloseButton(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              controller: _controller,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
