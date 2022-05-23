import 'package:flutter/material.dart';

import '../screens/required_update/required_update_screen.dart';
import '../screens/session/widgets/arrow_back_screen.dart';

class PrototypesScreen extends StatelessWidget {
  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: const Text('Arrow back screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArrowBack(
                  amountIssued: 0,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Required update screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequiredUpdateScreen(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
