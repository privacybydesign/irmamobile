import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/enrollment_status.dart";
import "../../models/error_event.dart";
import "../../providers/app_providers.dart";
import "../../providers/irma_repository_provider.dart";
import "../../util/after_frame.dart";
import "../../util/navigation.dart";
import "../error/error_screen.dart";
import "../splash_screen/splash_screen.dart";

/// The splash screen while the app finds out whether it is enrolled: then
/// home or the enrollment. A fatal error shows the error screen, and so does
/// waiting longer than 15 s.
class LoadingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  /// One timer for the screen's life: a rebuild does not restart it.
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      ref
          .read(irmaRepositoryProvider)
          .dispatch(
            ErrorEvent(
              exception:
                  "Timeout: enrollment status could not be determined within 15 seconds",
              stack: "",
              fatal: true,
            ),
          );
    });
    // After the first frame: the status may already be known, and
    // navigating needs a built router.
    afterFrame(() => _onStatus(ref.read(enrollmentStatusProvider).value));
  }

  void _onStatus(EnrollmentStatus? status) {
    if (!mounted) return;
    if (status == EnrollmentStatus.enrolled) {
      _timeout?.cancel();
      // LockGate handles displaying the PIN overlay if the app is
      // locked; no separate /pin route to navigate to.
      context.goHomeScreenWithoutTransition();
    } else if (status == EnrollmentStatus.unenrolled) {
      _timeout?.cancel();
      context.goEnrollmentScreen();
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      enrollmentStatusProvider,
      (_, status) => afterFrame(() => _onStatus(status.value)),
    );
    final error = ref.watch(fatalErrorProvider).value;
    if (error != null) return ErrorScreen.fromEvent(error: error);
    return const SplashScreen(isLoading: true);
  }
}
