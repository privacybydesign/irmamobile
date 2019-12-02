import 'package:flutter/material.dart';

import 'package:irmamobile/src/util/gif_ani.dart';

class LoadingIndicator extends StatefulWidget {
  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> with SingleTickerProviderStateMixin {
  GifController _gifCtrl;

  @override
  void initState() {
    _gifCtrl = GifController(vsync: this, duration: Duration(milliseconds: 2000), frameCount: 50);
    _gifCtrl.repeat();
    super.initState();
  }

  @override
  void dispose() {
    _gifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GifAnimation(
      image: const AssetImage("assets/generic/loading_indicator.gif"),
      controller: _gifCtrl,
      width: 120,
      height: 120,
    );
  }
}
