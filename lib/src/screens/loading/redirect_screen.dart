import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

class RedirectScreen extends StatelessWidget {
  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepository.get();
    return StreamBuilder<EnrollmentStatus>(
        stream: repo.getEnrollmentStatus(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == EnrollmentStatus.enrolled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(WalletScreen.routeName);
              });
            } else if (snapshot.data == EnrollmentStatus.unenrolled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(EnrollmentScreen.routeName);
              });
            }
          }
          // TODO Re-consider when the splash screen logic in app.dart (see TODO there) is improved.
          return StreamBuilder<ErrorEvent>(
            stream: repo.getFatalErrors(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final error = snapshot.data;
                return ErrorScreen.fromEvent(
                  error: error,
                  onTapClose: () {}, // Error is fatal, so closing the error is not possible anyway.
                );
              }
              return LoadingScreen();
            },
          );
        });
  }
}
