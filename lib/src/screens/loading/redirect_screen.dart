import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

class RedirectScreen extends StatelessWidget {
  static final routeName = "/";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EnrollmentStatus>(
      stream: IrmaRepository.get().getEnrollmentStatus(),
      builder: (context, snapshot) {
        if (snapshot.data != null && !snapshot.data.isEmpty()) {
          if (snapshot.data.isEnrolled()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(WalletScreen.routeName);
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(EnrollmentScreen.routeName);
            });
          }
        }
        return LoadingScreen();
      }
    );
  }
}
