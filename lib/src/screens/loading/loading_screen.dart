import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/enrollment_status.dart';
import '../../models/error_event.dart';
import '../../widgets/irma_repository_provider.dart';
import '../enrollment/enrollment_screen.dart';
import '../error/error_screen.dart';
import '../home/home_screen.dart';
import '../splash_screen/splash_screen.dart';

class LoadingScreen extends StatefulWidget {
  static const routeName = '/';

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  StreamSubscription<EnrollmentStatus>? _enrollmentStatusSubscription;
  Stream<ErrorEvent>? _errorEventStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      _errorEventStream = repo.getFatalErrors();
      _enrollmentStatusSubscription = repo.getEnrollmentStatus().listen(_enrollmentStatusHandler);
    });
  }

  void _enrollmentStatusHandler(EnrollmentStatus status) {
    if (status == EnrollmentStatus.enrolled) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else if (status == EnrollmentStatus.unenrolled) {
      // Because this happens on start-up immediately, we have to make sure a smooth transition is being made.
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, a1, a2) => EnrollmentScreen(),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    }
  }

  @override
  void dispose() {
    _enrollmentStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ErrorEvent>(
        stream: _errorEventStream,
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
}
