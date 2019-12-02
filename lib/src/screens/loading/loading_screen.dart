import 'package:flutter/material.dart';

import 'package:irmamobile/src/widgets/loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoadingIndicator(),
      ),
    );
  }
}
