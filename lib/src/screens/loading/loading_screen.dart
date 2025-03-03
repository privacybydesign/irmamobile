import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/enrollment_status.dart';
import '../../models/error_event.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_repository_provider.dart';
import '../error/error_screen.dart';
import '../splash_screen/splash_screen.dart';

class LoadingScreen extends StatefulWidget {
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  StreamSubscription<EnrollmentStatus>? _enrollmentStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);

      // when the phone is fast, the enrollment can already have changed before we added the listener
      repo.getEnrollmentStatus().first.then(_enrollmentStatusHandler);
      _enrollmentStatusSubscription = repo.getEnrollmentStatus().listen(_enrollmentStatusHandler);
    });
  }

  void _enrollmentStatusHandler(EnrollmentStatus status) async {
    // we have to await the locked setting, because it could come after the enrollment status,
    // causing us to be automatically redirected to the pin screen when we're already unlocked...
    final locked = await IrmaRepositoryProvider.of(context).getLocked().first;

    if (!mounted) {
      return;
    }

    if (status == EnrollmentStatus.enrolled) {
      if (locked) {
        context.goPinScreenWithoutTransition();
      } else {
        context.goHomeScreenWithoutTransition();
      }
    } else if (status == EnrollmentStatus.unenrolled) {
      context.goEnrollmentScreen();
    }
  }

  @override
  void dispose() {
    _enrollmentStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    return StreamBuilder<ErrorEvent>(
      stream: repo.getFatalErrors().timeout(
        const Duration(seconds: 15),
        onTimeout: (_) {
          repo.dispatch(
            ErrorEvent(
              exception: 'Timeout: enrollment status could not be determined within 15 seconds',
              stack: '',
              fatal: true,
            ),
          );
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ErrorScreen.fromEvent(error: snapshot.data!);
        }
        return const SplashScreen(isLoading: true);
      },
    );
  }
}
