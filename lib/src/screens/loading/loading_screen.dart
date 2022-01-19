// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/splash_screen/splash_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

class LoadingScreen extends StatelessWidget {
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
              // Because this happens on start-up immediately, we have to make sure a smooth transition is being made.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => EnrollmentScreen(),
                  transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                  transitionDuration: const Duration(milliseconds: 500),
                ));
              });
            }
          }
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
              return const SplashScreen();
            },
          );
        });
  }
}
