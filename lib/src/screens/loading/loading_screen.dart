import 'package:flutter/material.dart';

import '../../models/enrollment_status.dart';
import '../../models/error_event.dart';
import '../../widgets/irma_repository_provider.dart';
import '../enrollment/enrollment_screen.dart';
import '../error/error_screen.dart';
import '../home/home_screen.dart';
import '../splash_screen/splash_screen.dart';

class LoadingScreen extends StatelessWidget {
  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    return StreamBuilder<EnrollmentStatus>(
      stream: repo.getEnrollmentStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == EnrollmentStatus.enrolled) {
            // We don't add a smooth transition here like below, because it will be covered by the PinScreen anyway.
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
            });
          } else if (snapshot.data == EnrollmentStatus.unenrolled) {
            // Because this happens on start-up immediately, we have to make sure a smooth transition is being made.
            WidgetsBinding.instance?.addPostFrameCallback((_) {
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
                error: error!,
              );
            }
            return const SplashScreen(
              isLoading: true,
            );
          },
        );
      },
    );
  }
}
