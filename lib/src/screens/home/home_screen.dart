import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/home/widgets/irma_home_nav_bar.dart';

//TODO: Re-introduce an easter egg to navigate to debug screen (only in debug builds)
class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(bottomNavigationBar: IrmaNavBar());
  }
}
